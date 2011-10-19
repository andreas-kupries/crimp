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

critcl::cheaders c/coreInt.h
critcl::csources c/image.c
critcl::csources c/volume.c
critcl::csources c/image_type.c
critcl::csources c/buffer.c

# # ## ### ##### ######## #############
## Declare the Tcl layer of the package.

critcl::tsources policy_core.tcl

# # ## ### ##### ######## #############
## C-level API (i.e. types and stubs)

critcl::api header c/common.h
critcl::api header c/image_type.h
critcl::api header c/image.h
critcl::api header c/volume.h
critcl::api header c/buffer.h

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

# - -- --- ----- -------- -------------
## buffer.h

critcl::api function void crimp_buf_init {
    crimp_buffer* b
    Tcl_Obj*      obj
}

critcl::api function int crimp_buf_has {
    crimp_buffer* b
    int           n
}

critcl::api function int crimp_buf_size {
    crimp_buffer* b
}

critcl::api function int crimp_buf_tell {
    crimp_buffer* b
}

critcl::api function int crimp_buf_check {
    crimp_buffer* b
    int           location
}

critcl::api function void crimp_buf_moveto {
    crimp_buffer* b
    int           location
}

critcl::api function void crimp_buf_skip {
    crimp_buffer* b
    int           n
}

critcl::api function void crimp_buf_align {
    crimp_buffer* b
    int           n
}

critcl::api function void crimp_buf_alignr {
    crimp_buffer* b
    int           base
    int           n
}

critcl::api function int crimp_buf_match {
    crimp_buffer* b
    int           n
    char*         str
}

critcl::api function void crimp_buf_read_uint8 {
    crimp_buffer*   b
    {unsigned int*} value
}

critcl::api function void crimp_buf_read_uint16le {
    crimp_buffer*   b
    {unsigned int*} value
}

critcl::api function void crimp_buf_read_uint32le {
    crimp_buffer*   b
    {unsigned int*} value
}

critcl::api function void crimp_buf_read_uint16be {
    crimp_buffer*   b
    {unsigned int*} value
}

critcl::api function void crimp_buf_read_uint32be {
    crimp_buffer*   b
    {unsigned int*} value
}

critcl::api function void crimp_buf_read_int8 {
    crimp_buffer*   b
    int*            value
}

critcl::api function void crimp_buf_read_int16le {
    crimp_buffer*   b
    int*            value
}

critcl::api function void crimp_buf_read_int32le {
    crimp_buffer*   b
    int*            value
}

critcl::api function void crimp_buf_read_int16be {
    crimp_buffer*   b
    int*            value
}

critcl::api function void crimp_buf_read_int32be {
    crimp_buffer*   b
    int*            value
}

# # ## ### ##### ######## #############
## Main C section.

critcl::cinit {
    crimp_imagetype_init ();
} {
    extern void crimp_imagetype_init (void); /* c/image_type.c */
}

# # ## ### ##### ######## #############
## Pull in the implementations of the basic accessor commands.

critcl::owns        core/*.crimp
crimp_source_cproc {core/*.crimp}

# # ## ### ##### ######## #############
## Make the C pieces ready. Immediate build of the binaries, no deferal.

if {![critcl::load]} {
    error "Building and loading CRIMP failed."
}

# # ## ### ##### ######## #############

package provide crimp::core 0.1.1
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
