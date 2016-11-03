# -*- tcl -*-
# CRIMP, SUN	Reader for the SUN raster image file format.
#
# (c) 2011-2016 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

package require critcl       3

# # ## ### ##### ######## #############

if {![critcl::compiling]} {
    error "Unable to build CRIMP::SUN, no proper compiler found."
}

# # ## ### ##### ######## #############
## Administrivia

critcl::license \
    {Andreas Kupries} \
    {Under a BSD license.}

critcl::summary \
    {Extension of the CRIMP core to handle import and export of SUN raster images}

critcl::description {
    This package provides the CRIMP eco-system with the functionality to handle
    images stored as SUN raster images.
}

critcl::subject image {SUN raster image} {SUN raster import} {SUN raster export}
critcl::subject image {image import} {image export} SUN

# # ## ### ##### ######## #############
## Implementation.

critcl::tcl 8.5

# # ## ### ##### ######## #############
## Declare the Tcl layer aggregating the C primitives into useful
## commands. After the Tcl-based readers and writers to properly pick
## them up too in the ensembles.

critcl::tsources policy_sun.tcl

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

critcl::csources format/c/sun.c
critcl::cheaders format/c/sun.h

# # ## ### ##### ######## #############
## Pull in the SUN raster-specific pieces. These are fit under the
## read/write namespaces.

critcl::owns format/*sun*.crimp
crimp_source format/*sun*.crimp

# # ## ### ##### ######## #############
## Make the C pieces ready. Immediate build of the binaries, no deferal.

if {![critcl::load]} {
    error "Building and loading CRIMP::SUN failed."
}

# # ## ### ##### ######## #############

package provide crimp::sun 0.2
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
