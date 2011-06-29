# -*- tcl -*-
# CRIMP == C Runtime Image Manipulation Package
#
# (c) 2010 Andrew M. Goth  http://wiki.tcl.tk/andy%20goth
# (c) 2010 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

package require critcl       3
package require critcl::util 1

# # ## ### ##### ######## #############

if {![critcl::compiling]} {
    error "Unable to build CRIMP, no proper compiler found."
}

critcl::license \
    {Andreas Kupries} \
    {Under a BSD license.}

# # ## ### ##### ######## #############
## Implementation.

critcl::tcl 8.5

critcl::cflags -DIEEE_COMPLEX_DIVIDE

critcl::cheaders c/*.h cop/*.c
critcl::csources c/*.c

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
critcl::tsources writer/w_*.tcl

# # ## ### ##### ######## #############
## Declare the Tcl layer aggregating the C primitives into useful
## commands. After the Tcl-based readers and writers to properly pick
## them up too in the ensembles.

critcl::tsources crimp_tcl.tcl

# # ## ### ##### ######## #############
## C-level API (i.e. types and stubs)

critcl::api header c/common.h
critcl::api header c/image_type.h
critcl::api header c/image.h
critcl::api header c/volume.h

# - -- --- ----- -------- -------------
## image_type.h

#  API :: Core. Manage a mapping of types to names.
critcl::api function {const crimp_imagetype*} crimp_imagetype_find {
    {const char*} name
}
critcl::api function void crimp_imagetype_def {
    {const crimp_imagetype*} imagetype
}

# API :: Tcl. Manage Tcl_Obj's of image types.
critcl::api function Tcl_Obj* crimp_new_imagetype_obj {
    {const crimp_imagetype*} imagetype
}
critcl::api function int crimp_get_imagetype_from_obj {
    Tcl_Interp*       interp
    Tcl_Obj*          imagetypeObj
    crimp_imagetype** imagetype
}

# - -- --- ----- -------- -------------
## image.h

# API :: Core. Image lifecycle management.
critcl::api function crimp_image* crimp_new {
    {const crimp_imagetype*} type
    int w
    int h
}
critcl::api function crimp_image* crimp_newm {
    {const crimp_imagetype*} type
    int w
    int h
    Tcl_Obj* meta
}
critcl::api function crimp_image* crimp_dup  {
    crimp_image* image
}
critcl::api function void crimp_del {
    crimp_image* image
}

#  API :: Tcl. Manage Tcl_Obj's of images.
critcl::api function Tcl_Obj* crimp_new_image_obj {
    crimp_image* image
}
critcl::api function int crimp_get_image_from_obj {
    Tcl_Interp*   interp
    Tcl_Obj*      imageObj
    crimp_image** image
}

# - -- --- ----- -------- -------------
## volume.h

# API :: Core. Volume lifecycle management.
critcl::api function crimp_volume* crimp_vnew {
    {const crimp_imagetype*} type
    int w
    int h
    int d
}
critcl::api function crimp_volume* crimp_vnewm {
    {const crimp_imagetype*} type
    int w
    int h
    int d
    Tcl_Obj* meta
}
critcl::api function crimp_volume* crimp_vdup {
    crimp_volume* volume
}
critcl::api function void crimp_vdel {
    crimp_volume* volume
}

#  API :: Tcl. Manage Tcl_Obj's of volumes
critcl::api function Tcl_Obj* crimp_new_volume_obj {
    crimp_volume* volume
}
critcl::api function int crimp_get_volume_from_obj {
    Tcl_Interp*    interp
    Tcl_Obj*       volumeObj
    crimp_volume** volume
}

# # ## ### ##### ######## #############
## Main C section.

critcl::cinit {
    extern void crimp_imagetype_init (void); /* c/image_type.c */

    crimp_imagetype_init ();
} {}

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
## Read and execute all .crimp files in the current directory.

critcl::owns operator/*.crimp
::apply {{here} {
    foreach filename [lsort [glob -nocomplain -directory [file join $here operator] *.crimp]] {
	# Ignore the Tk related operators.
	if {[string match *tk* $filename]} continue

	#critcl::msg -nonewline " \[[file rootname [file tail $filename]]\]"
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

package provide crimp 0
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
