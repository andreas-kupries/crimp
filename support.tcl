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
    return
    # Check for the presence of the C99 header <stdint.h>.
    # If we have it, we will use it. If not we will make do with
    # compatibility definitions based on the more prevalent header
    # <limits.h>

    # This works because the package's C code is compiled after the
    # .tcl has been fully processed, regardless of relative location.
    # This enables us to dynamically create/modify a header file
    # needed by the C code.

    lappend paths /usr/include/stdint.h
    lappend paths /usr/local/include/stdint.h
    lappend paths compat/stdint.h
    critcl::cheaders [critcl::util locate stdint.h $paths]
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
		Tcl_SetResult (interp, "expected image type <<type>>", TCL_STATIC);
		return TCL_ERROR;
	    }
	}] crimp_image* crimp_image*

	critcl::argtype image_obj_$type [string map $map {
	    if (crimp_get_image_from_obj (interp, @@, &@A.i) != TCL_OK) {
		return TCL_ERROR;
	    }
	    if (@A.i->itype != crimp_imagetype_find ("crimp::image::<<type>>")) {
		Tcl_SetResult (interp, "expected image type <<type>>", TCL_STATIC);
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

	# Kernel extends image<<type>>
	critcl::argtype kernel_$type [string map $map {
	    if (crimp_get_image_from_obj (interp, @@, &@A) != TCL_OK) {
		return TCL_ERROR;
	    }
	    if (@A->itype != crimp_imagetype_find ("crimp::image::<<type>>")) {
		Tcl_SetResult (interp, "expected image type <<type>>", TCL_STATIC);
		return TCL_ERROR;
	    }
	    if (((crimp_w (@A) % 2) == 0) ||
		((crimp_h (@A) % 2) == 0)) {
		Tcl_SetResult(interp, "bad kernel dimensions, expected odd size", TCL_STATIC);
		return TCL_ERROR;
	    }
	}] crimp_image* crimp_image*


	# LUT extends image<<type>>
	critcl::argtype lut_$type [string map $map {
	    if (crimp_get_image_from_obj (interp, @@, &@A) != TCL_OK) {
		return TCL_ERROR;
	    }
	    if (@A->itype != crimp_imagetype_find ("crimp::image::<<type>>")) {
		Tcl_SetResult (interp, "expected image type <<type>>", TCL_STATIC);
		return TCL_ERROR;
	    }
	    if (!crimp_require_dim (@A, 256, 1)) {
		Tcl_SetResult(interp, "bad map dimension, expected 256x1", TCL_STATIC);
		return TCL_ERROR;
	    }
	}] crimp_image* crimp_image*

	critcl::argtype sqlut_$type [string map $map {
	    if (crimp_get_image_from_obj (interp, @@, &@A) != TCL_OK) {
		return TCL_ERROR;
	    }
	    if (@A->itype != crimp_imagetype_find ("crimp::image::<<type>>")) {
		Tcl_SetResult (interp, "expected image type <<type>>", TCL_STATIC);
		return TCL_ERROR;
	    }
	    if (!crimp_require_dim (@A, 256, 256)) {
		Tcl_SetResult(interp, "bad map dimensions, expected 256x256", TCL_STATIC);
		return TCL_ERROR;
	    }
	}] crimp_image* crimp_image*



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
	    Tcl_AppendResult(interp, "image \"", Tcl_GetString(@@), "\" doesn't exist",
			     NULL);
	    return TCL_ERROR;
	}
    } Tk_PhotoHandle Tk_PhotoHandle

    # Extend image_double with additional requirements.
    critcl::argtype projective-transform {
	if (crimp_get_image_from_obj (interp, @@, &@A) != TCL_OK) {
	    return TCL_ERROR;
	}
	if (@A->itype != crimp_imagetype_find ("crimp::image::double")) {
	    Tcl_SetResult (interp, "expected image type double", TCL_STATIC);
	    return TCL_ERROR;
	}
	if (!crimp_require_dim (@A, 3, 3)) {
	    Tcl_SetResult(interp, "bad matrix dimensions, expected 3x3", TCL_STATIC);
	    return TCL_ERROR;
	}
    } crimp_image* crimp_image*

    critcl::argtype color-transform {
	if (crimp_get_image_from_obj (interp, @@, &@A) != TCL_OK) {
	    return TCL_ERROR;
	}
	if (@A->itype != crimp_imagetype_find ("crimp::image::double")) {
	    Tcl_SetResult (interp, "expected image type double", TCL_STATIC);
	    return TCL_ERROR;
	}
	if (!crimp_require_dim (@A, 3, 3)) {
	    Tcl_SetResult(interp, "bad color transform dimensions, expected 3x3", TCL_STATIC);
	    return TCL_ERROR;
	}
    } crimp_image* crimp_image*

    critcl::argtype color-weights {
	if (crimp_get_image_from_obj (interp, @@, &@A) != TCL_OK) {
	    return TCL_ERROR;
	}
	if (@A->itype != crimp_imagetype_find ("crimp::image::double")) {
	    Tcl_SetResult (interp, "expected image type double", TCL_STATIC);
	    return TCL_ERROR;
	}
	if (!crimp_require_dim (@A, 3, 1)) {
	    Tcl_SetResult(interp, "bad color weight dimensions, expected 3x3", TCL_STATIC);
	    return TCL_ERROR;
	}
    } crimp_image* crimp_image*
}}

# # ## ### ##### ######## #############

proc crimp_map_type {type} {
    dict get {
	float  float
	double double
	grey32 {unsigned int}
	grey16 {unsigned short}
	grey8  {unsigned char}
    } $type
}

# # ## ### ##### ######## #############
## pixelwise image manipulation
## __NOTE__ As is not usable for multi-channel image types

proc crimp_map_pixel {intype name arguments outtype body} {
    critcl::at::caller
    critcl::at::incrt $intype
    critcl::at::incrt $name
    critcl::at::incrt $arguments
    critcl::at::incrt $outtype
    set bodylocation [critcl::at::get*]

    if {$intype eq $outtype} {
	set constructor crimp_new_like
	append name _$intype
    } else {
	set constructor crimp_new_${outtype}_like
	append name _2${outtype}_$intype
    }

    lappend map <<intype>>         [crimp_map_type $intype]
    lappend map <<outtype>>        [crimp_map_type $outtype]
    lappend map <<transformation>> \
	$bodylocation[string map $map $body]
    lappend map <<constructor>>    $constructor

    lappend params \
	image_$intype image \
	{*}$arguments

    crimp_primitive $name \
	$params \
	image \
	[string map $map {
	    crimp_image* result = <<constructor>> (image);
	    int          area   = crimp_image_area (image);

	    int idx;
	    ITER (<<intype>>,  incursor,  image);
	    ITER (<<outtype>>, outcursor, result);

	    for (idx = 0; idx < area; idx++, NEXT (incursor), NEXT (outcursor)) {
		<<outtype>> z;
		<<intype>> a = CURRENT (incursor);
		<<transformation>>
		CURRENT (outcursor) = z;
	    }

	    return result;
	}]
}

# # ## ### ##### ######## #############
