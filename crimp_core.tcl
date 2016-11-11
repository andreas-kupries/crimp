# -*- tcl -*-
# CRIMP == C Runtime Image Manipulation Package
#
# (c) 2010      Andrew M. Goth  http://wiki.tcl.tk/andy%20goth
# (c) 2010-2016 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

package require critcl 3.1 ;# 3.1   : critcl::source
#                          ;# 3.0.8 : critcl::at::*

# # ## ### ##### ######## #############
## Bail early if the environment is not suitable.

if {![critcl::compiling]} {
    error "Unable to build CRIMP, no proper compiler found."
}

# # ## ### ##### ######## #############
## Administrivia

critcl::license \
    {Andreas Kupries} \
    {Under a BSD license.}

critcl::summary \
    {The core data structures of all CRIMP packages}

critcl::description {
    This package is the core shared/used by all other CRIMP packages.

    At the C-level it provides the core data structures, functions, and macros
    for images and image types.

    These are reflected in the Tcl level API as well, via the fundamental
    accessors and basic image conversion from and to Tcl data structures
    (nested lists).
}

critcl::subject image {image type} {image accessors} {image construction}
critcl::subject {data structures} {data type}

# # ## ### ##### ######## #############
## Implementation.

critcl::tcl 8.5

# # ## ### ##### ######## #############
## Declare the Tcl layer of the package.

critcl::tsources policy_core.tcl

# # ## ### ##### ######## #############
## C-level API (i.e. types and stubs)

critcl::cheaders   c/coreInt.h
critcl::api header c/common.h

critcl::source core/image_type.api
critcl::source core/image.api
critcl::source core/volume.api
critcl::source core/buffer.api
critcl::source core/rect.api
critcl::source core/interpolate.api

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

crimp_stdint_h

critcl::cinit {
    crimp_imagetype_init ();
} {
    extern void crimp_imagetype_init (void); /* c/image_type.c */
}

critcl::include cutil.h

# # ## ### ##### ######## #############
## Implement the core primitives.

critcl::owns core/*.crimp
crimp_source core/*.crimp

# # ## ### ##### ######## #############
## Make the C pieces ready. Immediate build of the binaries, no deferal.

if {![critcl::load]} {
    error "Building and loading CRIMP failed."
}

# # ## ### ##### ######## #############

package provide crimp::core 0.2
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
