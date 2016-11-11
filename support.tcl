# -*- tcl -*-
# CRIMP Build Support Code
#
# (c) 2011-2016 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries

# # ## ### ##### ######## #############
## Requirements

critcl::buildrequirement {
    package require critcl::util 1
}

# # ## ### ##### ######## #############
## Configuration checks

proc crimp_stdint_h {} {
    # Check for the presence of the C99 header <stdint.h>.
    # If we have it, we will use it. If not we will make do with
    # compatibility definitions based on the more prevalent header
    # <limits.h>

    # This works because the package's C code is compiled after the
    # .tcl has been fully processed, regardless of relative location.
    # This enables us to dynamically create/modify a header file
    # needed by the C code.

    lappend paths /usr/include
    lappend paths /usr/local/include
    lappend paths compat
    critcl::cheaders [critcl::util locate stdint.h $paths]/stdint.h
}

# # ## ### ##### ######## #############
## Operator definitions

proc crimp_primitive {name args result body} {
    critcl::at::caller
    critcl::at::incrt $name
    critcl::at::incrt $args
    set bodylocation [critcl::at::get*]
    set args [linsert $args 0 Tcl_Interp* interp]
    ::critcl::cproc ::crimp::$name $args $result $bodylocation$body
}

# # ## ### ##### ######## #############
## Sourcing by patterns

proc crimp_source {args} {
    set rej  {}
    set glob glob
    foreach pattern $args {
	if {[string match !* $pattern]} {
	    lappend rej [string range $pattern 1 end]
	} else {
	    lappend glob $pattern
	}
    }
    foreach path [lsort -dict [eval $glob]] {
	if {[crimp_Rejected $rej $path]} continue
	#critcl::msg -nonewline " \[[file rootname [file tail $path]]\]"
	critcl::msg -nonewline .
	critcl::source $path
    }
    return
}

proc crimp_Rejected {patterns path} {
    foreach pattern $patterns {
	if {[string match $pattern $path]} { return 1 }
    }
    return 0
}

# # ## ### ##### ######## #############
## Custom image argument and result types.

apply {{} {
    # Skip if already done
    if {[critcl::has-argtype image]} return

    foreach type {
	rgba rgb hsv
	grey8 grey16 grey32
	bw double float fpcomplex
    } {
	set map [list <<type>> $type]
	critcl::argtype image_$type [string map $map {
	    if (crimp_get_image_from_obj (interp, @@, &@A) != TCL_OK) {
		return TCL_ERROR;
	    }
	    if (@A->itype != crimp_imagetype_find ("crimp::image::<<type>>")) {
		Tcl_SetObjResult (interp,
				  Tcl_NewStringObj ("expected image type <<type>>",
						    -1));
		return TCL_ERROR;
	    }
	}] crimp_image* crimp_image*

	critcl::argtype image_obj_$type [string map $map {
	    if (crimp_get_image_from_obj (interp, @@, &@A.i) != TCL_OK) {
		return TCL_ERROR;
	    }
	    if (@A.i->itype != crimp_imagetype_find ("crimp::image::<<type>>")) {
		Tcl_SetObjResult (interp,
				  Tcl_NewStringObj ("expected image type <<type>>",
						    -1));
		return TCL_ERROR;
	    }
	    @A.o = @@;
	}] crimp_image_obj crimp_image_obj

	# Note, the support structure is shared with image_obj below,
	# and the guard is specified to reflect that.
	critcl::argtypesupport image_obj_$type {
	    typedef struct crimp_image_obj {
		Tcl_Obj*     o;
		crimp_image* i;
	    } crimp_image_obj;
	} image_obj
    }

    critcl::argtype image {
	if (crimp_get_image_from_obj (interp, @@, &@A) != TCL_OK) {
	    return TCL_ERROR;
	}
    } crimp_image* crimp_image*

    critcl::argtype image_obj {
	if (crimp_get_image_from_obj (interp, @@, &@A.i) != TCL_OK) {
	    return TCL_ERROR;
	}
	@A.o = @@;
    } crimp_image_obj crimp_image_obj

    # Note, the support structure is shared with image_obj_<<type>>
    # above, and the guard above was specified to match us here.
    critcl::argtypesupport image_obj {
	typedef struct crimp_image_obj {
	    Tcl_Obj*     o;
	    crimp_image* i;
	} crimp_image_obj;
    } image_obj

    critcl::resulttype image {
	if (rv == NULL) { return TCL_ERROR; }
	Tcl_SetObjResult (interp, crimp_new_image_obj(rv));
	return TCL_OK;
    } crimp_image*

    critcl::resulttype image_type {
	Tcl_SetObjResult (interp, crimp_new_imagetype_obj(rv));
	return TCL_OK;
    } {const crimp_imagetype*}

    critcl::argtype photo {
	@A = Tk_FindPhoto(interp, Tcl_GetString(@@));
	if (!@A) {
	    Tcl_AppendResult(interp, "image \"", Tcl_GetString(@@), "\" doesn't exist", NULL);
	    return TCL_ERROR;
	}
    } Tk_PhotoHandle Tk_PhotoHandle

}}

# # ## ### ##### ######## #############
