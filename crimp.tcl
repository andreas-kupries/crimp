# -*- tcl -*-
# CRIMP == C Runtime Image Manipulation Package
#
# (c) 2010 Andrew M. Goth  http://wiki.tcl.tk/andy%20goth
# (c) 2010 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

#package require Tk
package require critcl

if {![critcl::compiling]} {
    error "Unable to build CRIMP, no proper compiler found."
}
#critcl::config keepsrc 1

# # ## ### ##### ######## #############
## Implementation.

catch {
    critcl::cheaders -g
    critcl::debug memory symbols
}

critcl::config tk 1
critcl::cheaders c/*.h cop/*.c
critcl::csources c/*.c
critcl::tsources crimp_tcl.tcl
# FFT sources and dependencies.
critcl::cheaders c/fftpack/f2c.h
critcl::csources c/fftpack/radb2.c
critcl::csources c/fftpack/radb3.c
critcl::csources c/fftpack/radb4.c
critcl::csources c/fftpack/radb5.c
critcl::csources c/fftpack/radbg.c
critcl::csources c/fftpack/radf2.c
critcl::csources c/fftpack/radf3.c
critcl::csources c/fftpack/radf4.c
critcl::csources c/fftpack/radf5.c
critcl::csources c/fftpack/radfg.c
critcl::csources c/fftpack/rfftb.c
critcl::csources c/fftpack/rfftb1.c
critcl::csources c/fftpack/rfftf.c
critcl::csources c/fftpack/rfftf1.c
critcl::csources c/fftpack/rffti.c
critcl::csources c/fftpack/rffti1.c

::apply {{here} {
    # image readers and writers implemented
    # as Tcl procedures.
    foreach f [glob -directory $here/reader *.tcl] { critcl::tsources $f }
    foreach f [glob -directory $here/writer *.tcl] { critcl::tsources $f }
}} [file dirname [file normalize [info script]]]

critcl::tsources plot.tcl

critcl::cinit {
    crimp_imagetype_init ();
} {}

critcl::ccode {
    #include <math.h>
    #include <stdlib.h>
    #include <string.h>
    #include <image_type.h>
    #include <image.h>
    #include <volume.h>
    #include <ahe.h>
    #include <rank.h>
    #include <linearalgebra.h>
    #include <geometry.h>
    #include <color.h>
    #include <util.h>
    #include <f2c.h>

    /* Common declarations to access the FFT functions. */

    extern int rffti_ (integer *n, real *wsave);
    extern int rfftf_ (integer *n, real* r, real *wsave);
    extern int rfftb_ (integer *n, real* r, real *wsave);
}

# # ## ### ##### ######## #############
## Read and execute all .crimp files in the current directory.

::apply {{here} {
    foreach filename [lsort [glob -nocomplain -directory [file join $here operator] *.crimp]] {
	set chan [open $filename]
	set name [gets $chan]
	set params "Tcl_Interp* interp"
	set number 2
	while {1} {
	    incr number
	    set line [gets $chan]
	    if {$line eq ""} {
		break
	    }
	    append params " $line"
	}
	set body "\n#line $number \"[file tail $filename]\"\n[read $chan]"
	close $chan
	namespace eval ::crimp [list ::critcl::cproc $name $params ok $body]
    }
}} [file dirname [file normalize [info script]]]

# # ## ### ##### ######## #############
## Make the C pieces ready. Force build of the binaries and check if ok.

if {[critcl::failed]} {
    error "Building CRIMP failed."
} else {
    # Build OK, force system to load the generated shared library.
    # Required bececause critcl::failed explicitly disables the
    # load phase.
    critcl::cbuild [info script]
}

# # ## ### ##### ######## #############
## Pull in the Tcl layer aggregating the C primitives into useful
## commands.
##
## NOTE: This is for the interactive use of crimp.tcl. When used as
##       plain package the 'tsources' declaration at the top ensures
##       the distribution and use of the Tcl layer.

source [file join [file dirname [file normalize [info script]]] crimp_tcl.tcl]

# This can fail when compiling via 'critcl -pkg', because snit may not
# be a visible package to the starkit. Have to think more about how to
# separate the pieces. Plot should likely be its own package.
catch {
    source [file join [file dirname [file normalize [info script]]] plot.tcl]
}

# # ## ### ##### ######## #############
## Fully Ready. Export.

package provide crimp 0
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
