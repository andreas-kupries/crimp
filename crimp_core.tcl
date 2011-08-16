# -*- tcl -*-
# CRIMP == C Runtime Image Manipulation Package
#
# (c) 2010 Andrew M. Goth  http://wiki.tcl.tk/andy%20goth
# (c) 2010 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

package require critcl       3

# # ## ### ##### ######## #############

if {![critcl::compiling]} {
    error "Unable to build CRIMP, no proper compiler found."
}

critcl::license \
    {Andreas Kupries} \
    {Under a BSD license.}

critcl::summary {The core data structures of all CRIMP packages}
critcl::description {
    This package provides the core data structures, functions, and
    macros for images and image types. It is the core shared/used by
    all other CRIMP packages. The provided API is at the C-level, a
    stubs table without any Tcl bindings. For these we have the
    other packages in the CRIMP eco-system.
}

critcl::subject {data structures}
critcl::subject {core functionality}
critcl::subject {image data type}
critcl::subject {image-type data type}
critcl::subject {data types}

# # ## ### ##### ######## #############
## Implementation.

critcl::tcl 8.5

critcl::cheaders c/coreInt.h
critcl::csources c/image.c
critcl::csources c/volume.c
critcl::csources c/image_type.c

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
    crimp_imagetype_init ();
} {
    extern void crimp_imagetype_init (void); /* c/image_type.c */
}

critcl::ccode {}

# # ## ### ##### ######## #############
## Make the C pieces ready. Immediate build of the binaries, no deferal.

if {![critcl::load]} {
    error "Building and loading CRIMP failed."
}

# # ## ### ##### ######## #############

package provide crimp::core 0.1
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
