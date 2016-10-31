# -*- tcl -*-
# CRIMP Build Support Code
#
# (c) 2011-2016 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries

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
	bw float fpcomplex
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
    }

    critcl::argtype image {
	if (crimp_get_image_from_obj (interp, @@, &@A) != TCL_OK) {
	    return TCL_ERROR;
	}
    } crimp_image* crimp_image*

    critcl::resulttype image {
	if (rv == NULL) { return TCL_ERROR; }
	Tcl_SetObjResult (interp, crimp_new_image_obj(rv));
	return TCL_OK;
    } crimp_image*

    critcl::resulttype image_type {
	Tcl_SetObjResult (interp, crimp_new_imagetype_obj(rv));
	return TCL_OK;
    } crimp_imagetype*
}}

# # ## ### ##### ######## #############
## DEPRECATED, remove when all uses are gone.

proc crimp_source_cproc {accept {reject {}}} {
    set here [file dirname [file normalize [info script]]]

    foreach pa $accept {
	foreach filename [lsort -dict [glob -nocomplain -tails -directory $here $pa]] {
	    set take 1
	    foreach pr $reject {
		if {![string match $pr $filename]} continue
		set take 0
		break
	    }
	    if {!$take} continue

	    #critcl::msg -nonewline " \[[file rootname [file tail $filename]]\]"
	    critcl::msg -nonewline .

	    set chan [open $here/$filename r]
	    set name ::crimp::[gets $chan]
	    set params "Tcl_Interp* interp"
	    set number 2
	    while {1} {
		incr number
		set line [gets $chan]
		if {$line eq ""} {
		    break
		}
		append params " $line"
	    }
	    set body "\n#line $number \"[file tail $filename]\"\n[read $chan]"
	    close $chan
	    ::critcl::cproc $name $params ok $body
	}
    }
    return
}
