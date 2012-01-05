# -*- tcl -*-
# CRIMP, SGI	Reader for the SGI raster image file format.
#
# (c) 2011 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

package require critcl       3

# # ## ### ##### ######## #############

if {![critcl::compiling]} {
    error "Unable to build CRIMP::SGI, no proper compiler found."
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
    {Extension of the CRIMP core to handle import and export of SGI raster images}

critcl::description {
    This package provides the CRIMP eco-system with the functionality to handle
    images stored as SGI raster images.
}

critcl::subject image {SGI raster image} {SGI raster import} {SGI raster export}
critcl::subject image {image import} {image export} SGI

# # ## ### ##### ######## #############
## Implementation.

critcl::tcl 8.5

# # ## ### ##### ######## #############
## Declare the Tcl layer aggregating the C primitives into useful
## commands. After the Tcl-based readers and writers to properly pick
## them up too in the ensembles.

critcl::tsources policy_sgi.tcl

# # ## ### ##### ######## #############
## C-level API (i.e. stubs and types)

critcl::api import crimp::core 0.1

# # ## ### ##### ######## #############
## Main C section.

critcl::ccode {}

critcl::csources format/sgi.c
critcl::cheaders format/sgi.h

# # ## ### ##### ######## #############
## Pull in the SGI raster-specific pieces. These are fit under the
## read/write namespaces.

critcl::owns        format/*sgi*.crimp
crimp_source_cproc {format/*sgi*.crimp}

# # ## ### ##### ######## #############
## Make the C pieces ready. Immediate build of the binaries, no deferal.

if {![critcl::load]} {
    error "Building and loading CRIMP::SGI failed."
}

# # ## ### ##### ######## #############

package provide crimp::sgi 0.1.1
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
