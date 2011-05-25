# -*- tcl -*-
# CRIMP == C Runtime Image Manipulation Package
#
# (c) 2010 Andrew M. Goth  http://wiki.tcl.tk/andy%20goth
# (c) 2010 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

#package require Tk
package require critcl 2 ;# Should actually be 2.1
package require critcl::util 1

if {![critcl::compiling]} {
    error "Unable to build CRIMP, no proper compiler found."
}

critcl::license \
    {Andreas Kupries} \
    {Under a BSD license.}

#critcl::config keepsrc 1
#critcl::debug all

# # ## ### ##### ######## #############
## Implementation.

critcl::tcl 8.5
critcl::tk

critcl::cflags -DIEEE_COMPLEX_DIVIDE -g

critcl::cheaders c/*.h cop/*.c
critcl::csources c/*.c

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

# # ## ### ##### ######## #############
## Image readers and writers implemented as Tcl procedures.

critcl::tsources reader/r_*.tcl
critcl::tsources writer/w_*.tcl

# # ## ### ##### ######## #############
## Declare the Tcl layer aggregating the C primitives into useful
## commands. After the Tcl-based readers and writers to properly pick
## them up too in the ensembles.

critcl::tsources crimp_tcl.tcl

# # ## ### ##### ######## #############
## Chart helpers.

critcl::tsources plot.tcl

# # ## ### ##### ######## #############
## Main C section.

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
    #include <gauss.h>
    #include <labelcc.h>
    #include <linearmaps.h>
    #include <crimp_config.h>

    /* Common declarations to access the FFT functions. */

    extern int rffti_ (integer *n, real *wsave);
    extern int rfftf_ (integer *n, real* r, real *wsave);
    extern int rfftb_ (integer *n, real* r, real *wsave);
}

# # ## ### ##### ######## #############
## Define a compatibility implementation of lrint() on systems which do
## not provide it via their libc and/or libm.

if {[critcl::util::checkfun lrint]} {
    puts -nonewline "(native lrint()) "
    flush stdout
} else {
    puts -nonewline "(+ compat/lrint.c) "
    flush stdout
    critcl::csources compat/lrint.c
}

::apply {{} {
    # Check the presence of a number of math functions the compiler
    # may or may not have. Any C89 compiler should provide these.

    # This works because the package's C code is compiled after the
    # .tcl has been fully processed, regardless of relative location.
    # This enables us to dynamically create/modify a header file
    # needed by the C code.

    foreach f {
	hypotf sinf cosf sqrtf expf
    } {
	set fd [string range $f 0 end-1]
	set d  C_HAVE_[string toupper $f]

	if {[critcl::util::checkfun $f]} {
	    critcl::util::def crimp_config.h $d
	    puts -nonewline "(have $f) "
	    flush stdout
	} else {
	    critcl::util::undef crimp_config.h $d
	    puts -nonewline "($f -> $fd) "
	    flush stdout
	}
    }
}}

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
## Make the C pieces ready. Immediate build of the binaries, no deferal.

if {![critcl::load]} {
    error "Building and loading CRIMP failed."
}

# # ## ### ##### ######## #############
## Fully Ready. Export.

package provide crimp 0
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
