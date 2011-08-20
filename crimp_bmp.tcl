# -*- tcl -*-
# CRIMP, BMP	Reader/writer for the BMP image file format.
#
# (c) 2011 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#
# Derived from the TkImg BMP reader/writer implementation.
# Copyright (c) 1997-2003 Jan Nijtmans    <nijtmans@users.sourceforge.net>
# Copyright (c) 2002      Andreas Kupries <andreas_kupries@users.sourceforge.net>
#

# # ## ### ##### ######## #############
## Requisites

package require critcl       3
package require critcl::util 1

# # ## ### ##### ######## #############

if {![critcl::compiling]} {
    error "Unable to build CRIMP::BMP, no proper compiler found."
}

critcl::license \
    {Andreas Kupries} \
    {Under a BSD license.}

critcl::summary \
    {Extension of the CRIMP core to handle import and export of BMP images}

critcl::description {
    This package provides the CRIMP eco-system with the functionality to handle
    images stored as Windows Bitmap (BMP).
}

critcl::subject image {BMP image} {Portable PixMap} {BMP import} {BMP export}
critcl::subject image {image import} {image export}

# # ## ### ##### ######## #############
## Implementation.

critcl::tcl 8.5

# # ## ### ##### ######## #############
## Declare the Tcl layer aggregating the C primitives into useful
## commands. After the Tcl-based readers and writers to properly pick
## them up too in the ensembles.

critcl::tsources policy_bmp.tcl

# # ## ### ##### ######## #############
## C-level API (i.e. stubs and types)

critcl::api import crimp::core 0.1

# # ## ### ##### ######## #############
## Main C section.

critcl::ccode {}

critcl::csources format/bmp.c
critcl::cheaders format/bmp.h

# # ## ### ##### ######## #############
## Read and execute all .crimp files in the current directory.

critcl::owns format/*bmp*.crimp
::apply {{here} {
    foreach filename [lsort [glob -nocomplain -directory [file join $here format] *bmp*.crimp]] {
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
    error "Building and loading CRIMP::BMP failed."
}

# # ## ### ##### ######## #############

package provide crimp::bmp 0.1
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
