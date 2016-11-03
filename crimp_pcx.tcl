# -*- tcl -*-
# CRIMP, PCX	Reader for the PCX image file format.
#
# (c) 2011-2016 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

package require critcl       3

# # ## ### ##### ######## #############

if {![critcl::compiling]} {
    error "Unable to build CRIMP::PCX, no proper compiler found."
}

# # ## ### ##### ######## #############
## Administrivia

critcl::license \
    {Andreas Kupries} \
    {Under a BSD license.}

critcl::summary \
    {Extension of the CRIMP core to handle import and export of PCX images}

critcl::description {
    This package provides the CRIMP eco-system with the functionality to handle
    images stored as Windows Bitmap (PCX).
}

critcl::subject image {PCX image} {Personal Computer eXchange} {PCX import} {PCX export}
critcl::subject image {image import} {image export} PaintBrush

# # ## ### ##### ######## #############
## Implementation.

critcl::tcl 8.5

# # ## ### ##### ######## #############
## Declare the Tcl layer aggregating the C primitives into useful
## commands. After the Tcl-based readers and writers to properly pick
## them up too in the ensembles.

critcl::tsources policy_pcx.tcl

# # ## ### ##### ######## #############
## C-level API (i.e. stubs and types)

critcl::api import crimp::core 0.2

# # ## ### ##### ######## #############
## Get the local support code. We source it directly because this is
## only needed for building the package, in any mode, and not during
## the runtime. Thus not added to the 'tsources'.
#
## This is shared between the various packages.

critcl::owns   support.tcl
critcl::source support.tcl

# # ## ### ##### ######## #############
## Main C section.

critcl::ccode {}

critcl::csources format/c/pcx.c
critcl::cheaders format/c/pcx.h

# # ## ### ##### ######## #############
## Pull in the PCX-specific pieces. These are fit under the read/write namespaces.

critcl::owns format/*pcx*.crimp
crimp_source format/*pcx*.crimp

# # ## ### ##### ######## #############
## Make the C pieces ready. Immediate build of the binaries, no deferal.

if {![critcl::load]} {
    error "Building and loading CRIMP::PCX failed."
}

# # ## ### ##### ######## #############

package provide crimp::pcx 0.2
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
