# -*- tcl -*-
# CRIMP :: PPM // Portable PixMap // Import, Export
#
# (c) 2011 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

package require critcl 3

# # ## ### ##### ######## #############

if {![critcl::compiling]} {
    error "Unable to build CRIMP::PPM, no proper compiler found."
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
    {Extension of the CRIMP core to handle import and export of PPM images}

critcl::description {
    This package provides the CRIMP eco-system with the functionality to handle
    images stored as Portable PixMap (PPM). It can read and write both plain
    and raw formats.
}

critcl::subject image {PPM image} {Portable PixMap} {PPM import} {PPM export}
critcl::subject image {image import} {image export}

# # ## ### ##### ######## #############
## Implementation.

critcl::tcl 8.5

# # ## ### ##### ######## #############
## Declare the Tcl layer aggregating the C primitives into useful
## commands. After the Tcl-based readers and writers to properly pick
## them up too in the ensembles.

critcl::tsources policy_ppm.tcl

# # ## ### ##### ######## #############
## C-level API (i.e. stubs and types)

critcl::api import crimp::core 0.1

# # ## ### ##### ######## #############
## Main C section.

critcl::ccode {
    #include <math.h>
    #include <stdlib.h>
    #include <string.h>
}

# # ## ### ##### ######## #############
## Pull in the PPM-specific pieces. These are fit under the read/write namespaces.

critcl::owns        format/*ppm*.crimp
crimp_source_cproc {format/*ppm*.crimp}

# # ## ### ##### ######## #############
## Make the C pieces ready. Immediate build of the binaries, no deferal.

if {![critcl::load]} {
    error "Building and loading CRIMP::PPM failed."
}

# # ## ### ##### ######## #############

package provide crimp::ppm 0.1.1
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
