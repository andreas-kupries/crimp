# -*- tcl -*-
# CRIMP == C Runtime Image Manipulation Package
#
# (c) 2010      Andrew M. Goth  http://wiki.tcl.tk/andy%20goth
# (c) 2010-2011 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

package require critcl       3
package require critcl::util 1

# # ## ### ##### ######## #############

if {![critcl::compiling]} {
    error "Unable to build CRIMP, no proper compiler found."
}

# # ## ### ##### ######## #############
## Get the local support code. We source it directly because this is
## only needed for building the package, in any mode, and not during
## the runtime. Thus not added to the 'tsources'.

::apply {{here} {
    source $here/support.tcl
}} [file dirname [file normalize [info script]]]

# # ## ### ##### ######## #############
## Administrivia

critcl::license \
    {Andreas Kupries} \
    {Under a BSD license.}

critcl::summary \
    {Main CRIMP package containing all the image processing goodies}

critcl::description {
    This package provides the CRIMP eco-system with all the image
    processing goodies. Note that this package does not contain
    image IO functionality. It indirectly provides only what it
    inherited from "crimp::core". For display of the images handled
    here use "crimp::tk". For reading and writing image files use
    the various other crimp packages, like "crimp::ppm", etc.
}

# subjects ... Try to find a way of getting these from the .crimp
# files, put the burden of maintaining the information local to the
# algorithms.

# # ## ### ##### ######## #############
## Implementation.

critcl::tcl 8.5

critcl::cflags -DIEEE_COMPLEX_DIVIDE

# Algorithm sources and dependencies
critcl::cheaders c/*.h cop/*.c
critcl::csources c/ahe.c
critcl::csources c/cabs.c
critcl::csources c/color.c
critcl::csources c/euclidmap.c
critcl::csources c/fir.c c/gauss.c
critcl::csources c/geometry.c
critcl::csources c/iir_order2.c
critcl::csources c/labelcc.c
critcl::csources c/linearalgebra.c
critcl::csources c/linearmaps.c
critcl::csources c/rank.c
critcl::csources c/z_abs.c
critcl::csources c/z_div.c
critcl::csources c/z_recip.c

critcl::owns demos.tcl demos/*.tcl images/*.png
critcl::owns doc specs tools

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

# # ## ### ##### ######## #############
## Declare the Tcl layer aggregating the C primitives into useful
## commands. After the Tcl-based readers and writers to properly pick
## them up too in the ensembles.

critcl::tsources policy.tcl

# # ## ### ##### ######## #############
## C-level API (i.e. types and stubs)

critcl::api import crimp::core 0.1

# # ## ### ##### ######## #############
## Main C section.

critcl::ccode {
    #include <math.h>
    #include <stdlib.h>
    #include <string.h>
    #include <util.h>
    #include <ahe.h>
    #include <rank.h>
    #include <linearalgebra.h>
    #include <geometry.h>
    #include <color.h>
    #include <util.h>
    #include <gauss.h>
    #include <labelcc.h>
    #include <linearmaps.h>
}

# # ## ### ##### ######## #############
## Define a compatibility implementation of lrint() on systems which do
## not provide it via their libc and/or libm.

if {[critcl::util::checkfun lrint]} {
    critcl::msg -nonewline "(native lrint()) "
} else {
    critcl::msg -nonewline "(+ compat/lrint.c) "
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
	    critcl::msg -nonewline "(have $f) "
	} else {
	    critcl::util::undef crimp_config.h $d
	    critcl::msg -nonewline "($f -> $fd) "
	}
    }
}}

# # ## ### ##### ######## #############
## Pull in the processing primitives.
## We ignore the Tk dependent pieces.

critcl::owns        operator/*.crimp
crimp_source_cproc {operator/*.crimp}

# # ## ### ##### ######## #############
## Make the C pieces ready. Immediate build of the binaries, no deferal.

if {![critcl::load]} {
    error "Building and loading CRIMP failed."
}

# # ## ### ##### ######## #############

package provide crimp 0.1
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
