# -*- tcl -*-
# CRIMP, BMP	Reader for the BMP image file format.
#
# (c) 2011 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#
# Redeveloped after reading the TkImg BMP reader/writer implementation.
# Copyright (c) 1997-2003 Jan Nijtmans    <nijtmans@users.sourceforge.net>
# Copyright (c) 2002      Andreas Kupries <andreas_kupries@users.sourceforge.net>
#

# # ## ### ##### ######## #############
## Requisites

package require critcl       3

# # ## ### ##### ######## #############

if {![critcl::compiling]} {
    error "Unable to build CRIMP::BMP, no proper compiler found."
}

# # ## ### ##### ######## #############
## Get the local support code. We source it directly because this is
## only needed for building the package, in any mode, and not during
## the runtime. Thus not added to the 'tsources'.

critcl::owns support.tcl
::apply {{here} {
    source $here/support.tcl
}} [file dirname [file normalize [info script]]]

# # ## ### ##### ######## #############
## Administrivia

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
## Pull in the BMP-specific pieces. These are fit under the read/write namespaces.

critcl::owns        format/*bmp*.crimp
crimp_source_cproc {format/*bmp*.crimp}

# # ## ### ##### ######## #############
## Make the C pieces ready. Immediate build of the binaries, no deferal.

if {![critcl::load]} {
    error "Building and loading CRIMP::BMP failed."
}

# # ## ### ##### ######## #############

package provide crimp::bmp 0.1.1
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
