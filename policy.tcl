## -*- tcl -*-
# # ## ### ##### ######## #############
## This file defines a number of commands on top of the C primitives
## which are easier to use than directly calling on the latter.

namespace eval ::crimp {}

# # ## ### ##### ######## #############

proc ::crimp::ALIGN {image size where fe values} {
    # Do nothing if the image is at the requested size.

    switch -exact -- $where {
	top - center - bottom {
	    set delta [expr {$size - [height $image]}]
	    if {!$delta} { return $image }
	}
	left - middle - right {
	    set delta [expr {$size - [width $image]}]
	    if {!$delta} { return $image }
	}
    }

    # Expand the image to the requested size, with the alignment
    # specifying which border(s) to expand.

    set n 0
    set s 0
    set e 0
    set w 0

    switch -exact -- $where {
	top    { set s $delta }
	bottom { set n $delta }
	left   { set e $delta }
	right  { set w $delta }
	center {
	    # In the centerline. If an even split is not possible move
	    # it one pixel down.
	    set d [expr {$delta/2}]
	    set n $d
	    set s $d
	    if {$delta % 2 == 1} { incr n }
	}
	middle {
	    # In the middle. If an even split is not possible move it
	    # one pixel to the right.
	    set d [expr {$delta/2}]
	    set w $d
	    set e $d
	    if {$delta % 2 == 1} { incr w }
	}
    }

    # Run the expansion.
    return [::crimp::$fe $image $w $n $e $s {*}$values]
}

proc ::crimp::INTERPOLATE {argv} {
    upvar 1 $argv args

    # Default interpolation method. Compromise between accuracy and
    # speed.
    set imethod bilinear

    set at 0
    while {[string match -* [set opt [lindex $args $at]]]} {
	switch -exact -- $opt {
	    -interpolate {
		incr at
		set val [lindex $args $at]
		set legal {nneighbour bilinear bicubic}
		if {$val ni $legal} {
		    return -code error "Expected one of [linsert end [join $legal ,] or], got \"$val\""
		}
		set imethod $val
	    }
	    default {
		return -code error "Expected -interpolate, got \"$opt\""
	    }
	}
	incr at
    }

    set args [lrange $args $at end]
    return $imethod
}

proc ::crimp::BORDER {imagetype spec} {
    set values [lassign $spec bordertype]

    if {![llength [List expand_*_$bordertype]]} {
	# TODO :: Compute/memoize available border types.
	set chop [string length ::crimp::expand_${imagetype}_]
	set btypes {}
	foreach x [lsort -dict [List expand_${imagetype}_*]] {
	    lappend btypes [string range $x $chop end]
	}
	set btypes [linsert [::join $btypes {, }] end-1 or]
	return -code error "Unknown border type \"$bordertype\", expected one of $btypes"
    }

    set f expand_${imagetype}_$bordertype
    if {![Has $f]} {
	return -code error "Unable to expand images of type \"$type\" by border \"$bordertype\""
    }

    # Process type specific arguments.
    switch -- $bordertype {
	const {
	    # TODO :: Introspect number of color channels from image
	    # type, then extend or reduce the values accordingly.
	    #
	    # FOR NOW :: Hardwired map.
	    # SEE ALSO :: remap, blank.
	    # TODO :: Unify using some higher-order code.

	    switch -- $imagetype {
		hsv - rgb {
		    if {![llength $values]} {
			set values {0 0 0}
		    }
		    while {[llength $values] < 3} {
			lappend values [lindex $values end]
		    }
		    if {[llength $values] > 3} {
			set values [lrange $values 0 2]
		    }
		}
		rgba {
		    if {![llength $values]} {
			set values {0 0 0 255}
		    }
		    while {[llength $values] < 3} {
			lappend values [lindex $values end]
		    }
		    if {[llength $values] < 4} {
			lappend values 255
		    }
		    if {[llength $values] > 4} {
			set values [lrange $values 0 3]
		    }
		}
		float -
		grey32 -
		grey16 -
		grey8 {
		    if {![llength $values]} {
			set values {0}
		    } elseif {[llength $values] > 1} {
			set values [lrange $values 0 0]
		    }
		}
		fpcomplex {
		    if {![llength $values]} {
			set values {0 0}
		    }
		    while {[llength $values] < 2} {
			lappend values [lindex $values end]
		    }
		    if {[llength $values] > 2} {
			set values [lrange $values 0 1]
		    }
		}
	    }
	}
	default {
	    if {[llength $values]} {
		return -code error "wrong\#args: no values accepted by \"$bordertype\" borders"
	    }
	}
    }

    return [list $f $values]
}

proc ::crimp::GCD {p q} {
    # Taken from http://wiki.tcl.tk/752
    while {1} {
	if {$q == 0} {
	    # Termination case
	    break
	} elseif {$p>$q} {
	    # Swap p and q
	    set t $p
	    set p $q
	    set q $t
	}
	set q [expr {$q%$p}]
    }
    return $p
}

# # ## ### ##### ######## #############

namespace eval ::crimp::convert {
    namespace export *
    namespace ensemble create
}

::apply {{} {
    # Converters implemented as C primitives
    foreach fun [::crimp::List convert_*] {

	if {[string match {*_2[rh]*_*} $fun]} {
	    # Conversion from grey8 to the multi-channel types (rgb,
	    # rgba, hsv) needs special handling in the converter to
	    # allow for a conversion with and without a color
	    # gradient.

	    set dst [lindex [::crimp::P $fun] 0]
	    set it  [string range $dst 1 end]

	    switch -exact -- $it {
		hsv  {set b {{0 0 0}}   ; set w {{0 0 255}}}
		rgb  {set b {{0 0 0}}   ; set w {{255 255 255}}}
		rgba {set b {{0 0 0 0}} ; set w {{255 255 255 255}}}
	    }

	    proc $dst {image {gradient {}}} \
		[string map [list @ $dst % $it <W> $w <B> $b] {
		    set type [::crimp::TypeOf $image]
		    # Pass through unchanged if the image is already of
		    # the requested type.
		    if {"2$type" eq "@"} {
			return $image
		    }
		    set f convert_@_${type}
		    if {![::crimp::Has $f]} {
			return -code error "Unable to convert images of type \"$type\" to \"@\""
		    }

		    if {$type eq "grey8"} {
			if {[llength [info level 0]] < 3} {
			    # Standard gradient, plain black to white greyscale
			    set gradient [::crimp::gradient % <B> <W> 256]
			}
			return [::crimp::$f $image $gradient]
		    } else {
			# anything else has no gradient
			if {[llength [info level 0]] == 3} {
			    return -code error "wrong#args: should be \"::crimp::$f imageObj\""
			}
			return [::crimp::$f $image]
		    }
		}]

	} else {
	    # Standard converters not requiring additional arguments
	    # to guide/configure the process.

	    proc [lindex [::crimp::P $fun] 0] {image} \
		[string map [list @ [lindex [::crimp::P $fun] 0]] {
		    set type [::crimp::TypeOf $image]
		    # Pass through unchanged if the image is already of
		    # the requested type.
		    if {"2$type" eq "@"} {
			return $image
		    }
		    set f    convert_@_${type}
		    if {![::crimp::Has $f]} {
			return -code error "Unable to convert images of type \"$type\" to \"@\""
		    }
		    return [::crimp::$f $image]
		}]
	}
    }
} ::crimp::convert}

# # ## ### ##### ######## #############

namespace eval ::crimp::join {
    namespace export *
    namespace ensemble create
}

::apply {{} {
    foreach fun [::crimp::List join_*] {
	proc [::crimp::P $fun] {args} [string map [list @ $fun] {
	    # TODO : Check arguments for proper type.
	    return [@ {*}$args]
	}]
    }
} ::crimp::join}

# # ## ### ##### ######## #############

namespace eval ::crimp::flip {
    namespace export *
    namespace ensemble create
}

::apply {{} {
    foreach fun [::crimp::List flip_*] {
	proc [lindex [::crimp::P $fun] 0] {image} \
	    [string map [list @ [lindex [::crimp::P $fun] 0]] {
		set type [::crimp::TypeOf $image]
		set f    flip_@_$type
		if {![::crimp::Has $f]} {
		    return -code error "Unable to flip @ images of type \"$type\""
		}
		return [::crimp::$f $image]
	    }]
    }
} ::crimp::flip}

# # ## ### ##### ######## #############

namespace eval ::crimp::rotate {
    namespace export *
    namespace ensemble create
}

proc ::crimp::rotate::ccw {image} {
    return [::crimp::flip::vertical [::crimp::flip::transpose $image]]
}

proc ::crimp::rotate::cw {image} {
    return [::crimp::flip::horizontal [::crimp::flip::transpose $image]]
}

proc ::crimp::rotate::half {image} {
    return [::crimp::flip::horizontal [::crimp::flip::vertical $image]]
}

# # ## ### ##### ######## #############

proc ::crimp::resize {args} {
    return [Resize [::crimp::INTERPOLATE args] {*}$args]
}

proc ::crimp::Resize {interpolation image w h} {
    # Resize the image to new width and height.

    # Note that the projective transform can leave the image a bit to
    # large, due to it rounding the west and south borders up (ceil)
    # when going from rational to integral coordinates. This is fixed
    # by cutting the result to the proper dimensions.

    return [cut [warp::Projective $interpolation $image \
		     [transform::scale \
			  [expr {double($w)/[width  $image]}] \
			  [expr {double($h)/[height $image]}]]] \
		0 0 $w $h]
}

# # ## ### ##### ######## #############
## All morphology operations are currently based on a single
## structuring element, the flat 3x3 brick.

namespace eval ::crimp::morph {
    namespace export *
    namespace ensemble create
}

proc ::crimp::morph::erode {image} {
    return [::crimp::filter::rank $image 1 0]
}

proc ::crimp::morph::dilate {image} {
    return [::crimp::filter::rank $image 1 99.99]
}

proc ::crimp::morph::open {image} {
    return [dilate [erode $image]]
}

proc ::crimp::morph::close {image} {
    return [erode [dilate $image]]
}

proc ::crimp::morph::gradient {image} {
    return [::crimp::subtract [dilate $image] [erode $image]]
}

proc ::crimp::morph::igradient {image} {
    return [::crimp::subtract $image [erode $image]]
}

proc ::crimp::morph::egradient {image} {
    return [::crimp::subtract [dilate $image] $image]
}

proc ::crimp::morph::tophatw {image} {
    return [::crimp::subtract $image [open $image]]
}

proc ::crimp::morph::tophatb {image} {
    return [::crimp::subtract [close $image] $image]
}

proc ::crimp::morph::toggle {image} {
    return [::crimp::add [erode $image] [dilate $image] 2]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::montage {
    namespace export *
    namespace ensemble create
}

proc ::crimp::montage::horizontal {args} {
    # option processing (expansion type, vertical alignment) ...

    # Default settings for border expansion in alignment.
    set border    const
    set alignment center

    set at 0
    while {1} {
	set opt [lindex $args $at]
	if {![string match -* $opt]} break
	incr at
	switch -- $opt {
	    -align {
		set alignment [lindex $args $at]
		if {$alignment ni {top center bottom}} {
		    return -code error "Illegal vertical alignment \"$alignment\", expected bottom, center, or top"
		}
		incr at
	    }
	    -border {
		set border [lindex $args $at]
		incr at
	    }
	    default {
		return -code error "Unknown option \"$opt\", expected -align, or -border"
	    }
	}
    }
    set args [lrange $args $at end]

    if {[llength $args] == 1} {
	# Check border settings. While irrelevant for the single image
	# case we don't wish to accept something bogus even so.

	set image [lindex $args 0]
	crimp::BORDER [::crimp::TypeOf $image] $border
	return $image
    } elseif {[llength $args] == 0} {
	return -code error "No images to montage"
    }

    # Check type, and compute max height, for border expansion.
    set type {}
    set height 0
    foreach image $args {
	set itype [::crimp::TypeOf $image]
	if {($type ne {}) && ($type ne $itype)} {
	    return -code error "Type mismatch, unable to montage $type to $itype"
	}
	set type   $itype
	set height [tcl::mathfunc::max $height [::crimp::height $image]]
    }

    lassign [::crimp::BORDER $type $border] fe values

    set f montageh_${type}
    if {![::crimp::Has $f]} {
	return -code error "Unable to montage images of type \"$type\""
    }

    # todo: investigate ability of critcl to have typed var-args
    # commands.
    set remainder [lassign $args result]
    set result    [::crimp::ALIGN $result $height $alignment $fe $values]
    foreach image $remainder {
	set image [::crimp::ALIGN $image $height $alignment $fe $values]
	set result [::crimp::$f $result $image]
    }
    return $result
}

proc ::crimp::montage::vertical {args} {
    # option processing (expansion type, vertical alignment) ...

    # Default settings for border expansion in alignment.
    set border    const
    set alignment middle

    set at 0
    while {1} {
	set opt [lindex $args $at]
	if {![string match -* $opt]} break
	incr at
	switch -- $opt {
	    -align {
		set alignment [lindex $args $at]
		if {$alignment ni {left middle right}} {
		    return -code error "Illegal horizontal alignment \"$alignment\", expected left, middle, or right"
		}
		incr at
	    }
	    -border {
		set border [lindex $args $at]
		incr at
	    }
	    default {
		return -code error "Unknown option \"$opt\", expected -align, or -border"
	    }
	}
    }
    set args [lrange $args $at end]

    if {[llength $args] == 1} {
	# Check border settings. While irrelevant for the single image
	# case we don't wish to accept something bogus even so.

	set image [lindex $args 0]
	crimp::BORDER [::crimp::TypeOf $image] $border
	return $image
    } elseif {[llength $args] == 0} {
	return -code error "No images to montage"
    }

    # Check type, and compute max width, for border expansion.
    set type {}
    set width 0
    foreach image $args {
	set itype [::crimp::TypeOf $image]
	if {($type ne {}) && ($type ne $itype)} {
	    return -code error "Type mismatch, unable to montage $type to $itype"
	}
	set type   $itype
	set width [tcl::mathfunc::max $width [::crimp::width $image]]
    }

    lassign [::crimp::BORDER $type $border] fe values

    set f montagev_${type}
    if {![::crimp::Has $f]} {
	return -code error "Unable to montage images of type \"$type\""
    }

    # todo: investigate ability of critcl to have typed var-args
    # commands.
    set remainder [lassign $args result]
    set result    [::crimp::ALIGN $result $width $alignment $fe $values]
    foreach image $remainder {
	set image [::crimp::ALIGN $image $width $alignment $fe $values]
	set result [::crimp::$f $result $image]
    }
    return $result
}

# # ## ### ##### ######## #############

proc ::crimp::invert {image} {
    remap $image [map invers]
}

proc ::crimp::solarize {image n} {
    remap $image [map solarize $n]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::effect {
    namespace export *
    namespace ensemble create
}

proc ::crimp::effect::sharpen {image} {
    # http://wiki.tcl.tk/9521
    return [::crimp::filter::convolve $image \
		[::crimp::kernel::make {
		    { 0  -1  0}
		    {-1   5 -1}
		    { 0  -1  0}} 1]]
}

proc ::crimp::effect::emboss {image} {
    # http://wiki.tcl.tk/9521 (Suchenwirth)
    return [::crimp::filter::convolve $image \
		[::crimp::kernel::make {
		    {2  0  0}
		    {0 -1  0}
		    {0  0 -1}}]]
}

proc ::crimp::effect::charcoal {image} {
    return [::crimp::invert \
		[::crimp::morph::gradient \
		     [::crimp::convert::2grey8 $image]]]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::threshold {
    namespace export *
    namespace ensemble create
    namespace eval global {
	namespace export *
	namespace ensemble create
    }
}

# TODO :: auto-create from the methods of 'table threshold'.
# TODO :: introspect the threshold ensemble !

proc ::crimp::threshold::global::below {image n} {
    if {[::crimp::TypeOf $image] eq "float"} {
	return [crimp::thresholdg_below $image $n]
    } else {
	return [::crimp::remap $image [::crimp::map threshold below $n]]
    }
}

proc ::crimp::threshold::global::above {image n} {
    if {[::crimp::TypeOf $image] eq "float"} {
	return [crimp::thresholdg_above $image $n]
    } else {
	return [::crimp::remap $image [::crimp::map threshold above $n]]
    }
}

proc ::crimp::threshold::global::inside {image min max} {
    if {[::crimp::TypeOf $image] eq "float"} {
	return [crimp::thresholdg_inside $image $min $max]
    } else {
	return [::crimp::remap $image [::crimp::map threshold inside $min $max]]
    }
}

proc ::crimp::threshold::global::outside {image min max} {
    if {[::crimp::TypeOf $image] eq "float"} {
	return [crimp::thresholdg_outside $image $min $max]
    } else {
	return [::crimp::remap $image [::crimp::map threshold outside $min $max]]
    }
}

proc ::crimp::threshold::global::otsu {image} {
    set maps {}
    set stat [::crimp::statistics::otsu [::crimp::statistics::basic $image]]

    if {[::crimp::TypeOf $image] eq "float"} {
	return [crimp::thresholdg_above $image \
		    [dict get $stat channel value otsu]]
    } else {
	foreach c [dict get $stat channels] {
	    lappend maps \
		[::crimp::map threshold above \
		     [dict get $stat channel $c otsu]]
	}
	return [::crimp::remap $image {*}$maps]
    }
}

proc ::crimp::threshold::global::middle {image} {
    set maps {}
    set stat [::crimp::statistics::basic $image]
    if {[::crimp::TypeOf $image] eq "float"} {
	return [crimp::thresholdg_above $image \
		    [dict get $stat channel value middle]]
    } else {
	foreach c [dict get $stat channels] {
	    lappend maps \
		[::crimp::map threshold above \
		     [dict get $stat channel $c middle]]
	}
	return [::crimp::remap $image {*}$maps]
    }
}

proc ::crimp::threshold::global::mean {image} {
    set maps {}
    set stat [::crimp::statistics::basic $image]
    if {[::crimp::TypeOf $image] eq "float"} {
	return [crimp::thresholdg_above $image \
		    [dict get $stat channel value mean]]
    } else {
	foreach c [dict get $stat channels] {
	    lappend maps \
		[::crimp::map threshold above \
		     [dict get $stat channel $c mean]]
	}
	return [::crimp::remap $image {*}$maps]
    }
}

proc ::crimp::threshold::global::median {image} {
    set maps {}
    set stat [::crimp::statistics::basic $image]
    if {[::crimp::TypeOf $image] eq "float"} {
	return [crimp::thresholdg_above $image \
		    [dict get $stat channel value median]]
    } else {
	foreach c [dict get $stat channels] {
	    lappend maps \
		[::crimp::map threshold above \
		     [dict get $stat channel $c median]]
	}
	return [::crimp::remap $image {*}$maps]
    }
}

proc ::crimp::threshold::local {image args} {
    if {![llength $args]} {
	return -code error "wrong\#args: expected image map..."
    }

    set itype [::crimp::TypeOf $image]
    set mtype [::crimp::TypeOf [lindex $args 0]]

    foreach map $args {
	set xtype [::crimp::TypeOf $map]
	if {$xtype ne $mtype} {
	    return -code error "Map type mismatch between \"$mtype\" and \"$xtype\", all maps have to have the same type."
	}
    }

    # Multi-channel inputs with single-channel thresholds are handled
    # specially. Not only are we shrinking or extending the set of
    # thresholding maps if too many or not enough were specified (the
    # latter by replicating the last map), but we also have to split
    # the input and then rejoin the results. This may also require us
    # to resize the separate planes to match as the individual binary
    # operations may have left us with results of differing geometries.

    set multi 0
    switch -glob -- $itype/$mtype {
	fpcomplex/fpcomplex - rgba/rgba - rgb/rgb - hsv/hsv {
	    # Nothing to do. Handled later by the generic branch.
	}
	fpcomplex/float -
	fpcomplex/grey8 {
	    if {[llength $args]} {
		while {[llength $args] < 2} {
		    lappend args [lindex $args end]
		}
	    }
	    if {[llength $args] > 2} {
		set args [lrange $args 0 1]
	    }
	    set multi 1
	}
	hsv/float - rgb/float -
	hsv/grey8 - rgb/grey8 {
	    if {[llength $args]} {
		while {[llength $args] < 3} {
		    lappend args [lindex $args end]
		}
	    }
	    if {[llength $args] > 3} {
		set args [lrange $args 0 2]
	    }
	    set multi 1
	}
	rgba/float -
	rgba/grey8 {
	    if {[llength $args]} {
		while {[llength $args] < 4} {
		    lappend args [lindex $args end]
		}
	    }
	    if {[llength $args] > 4} {
		set args [lrange $args 0 3]
	    }
	    set multi 1
	}
	fpcomplex/* - rgba/* - rgb/* - hsv/* {
	    return -code error "Unable to locally threshold images of type \"$itype\" with maps of type \"$mtype\""
	}
    }

    if {$multi} {
	foreach plane [::crimp::split $image] threshold $args {
	    lappend result [local $plane $threshold]
	}

	# Match geometries... Compute the union bounding box from the
	# result planes, then expand the planes to match it, at last
	# join them.

	set bbox [::crimp::bbox {*}$result]
	foreach plane $result {
	    lappend matched [::crimp::matchgeo $plane $bbox]
	}
	return [::crimp::join::2$itype {*}$matched]
    }

    set f threshold_${itype}_$mtype
    if {![::crimp::Has $f]} {
	return -code error "Unable to locally threshold images of type \"$itype\" with maps of type \"$mtype\""
    }

    return [::crimp::$f $image {*}$args]
}

# # ## ### ##### ######## #############

proc ::crimp::gamma {image y} {
    remap $image [map gamma $y]
}

proc ::crimp::degamma {image y} {
    remap $image [map degamma $y]
}

# # ## ### ##### ######## #############

proc ::crimp::remap {image args} {
    set type [TypeOf $image]
    if {![Has map_$type]} {
	return -code error "Unable to re-map images of type \"$type\""
    }

    # Extend the set of maps if not enough were specified, by
    # replicating the last map, except for the alpha channel, where we
    # use identity.

    switch -- $type {
	hsv - rgb {
	    if {[llength $args]} {
		while {[llength $args] < 3} {
		    lappend args [lindex $args end]
		}
	    }
	}
	rgba {
	    if {[llength $args]} {
		while {[llength $args] < 3} {
		    lappend args [lindex $args end]
		}
		if {[llength $args] < 4} {
		    lappend args [map identity]
		}
	    }
	}
    }

    return [map_$type $image {*}$args]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::contrast {
    namespace export {[0-9a-z]*}
    namespace ensemble create
}

proc ::crimp::contrast::normalize {image {percentile 5}} {
    set itype [::crimp::TypeOf $image]
    switch -exact -- $itype {
	rgb - rgba - hsv {
	    set sb [::crimp::statistics::basic $image]
	    set result {}
	    foreach chan [::crimp::split $image] name [dict get $sb channels] {
		if {$name ne "alpha"} {
		    set chan [NORM $chan $percentile [dict get $sb channel $name]]
		}
		lappend result $chan
	    }
	    return [::crimp::join::2$itype {*}$result]
	}
	grey8 {
	    return [NORM $image $percentile [dict get [::crimp::statistics::basic $image] channel luma]]
	}
	default {
	    return -code error "global histogram equalization not supported for image type \"$itype\""
	}
    }
}

proc ::crimp::contrast::NORM {image percentile statistics} {
    # GREY8 normalization (stretching).

    set mint [expr {$percentile*255./100}]
    set maxt [expr {255 - $mint}]
    set cdf  [dict get $statistics cdf255]

    set min 0
    foreach count $cdf {
	if {$count >= $mint} break
	incr min
    }

    set max 0
    foreach count $cdf {
	incr max
	if {$count >= $maxt} break
    }

    return [::crimp::remap $image [::crimp::map stretch $min $max]]
}

namespace eval ::crimp::contrast::equalize {
    namespace export {[0-9a-z]*}
    namespace ensemble create
}

proc ::crimp::contrast::equalize::local {image args} {

    set itype [::crimp::TypeOf $image]
    switch -exact -- $itype {
	rgb {
	    # Recursive invokation with conversion into and out of the
	    # proper type.
	    return [::crimp::convert::2rgb [local [::crimp::convert::2hsv $image] {*}$args]]
	}
	rgba {
	    # Recursive invokation, with conversion into and out of
	    # the proper type, making sure to leave the alpha-channel
	    # untouched.

	    return [crimp::alpha::set \
			[::crimp::convert::2rgb [local [::crimp::convert::2hsv $image] {*}$args]] \
			[lindex [::crimp::split $image] end]]
	}
	hsv {
	    # The equalization is done on the value/luma channel only.
	    lassign [::crimp::split $image] h s v
	    return [::crimp::join::2hsv $h $s [::crimp::filter::ahe $v {*}$args]]
	}
	grey8 {
	    return [::crimp::filter::ahe $image {*}$args]
	}
	default {
	    return -code error "local (adaptive) histogram equalization not supported for image type \"$itype\""
	}
    }
}

proc ::crimp::contrast::equalize::global {image} {
    set itype [::crimp::TypeOf $image]
    switch -exact -- $itype {
	rgb {
	    # Recursive invokation with conversion into and out of the
	    # proper type.
	    return [::crimp::convert::2rgb [global [::crimp::convert::2hsv $image]]]
	}
	rgba {
	    # Recursive invokation, with conversion into and out of
	    # the proper type, making sure to leave the alpha-channel
	    # untouched.

	    return [crimp::alpha::set \
			[::crimp::convert::2rgb [global [::crimp::convert::2hsv $image]]] \
			[lindex [::crimp::split $image] end]]
	}
	hsv {
	    lassign [::crimp::split $image] h s v
	    return [::crimp::join::2hsv $h $s [GLOBAL $v]]
	}
	grey8 {
	    return [GLOBAL $image]
	}
	default {
	    return -code error "global histogram equalization not supported for image type \"$itype\""
	}
    }
}

proc ::crimp::contrast::equalize::GLOBAL {image} {
    # GREY8 equalization.
    return [::crimp::remap $image \
		[crimp::mapof \
		     [::crimp::FIT \
			  [::crimp::CUMULATE \
			       [dict values [dict get [::crimp::histogram $image] luma]]] \
			  255]]]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::color {
    namespace export {[0-9a-z]*}
    namespace ensemble create

    variable typecode crimp/colortransform
}

proc ::crimp::color::mix {image colortransform} {
    set itype [::crimp::TypeOf $image]
    if {$itype ni {rgb rgba hsv}} {
	return -code error "Unable to mix colors for image type $itype"
    }
    return [::crimp::color_mix $image [CHECK $colortransform]]
}

proc ::crimp::color::combine {image wa wb wc} {
    set itype [::crimp::TypeOf $image]
    if {$itype ni {rgb rgba hsv}} {
	return -code error "Unable to recombine colors for image type $itype"
    }

    return [::crimp::color_combine $image \
		[::crimp::read::tcl float [list [list $wa $wb $wc]]]
}

proc ::crimp::color::rgb2xyz {} {
    return [MAKE [XYZ]]
}

namespace eval ::crimp::color::xyz2lms {
    namespace export {[0-9a-z]*}
    namespace ensemble create
}

proc ::crimp::color::xyz2lms::cmccat97 {} {
    return [::crimp::color::MAKE [::crimp::color::LMS::CMCCAT97]]
}

proc ::crimp::color::xyz2lms::rlab {} {
    return [::crimp::color::MAKE [::crimp::color::LMS::RLAB]]
}

proc ::crimp::color::xyz2lms::ciecam97 {} {
    return [::crimp::color::MAKE [::crimp::color::LMS::CIECAM97]]
}

proc ::crimp::color::xyz2lms::ciecam02 {} {
    return [::crimp::color::MAKE [::crimp::color::LMS::CIECAM02]]
}

namespace eval ::crimp::color::rgb2lms {
    namespace export {[0-9a-z]*}
    namespace ensemble create
}

proc ::crimp::color::rgb2lms::cmccat97 {} {
    return [::crimp::color::MAKE \
		[::crimp::matmul3x3_float \
		     [::crimp::color::LMS::CMCCAT97] \
		     [::crimp::color::XYZ]]]
}

proc ::crimp::color::rgb2lms::rlab {} {
    return [::crimp::color::MAKE \
		[::crimp::matmul3x3_float \
		     [::crimp::color::LMS::RLAB] \
		     [::crimp::color::XYZ]]]
}

proc ::crimp::color::rgb2lms::ciecam97 {} {
    return [::crimp::color::MAKE \
		[::crimp::matmul3x3_float \
		     [::crimp::color::LMS::CIECAM97] \
		     [::crimp::color::XYZ]]]
}

proc ::crimp::color::rgb2lms::ciecam02 {} {
    return [::crimp::color::MAKE \
		[::crimp::matmul3x3_float \
		     [::crimp::color::LMS::CIECAM02] \
		     [::crimp::color::XYZ]]]
}

proc ::crimp::color::chain {t args} {
    if {[llength $args] == 0} {
	return $t
    }
    set args [linsert $args 0 $t]
    while {[llength $args] > 1} {
	set args [lreplace $args end-1 end \
		      [MAKE [::crimp::matmul3x3_float \
				 [CHECK [lindex $args end-1]] \
				 [CHECK [lindex $args end]]]]]
    }
    return [lindex $args 0]
}

proc ::crimp::color::make {a b c d e f g h i} {
    # Create the matrix for a color transform (3x3 float) from
    # the nine parameters.
    return [MAKE [::crimp::read::tcl float \
		[list \
		     [list $a $b $c] \
		     [list $d $e $f] \
		     [list $g $h $i]]]]
}

proc ::crimp::color::MAKE {m} {
    variable typecode
    return [list $typecode $m]
}

proc ::crimp::color::CHECK {transform {prefix {}}} {
    variable typecode
    if {
	[catch {llength $transform} len] ||
	($len != 2) ||
	([lindex $transform 0] ne $typecode) ||
	[catch {::crimp::TypeOf [set m [lindex $transform 1]]} t] ||
	($t ne "float") ||
	([::crimp::dimensions $m] ne {3 3})
    } {
	return -code error "${prefix}expected color transform, this is not it."
    }
    return $m
}

proc ::crimp::color::XYZ {} {
    # RGB to XYZ. Core matrix.
    # http://en.wikipedia.org/wiki/CIE_1931_color_space
    # http://en.wikipedia.org/wiki/CIE_1960_color_space
    # http://en.wikipedia.org/wiki/XYZ_color_space

    #    1    | 0.49    0.31    0.20	|   | 2.76883 1.75171 1.13014 |
    # ------- |	0.17697 0.81240 0.01063	| = | 1       4.59061 0.06007 |
    # 0.17697 |	0       0.01    0.99    |   | 0       0.05651 5.59417 |

    return [::crimp::read::tcl float {
	{2.76883087528959710685 1.75170932926484714923 1.13013505113861106402}
	{1                      4.59060857772503814205 0.06006667796801717805}
	{0                      0.05650675255693055320 5.59416850313612476690}
    }]
}

namespace eval ::crimp::color::LMS {}
# http://en.wikipedia.org/wiki/LMS_color_space

proc ::crimp::color::LMS::CMCCAT97 {} {
    # Core matrix XYZ to LMS per CMCCAT97.

    return [::crimp::read::tcl float {
	{ 0.8951  0.2664 -0.1614}
	{-0.7502  1.7135  0.0367}
	{ 0.0389 -0.0685  1.0296}
    }]
}

proc ::crimp::color::LMS::RLAB {} {
    # Core matrix XYZ to LMS per RLAB (D65).

    return [::crimp::read::tcl float {
	{ 0.4002 0.7076 -0.0808}
	{-0.2263 1.1653  0.0457}
	{ 0      0       0.9182}
    }]
}

proc ::crimp::color::LMS::CIECAM97 {} {
    # Core matrix XYZ to LMS per CIECAM97.

    return [::crimp::read::tcl float {
	{ 0.8562  0.3372 -0.1934}
	{-0.8360  1.8327  0.0033}
	{ 0.0357 -0.0469  1.0112}
    }]
}

proc ::crimp::color::LMS::CIECAM02 {} {
    # Core matrix XYZ to LMS per CIECAM02.

    return [::crimp::read::tcl float {
	{ 0.7328 0.4296 -0.1624}
	{-0.7036 1.6975  0.0061}
	{ 0.0030 0.0136  0.9834}
    }]
}

# # ## ### ##### ######## #############

proc ::crimp::integrate {image} {
    set type [TypeOf $image]
    set f integrate_$type
    if {![Has $f]} {
	return -code error "Unable to integrate images of type \"$type\""
    }

    return [$f $image]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::downsample {
    namespace export *
    namespace ensemble create
}

proc ::crimp::downsample::xy {image factor} {
    set type [::crimp::TypeOf $image]
    set f downsample_$type
    if {![::crimp::Has $f]} {
	return -code error "Unable to downsample images of type \"$type\""
    }

    return [::crimp::$f $image $factor]
}

proc ::crimp::downsample::x {image factor} {
    set type [::crimp::TypeOf $image]
    set f downsamplex_$type
    if {![::crimp::Has $f]} {
	return -code error "Unable to downsample (x) images of type \"$type\""
    }

    return [::crimp::$f $image $factor]
}

proc ::crimp::downsample::y {image factor} {
    set type [::crimp::TypeOf $image]
    set f downsampley_$type
    if {![::crimp::Has $f]} {
	return -code error "Unable to downsample (y) images of type \"$type\""
    }

    return [::crimp::$f $image $factor]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::upsample {
    namespace export *
    namespace ensemble create
}

proc ::crimp::upsample::xy {image factor} {
    set type [::crimp::TypeOf $image]
    set f upsample_$type
    if {![::crimp::Has $f]} {
	return -code error "Unable to upsample images of type \"$type\""
    }

    return [::crimp::$f $image $factor]
}

proc ::crimp::upsample::x {image factor} {
    set type [::crimp::TypeOf $image]
    set f upsamplex_$type
    if {![::crimp::Has $f]} {
	return -code error "Unable to upsample (x) images of type \"$type\""
    }

    return [::crimp::$f $image $factor]
}

proc ::crimp::upsample::y {image factor} {
    set type [::crimp::TypeOf $image]
    set f upsampley_$type
    if {![::crimp::Has $f]} {
	return -code error "Unable to upsample (y) images of type \"$type\""
    }

    return [::crimp::$f $image $factor]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::decimate {
    namespace export *
    namespace ensemble create
}

# Combines downsampling with a pre-processing step applying a
# low-pass filter to avoid aliasing of higher image frequencies.

# We assume that the low-pass filter is separable, and the kernel is
# the 1-D horizontal form of it. We compute the vertical form on our
# own, transposing the kernel (if needed).

# NOTE: This implementation, while easy conceptually, is not very
# efficient, because it does the filtering on the input image, before
# downsampling.

# FUTURE: Write a C level primitive integrating the filter and
# sampler, computing the filter only for the pixels which go into the
# result.

proc ::crimp::decimate::xy {image factor kernel} {
    return [::crimp::downsample::xy \
		[::crimp::filter::convolve $image \
		     $kernel [::crimp::kernel::transpose $kernel]] \
		$factor]
}

proc ::crimp::decimate::x {image factor kernel} {
    return [::crimp::downsample::x \
		[::crimp::filter::convolve $image \
		     $kernel] \
		$factor]
}

proc ::crimp::decimate::y {image factor kernel} {
    return [::crimp::downsample::y \
		[::crimp::filter::convolve $image \
		     [::crimp::kernel::transpose $kernel]] \
		$factor]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::interpolate {
    namespace export *
    namespace ensemble create
}

# Combines upsampling with a post-processing step applying a low-pass
# filter to remove copies of the image at higher image frequencies.

# We assume that the low-pass filter is separable, and the kernel is
# the 1-D horizontal form of it. We compute the vertical form on our
# own, transposing the kernel (if needed).

# NOTE: This implementation, while easy conceptually, is not very
# efficient, because it does the filtering on the full output image,
# after upsampling.

# FUTURE: Write a C level primitive integrating the filter and
# sampler, computing the filter only for the actually new pixels, and
# use polyphase restructuring.

# DANGER: This assumes that the filter, applied to the original pixels
# leaves them untouched. I.e. scaled center weight is 1.  The easy
# implementation here does not have this assumption.

proc ::crimp::interpolate::xy {image factor kernel} {
    return [::crimp::filter::convolve \
		[::crimp::upsample::xy $image $factor] \
		$kernel [::crimp::kernel::transpose $kernel]]
}

proc ::crimp::interpolate::x {image factor kernel} {
    return [::crimp::filter::convolve \
		[::crimp::upsample::x $image $factor] \
		$kernel]
}

proc ::crimp::interpolate::y {image factor kernel} {
    return [::crimp::filter::convolve \
		[::crimp::upsample::y $image $factor] \
		[::crimp::kernel::transpose $kernel]]
}

# # ## ### ##### ######## #############

proc ::crimp::split {image} {
    set type [TypeOf $image]
    if {![Has split_$type]} {
	return -code error "Unable to split images of type \"$type\""
    }
    return [split_$type $image]
}

# # ## ### ##### ######## #############

proc ::crimp::blank {type w h args} {
    if {![Has blank_$type]} {
	return -code error "Unable to create blank images of type \"$type\""
    }
    if {$w < 0} {
	return -code error "Illegal width, expected positive integer, got \"$w\""
    }
    if {$h < 0} {
	return -code error "Illegal height, expected positive integer, got \"$h\""
    }

    # Extend the set of channel values if not enough were specified,
    # by setting to them to BLACK or TRANSPARENT, respectively.

    switch -- $type {
	hsv - rgb {
	    if {[llength $args]} {
		while {[llength $args] < 3} {
		    lappend args 0
		}
	    }
	}
	fpcomplex {
	    if {[llength $args]} {
		while {[llength $args] < 2} {
		    lappend args 0
		}
	    }
	}
	rgba {
	    # black and transparent have the same raw value, 0. This
	    # obviates the need to handle the alpha channel
	    # separately.
	    if {[llength $args]} {
		while {[llength $args] < 4} {
		    lappend args 0
		}
	    }
	}
    }

    return [blank_$type $w $h {*}$args]
}

# # ## ### ##### ######## #############

proc ::crimp::expand {bordertype image ww hn we hs args} {
    # args = ?type-specific arguments?
    # currently only for bordertype 'const'. Default to (0 0 0 255).

    set type [TypeOf $image]

    lassign [BORDER $type [list $bordertype {*}$args]] f values

    return [$f $image $ww $hn $we $hs {*}$values]
}

# # ## ### ##### ######## #############

proc ::crimp::crop {image ww hn we hs} {
    set type [TypeOf $image]
    set f    crop_$type
    if {![::crimp::Has $f]} {
	return -code error "Cropping is not supported for images of type \"$type\""
    }
    return [::crimp::$f $image $ww $hn $we $hs]
}

proc ::crimp::cut {image dx dy w h} {
    set type [TypeOf $image]
    set f    cut_$type
    if {![::crimp::Has $f]} {
	return -code error "Cutting is not supported for images of type \"$type\""
    }
    if {$w < 0} {
	return -code error "Illegal width, expected positive integer, got \"$w\""
    }
    if {$h < 0} {
	return -code error "Illegal height, expected positive integer, got \"$h\""
    }

    lassign [::crimp::at $image] ox oy
    incr ox $dx
    incr oy $dy
    return [::crimp::$f $image $ox $oy $w $h]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::alpha {
    namespace export *
    namespace ensemble create
}

# # ## ### ##### ######## #############
# NOTE: The use of the builtin 'set' command in the alpha namespace
# requires '::set'.

proc ::crimp::alpha::set {image mask} {
    ::set itype [::crimp::TypeOf $image]
    ::set mtype [::crimp::TypeOf $mask]
    ::set f     setalpha_${itype}_$mtype
    if {![::crimp::Has $f]} {
	return -code error "Setting the alpha channel is not supported for images of type \"$itype\" and mask of type \"$mtype\""
    }
    return [::crimp::$f $image $mask]
}

# # ## ### ##### ######## #############

proc ::crimp::alpha::opaque {image} {
    ::set itype [::crimp::TypeOf $image]
    if {$itype ne "rgba"} { return $image }
    # alpha::set
    return [set $image \
		[::crimp::blank grey8 \
		     {*}[::crimp::dimensions $image] 255]]
}

# # ## ### ##### ######## #############

proc ::crimp::alpha::blend {fore back alpha} {
    ::set ftype [::crimp::TypeOf $fore]
    ::set btype [::crimp::TypeOf $back]
    ::set f     alpha_blend_${ftype}_$btype
    if {![::crimp::Has $f]} {
	return -code error "Blend is not supported for a foreground of type \"$ftype\" and a background of type \"$btype\""
    }
    return [::crimp::$f $fore $back [::crimp::table::CLAMP $alpha]]
}

# # ## ### ##### ######## #############

proc ::crimp::alpha::over {fore back} {
    ::set ftype [::crimp::TypeOf $fore]
    ::set btype [::crimp::TypeOf $back]
    ::set f     alpha_over_${ftype}_$btype
    if {![::crimp::Has $f]} {
	return -code error "Over is not supported for a foreground of type \"$ftype\" and a background of type \"$btype\""
    }
    return [::crimp::$f $fore $back]
}

# # ## ### ##### ######## #############

proc ::crimp::scale {a scale} {
    set type [TypeOf $a]
    set f     scale_${type}
    if {![Has $f]} {
	return -code error "Scale is not supported by \"$atype\""
    }
    return [$f $a $scale]
}

# # ## ### ##### ######## #############

proc ::crimp::add {a b {scale 1} {offset 0}} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]

    set f add_${atype}_$btype
    if {[Has $f]} {
	return [$f $a $b $scale $offset]
    }

    if {$atype ne $btype} {
	set f add_${btype}_$atype
	if {[Has $f]} {
	    return [$f $b $a $scale $offset]
	}
    }

    return -code error "Add is not supported for the combination of \"$atype\" and \"$btype\""
}

# # ## ### ##### ######## #############

proc ::crimp::subtract {a b {scale 1} {offset 0}} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]
    set f     subtract_${atype}_$btype
    if {![Has $f]} {
	return -code error "Subtract is not supported for the combination of \"$atype\" and \"$btype\""
    }
    return [$f $a $b $scale $offset]
}

# # ## ### ##### ######## #############

proc ::crimp::difference {a b} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]

    set f difference_${atype}_$btype
    if {[Has $f]} {
	return [$f $a $b]
    }

    if {$atype ne $btype} {
	set f difference_${btype}_$atype
	if {[Has $f]} {
	    return [$f $b $a]
	}
    }

    return -code error "Difference is not supported for the combination of \"$atype\" and \"$btype\""
}

# # ## ### ##### ######## #############

proc ::crimp::square {a} {
    return [multiply $a $a]
}

proc ::crimp::multiply {a b} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]

    set f multiply_${atype}_$btype
    if {[Has $f]} {
	return [$f $a $b]
    }

    if {$atype ne $btype} {
	set f multiply_${btype}_$atype
	if {[Has $f]} {
	    return [$f $b $a]
	}
    }

    return -code error "Multiply is not supported for the combination of \"$atype\" and \"$btype\""
}

# # ## ### ##### ######## #############

proc ::crimp::hypot {a b} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]

    set f hypot_${atype}_$btype
    if {[Has $f]} {
	return [$f $a $b]
    }

    if {$atype ne $btype} {
	set f hypot_${btype}_$atype
	if {[Has $f]} {
	    return [$f $b $a]
	}
    }

    return -code error "Hypot is not supported for the combination of \"$atype\" and \"$btype\""
}

# # ## ### ##### ######## #############

proc ::crimp::divide {a b {scale 1} {offset 0}} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]
    set f     div_${atype}_$btype
    if {![Has $f]} {
	return -code error "Division is not supported for the combination of \"$atype\" and \"$btype\""
    }
    if {$atype eq "fpcomplex" } {
	return [$f $a $b]
    } else {
	return [$f $a $b $scale $offset]
    }
}

# # ## ### ##### ######## #############

proc ::crimp::atan2 {a b} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]
    set f     atan2_${atype}_$btype
    if {![Has $f]} {
	return -code error "atan2 is not supported for the combination of \"$atype\" and \"$btype\""
    }
    return [$f $a $b]
}

# # ## ### ##### ######## #############
## min aka 'darker' as the less brighter of each pixel is chosen.

proc ::crimp::min {a b} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]

    set f min_${atype}_$btype
    if {[Has $f]} {
	return [$f $a $b]
    }

    if {$atype ne $btype} {
	set f min_${btype}_$atype
	if {[Has $f]} {
	    return [$f $b $a]
	}
    }

    return -code error "Min is not supported for the combination of \"$atype\" and \"$btype\""
}

# # ## ### ##### ######## #############
## max aka 'lighter' as the brighter of each pixel is chosen.

proc ::crimp::max {a b} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]

    set f max_${atype}_$btype
    if {[Has $f]} {
	return [$f $a $b]
    }

    if {$atype ne $btype} {
	set f max_${btype}_$atype
	if {[Has $f]} {
	    return [$f $b $a]
	}
    }

    return -code error "Max is not supported for the combination of \"$atype\" and \"$btype\""
}

# # ## ### ##### ######## #############
## This operation could be done at this level, using a combination of
## 'multiply' and 'invert'. Doing it in C on the other hand avoids the
## three temporary images of such an implementation.

proc ::crimp::screen {a b} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]

    set f screen_${atype}_$btype
    if {[Has $f]} {
	return [$f $a $b]
    }

    if {$atype ne $btype} {
	set f screen_${btype}_$atype
	if {[Has $f]} {
	    return [$f $b $a]
	}
    }

    return -code error "Screen is not supported for the combination of \"$atype\" and \"$btype\""
}

# # ## ### ##### ######## #############

namespace eval ::crimp::filter {
    namespace export {[a-z]*}
    namespace ensemble create
}

# # ## ### ##### ######## #############

proc ::crimp::filter::convolve {image args} {
    # args = ?-border spec? kernel...

    set type [::crimp::TypeOf $image]
    set fc convolve_*_${type}
    if {![llength [::crimp::List $fc]]} {
	return -code error "Convolution is not supported for image type \"$type\""
    }

    # Default settings for border expansion.
    lassign [::crimp::BORDER $type const] fe values

    set at 0
    while {1} {
	set opt [lindex $args $at]
	if {![string match -* $opt]} break
	incr at
	switch -- $opt {
	    -border {
		set value [lindex $args $at]
		lassign [::crimp::BORDER $type $value] fe values
		incr at
	    }
	    default {
		return -code error "Unknown option \"$opt\", expected -border"
	    }
	}
    }
    set args [lrange $args $at end]
    if {![llength $args]} {
	return -code error "wrong#args: expected image ?-border spec? kernel..."
    }

    # kernel = list (kw kh kernel-image scale)
    # Kernel x in [-kw ... kw], 2*kw+1 values
    # Kernel y in [-kh ... kh], 2*kh+1 values
    # Shrinkage by 2*kw, 2*kh. Compensate using the chosen border type.

    foreach kernel $args {
	lassign $kernel kw kh K scale offset

	set ktype [::crimp::TypeOf $K]
	set fc convolve_${ktype}_${type}
	if {![::crimp::Has $fc]} {
	    return -code error "Convolution kernel type \"$ktype\" is not supported for image type \"$type\""
	}

	set image [::crimp::$fc \
		       [::crimp::$fe $image $kw $kh $kw $kh {*}$values] \
		       $K $scale $offset]
    }

    return $image
}

# # ## ### ##### ######## #############

proc ::crimp::filter::ahe {image args} {
    # args = ?-border spec? ?radius?

    set type [::crimp::TypeOf $image]
    set fc ahe_${type}
    if {![::crimp::Has $fc]} {
	return -code error "AHE filtering is not supported for image type \"$type\""
    }

    # Default settings for border expansion.
    lassign [::crimp::BORDER $type const] fe values

    set at 0
    while {1} {
	set opt [lindex $args $at]
	if {![string match -* $opt]} break
	incr at
	switch -- $opt {
	    -border {
		set value [lindex $args $at]
		lassign [::crimp::BORDER $type $value] fe values
		incr at
	    }
	    default {
		return -code error "Unknown option \"$opt\", expected -border"
	    }
	}
    }
    set args [lrange $args $at end]

    switch -- [llength $args] {
	0 { set radius 3                }
	1 { set radius [lindex $args 0] }
	default {
	    return -code error "wrong#args: expected image ?-border spec? ?radius?"
	}
    }

    # Shrinkage by 2*radius. Compensate using the chosen border type.

    return [::crimp::$fc \
		[::crimp::$fe $image $radius $radius $radius $radius {*}$values] \
		$radius]
}

# # ## ### ##### ######## #############

proc ::crimp::filter::mean {image args} {
    # args = ?-border spec? ?radius?

    set type [::crimp::TypeOf $image]

    # Multi-channel images are handled by splitting them and
    # processing each channel separately (invoking the method
    # recursively).
    switch -exact -- $type {
	rgb - rgba - hsv {
	    set r {}
	    foreach c [::crimp::split $image] {
		lappend r [mean $c {*}$args]
	    }
	    return [::crimp::join 2$type {*}$r]
	}
    }

    # Instead of using the histogram-based framework underlying the
    # rank and ahe filters we implement the mean filter via summed
    # area tables (see method integrate), making the computation
    # independent of the filter radius.

    # Our standard border expansion is also not const, but 'mirror',
    # as this is the only setting which will not warp the mean at the
    # image edges.

    # Default settings for border expansion.
    lassign [::crimp::BORDER $type mirror] fe values

    set at 0
    while {1} {
	set opt [lindex $args $at]
	if {![string match -* $opt]} break
	incr at
	switch -- $opt {
	    -border {
		set value [lindex $args $at]
		lassign [::crimp::BORDER $type $value] fe values
		incr at
	    }
	    default {
		return -code error "Unknown option \"$opt\", expected -border"
	    }
	}
    }
    set args [lrange $args $at end]
    switch -- [llength $args] {
	0 { set radius 3                }
	1 { set radius [lindex $args 0] }
	default {
	    return -code error "wrong#args: expected image ?-border spec? ?radius?"
	}
    }

    # Shrinkage is by 2*(radius+1). Compensate using the chosen border type.
    set expand [expr {$radius + 1}]
    set factor [expr {1./((2*$radius+1)**2)}]

    return [::crimp::convert 2$type \
		[::crimp::scale_float \
		     [::crimp::region_sum \
			  [::crimp::integrate \
			       [::crimp::$fe $image $expand $expand $expand $expand {*}$values]] \
			  $radius] $factor]]
}

# # ## ### ##### ######## #############

proc ::crimp::filter::stddev {image args} {
    # args = ?-border spec? ?radius?

    set type [::crimp::TypeOf $image]

    # Multi-channel images are not handled, because the output is a
    # float, which we cannot join.
    if {[llength [::crimp::channels $image]] > 1} {
	    return -code error "Unable to process multi-channel images"
    }

    # Instead of using the histogram-based framework underlying the
    # rank and ahe filters we implement the stddev filter via summed
    # area tables (see method integrate), making the computation
    # independent of the filter radius.

    # Our standard border expansion is also not const, but 'mirror',
    # as this is the only setting which will not warp the mean at the
    # image edges.

    # Default settings for border expansion.
    lassign [::crimp::BORDER $type mirror] fe values

    set at 0
    while {1} {
	set opt [lindex $args $at]
	if {![string match -* $opt]} break
	incr at
	switch -- $opt {
	    -border {
		set value [lindex $args $at]
		lassign [::crimp::BORDER $type $value] fe values
		incr at
	    }
	    default {
		return -code error "Unknown option \"$opt\", expected -border"
	    }
	}
    }
    set args [lrange $args $at end]
    switch -- [llength $args] {
	0 { set radius 3                }
	1 { set radius [lindex $args 0] }
	default {
	    return -code error "wrong#args: expected image ?-border spec? ?radius?"
	}
    }

    # Compute and return stddev.
    return [lindex [MEAN_STDDEV $image $radius $fe $values] 1]
}

proc ::crimp::filter::MEAN_STDDEV {image radius fe values} {
    # Shrinkage is by 2*(radius+1). Compensate using the chosen border type.
    set expand [expr {$radius + 1}]
    set factor [expr {1./((2*$radius+1)**2)}]

    # Compute mean and stddev ...

    set expanded [::crimp::$fe $image $expand $expand $expand $expand {*}$values]
    set mean     [::crimp::scale_float \
		      [::crimp::region_sum \
			   [::crimp::integrate $expanded] \
			   $radius] \
		      $factor]
    set stddev   [::crimp::sqrt_float \
		      [::crimp::subtract \
			   [::crimp::scale_float \
				[::crimp::region_sum \
				     [::crimp::integrate \
					  [::crimp::square \
					       [::crimp::convert::2float $expanded]]] \
				     $radius] \
				$factor] \
			   [::crimp::square $mean]]]

    return [list $mean $stddev]
}

# # ## ### ##### ######## #############

proc ::crimp::filter::rank {image args} {
    # args = ?-border spec? ?radius ?percentile??

    set type [::crimp::TypeOf $image]
    set fc rof_${type}
    if {![::crimp::Has $fc]} {
	return -code error "Rank filtering is not supported for image type \"$type\""
    }

    # Default settings for border expansion.
    lassign [::crimp::BORDER $type const] fe values

    set at 0
    while {1} {
	set opt [lindex $args $at]
	if {![string match -* $opt]} break
	incr at
	switch -- $opt {
	    -border {
		set value [lindex $args $at]
		lassign [::crimp::BORDER $type $value] fe values
		incr at
	    }
	    default {
		return -code error "Unknown option \"$opt\", expected -border"
	    }
	}
    }
    set args [lrange $args $at end]
    switch -- [llength $args] {
	0 { set radius 3                ; set percentile 50 }
	1 { set radius [lindex $args 0] ; set percentile 50 }
	2 { lassign $args radius percentile }
	default {
	    return -code error "wrong#args: expected image ?-border spec? ?radius ?percentile??"
	}
    }

    # percentile is float. convert to integer, and constrain range.

    set percentile [expr {round(100*$percentile)}]
    if {$percentile < 0     } { set percentile     0 }
    if {$percentile > 10000 } { set percentile 10000 }

    # Shrinkage by 2*radius. Compensate using the chosen border type.

    return [::crimp::$fc \
		[::crimp::$fe $image $radius $radius $radius $radius {*}$values] \
		$radius $percentile]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::filter::gauss {
    namespace export discrete sampled
    namespace ensemble create
}

proc ::crimp::filter::gauss::discrete {image sigma {r {}}} {
    set Kx [::crimp::kernel::fpmake [::crimp::table::fgauss::discrete $sigma $r]]
    set Ky [::crimp::kernel::transpose $Kx]
    return [::crimp::filter::convolve $image $Kx $Ky]
}

proc ::crimp::filter::gauss::sampled {image sigma {r {}}} {
    set Kx [::crimp::kernel::fpmake [::crimp::table::fgauss::sampled $sigma $r]]
    set Ky [::crimp::kernel::transpose $Kx]
    return [::crimp::filter::convolve $image $Kx $Ky]
}

# # ## ### ##### ######## #############
# Related reference:
# http://www.holoborodko.com/pavel/image-processing/edge-detection/

namespace eval ::crimp::filter::sobel {
    namespace export x y
    namespace ensemble create

}

proc ::crimp::filter::sobel::x {image} {
    # |-1 0 1|            |1|
    # |-2 0 2| = |-1 0 1|*|2|
    # |-1 0 1|            |1|

    return [::crimp::filter::convolve $image \
		[::crimp::kernel::fpmake {{-1  0 1}} 0] \
		[::crimp::kernel::fpmake {{{1} {2} {1}}} 0]]
}

proc ::crimp::filter::sobel::y {image} {
    # |-1 -2 -1|   |-1|
    # | 0  0  0| = | 0|*|1 2 1|
    # | 1  2  1|   | 1|

    return [::crimp::filter::convolve $image \
		[::crimp::kernel::transpose [::crimp::kernel::fpmake {{-1 0 1}} 0]] \
		[::crimp::kernel::fpmake {{1 2 1}} 0]]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::filter::scharr {
    namespace export x y
    namespace ensemble create

}

proc ::crimp::filter::scharr::x {image} {
    # | -3 0  3|            | 3|
    # |-10 0 10| = |-1 0 1|*|10|
    # | -3 0  3|            | 3|

    return [::crimp::filter::convolve $image \
		[::crimp::kernel::fpmake {{-1  0 1}} 0] \
		[::crimp::kernel::transpose [::crimp::kernel::fpmake {{3 10 3}} 0]]]
}

proc ::crimp::filter::scharr::y {image} {
    # |-3 -10 -3|   |-1|
    # | 0   0  0| = | 0|*|3 10 3|
    # | 3  10  3|   | 1|

    return [::crimp::filter::convolve $image \
		[::crimp::kernel::transpose [::crimp::kernel::fpmake {{-1 0 1}} 0]] \
		[::crimp::kernel::fpmake {{3 10 3}} 0]]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::filter::prewitt {
    namespace export x y
    namespace ensemble create
}

proc ::crimp::filter::prewitt::x {image} {
    # |-1 0 1|            |1|
    # |-1 0 1| = |-1 0 1|*|1|
    # |-1 0 1|            |1|

    return [::crimp::filter::convolve $image \
		[::crimp::kernel::fpmake {{-1  0 1}} 0] \
		[::crimp::kernel::transpose [::crimp::kernel::fpmake {{1 1 1}} 0]]]
}

proc ::crimp::filter::prewitt::y {image} {
    # |-1 -1 -1|   |-1|
    # | 0  0  0| = | 0|*|1 1 1|
    # | 1  1  1|   | 1|

    return [::crimp::filter::convolve $image \
		[::crimp::kernel::transpose [::crimp::kernel::fpmake {{-1 0 1}} 0]] \
		[::crimp::kernel::fpmake {{1 1 1}} 0]]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::filter::roberts {
    namespace export x y
    namespace ensemble create
}

proc ::crimp::filter::roberts::x {image} {
    return [::crimp::filter::convolve $image \
		[::crimp::kernel::fpmake {
		    {0  -1  0}
		    {1   0  0}
		    {0   0  0}
		} 0]]
}

proc ::crimp::filter::roberts::y {image} {
    return [::crimp::filter::convolve $image \
		[::crimp::kernel::fpmake {
		    {-1  0  0}
		    { 0  1  0}
	            { 0  0  0}
		} 0]]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::filter::canny {
    namespace export sobel deriche
    namespace ensemble create

    # References
    #
    # 1. Rafael C. Gonzalez,
    #    Richards E. Woods,
    #    Digital Image Processing (Third Edition) In Image Restoration and Reconstruction,
    #    Pages 719-723 (Point, Line and Edge Detection)
    #
    # 2. http://en.wikipedia.org/wiki/Connected_Component_Labeling
}

proc ::crimp::filter::canny::sobel {image {high 100} {low 50} {sigma 1}   } {

    set imagegrey [::crimp::filter::gauss::discrete \
		       [::crimp::convert::2float \
			    [::crimp::convert::2grey8 $image]] $sigma]

    set Kx [::crimp::kernel::fpmake {
	{1  0 -1}
	{2  0 -2}
	{1  0 -1}} 0]

    set Ky  [::crimp::kernel::transpose $Kx]
    set imagex   [::crimp::filter::convolve $imagegrey $Kx]
    set imagey   [::crimp::filter::convolve $imagegrey $Ky]

    set imagexy  [::crimp::hypot $imagex $imagey]
    set imagetan [::crimp::atan2 $imagey $imagex]
    set imagexy  [::crimp::expand_float_const $imagexy  1 1 1 1 0]
    set imagetan [::crimp::expand_float_const $imagetan 1 1 1 1 0]
    set imagecan [::crimp::cannyinternal $imagexy $imagetan $high $low]
    set imagecan [::crimp::crop_float $imagecan 1 1 1 1]

    return  [::crimp::convert::2grey8 $imagecan]
}

proc ::crimp::filter::canny::deriche {image {high 150} {low 100} {sigma 0.1}} {

    set imagegrey [::crimp::convert::2float \
		       [::crimp::convert::2grey8 $image]]

    set imagexy [::crimp::gaussian_gradient_mag_float $imagegrey $sigma]

    set imagey [::crimp::gaussian_01_float \
		    [::crimp::gaussian_10_float $imagegrey 1 $sigma] 0 $sigma]

    set imagex [::crimp::gaussian_10_float \
		    [::crimp::gaussian_01_float $imagegrey 1 $sigma] 0 $sigma]

    set imagetan  [::crimp::atan2  $imagey   $imagex]

    set imagexy  [::crimp::expand_float_const $imagexy  1 1 1 1 0]
    set imagetan [::crimp::expand_float_const $imagetan 1 1 1 1 0]
    set imagecan [::crimp::cannyinternal $imagexy $imagetan $high $low]
    set imagecan [::crimp::crop_float $imagecan 1 1 1 1]

    return  [::crimp::convert::2grey8 $imagecan]
}

# # ## ### ##### ######## #############

proc ::crimp::filter::wiener {image {radius 2}} {
    # Reference
    #
    # 1. Rafael C. Gonzalez,
    #    Richards E. Woods,
    #    Digital Image Processing (Third Edition) In Image Restoration and Reconstruction,
    #    Pages 352-357, Image Restoration and Reconstruction

    set length  [expr {$radius*2+1 }]
    set itype   [::crimp::TypeOf $image]

    if { $itype in { grey8 grey16 grey32 } } {
	set image   [::crimp::convert 2float $image]

	# Calculation of Local MEAN for later use
	set localmean [::crimp::filter mean $image $radius]

	# Calculation of Local Variance for later use
	set Kmatrix [lrepeat $length [lrepeat $length 1]]
	set kernel  [crimp::kernel::fpmake  $Kmatrix 0]
	set convolvedimage [crimp::filter::convolve \
				[::crimp::square $image] $kernel]
	set divisorimage   [::crimp::blank float \
				{*}[::crimp::dimensions $convolvedimage] \
				[expr $length*$length]]
	set localvar [::crimp::subtract \
			  [::crimp::divide $convolvedimage $divisorimage] \
			  [::crimp::square $localmean]]

	# Setup for noise calculation and a blank BLACK image

	set stat     [::crimp::statistics basic $localvar]
	set noise    [dict get $stat channel value mean]
	set noiseimage     [::crimp::blank float \
				{*}[::crimp::dimensions $convolvedimage] $noise]

	set zeros     [::crimp::blank float \
			   {*}[::crimp::dimensions $image] 0]

	#  Calculate result
	#  Calculation is split up to minimize use of memory
	#  for temp arrays.

	set  f        [::crimp::subtract $image    $localmean]
	set  image    [::crimp::subtract $localvar $noiseimage]
	set  image    [::crimp::max      $image    $zeros]
	set  localvar [::crimp::max      $localvar $noiseimage]
	set  f        [::crimp::divide   $f        $localvar]
	set  f        [::crimp::multiply $f        $image]
	set  f        [::crimp::add      $f        $localmean]

	return [crimp::convert::2$itype $f]

    } elseif { $itype in { rgb rgba } } {
	set CHAN [::crimp::split $image]
	set filtered {}
	foreach chan [lrange $CHAN 0 2] {
	    # Recursive handling of each channel, except alpha.
	    lappend filtered [::crimp::filter::wiener $chan $radius]
	}
	if {$itype eq "rgba"} {
	    lappend filtered [lindex $CHAN 3]

	}
	return [::crimp::join_2$itype {*}$filtered]
    } else {
	return -code error "Wiener filtering is not supported for image type \"$itype\" must be grey8, grey16, grey32, rgb, rgba "
    }
}

# # ## ### ##### ######## #############

namespace eval ::crimp::gradient {
    namespace export {[a-z]*}
    namespace ensemble create
}

# TODO gradient via laplace directly, or as difference of gaussians.

proc ::crimp::gradient::sobel {image} {
    return [list \
		[::crimp::filter::sobel::x $image] \
		[::crimp::filter::sobel::y $image]]
}

proc ::crimp::gradient::scharr {image} {
    return [list \
		[::crimp::filter::scharr::x $image] \
		[::crimp::filter::scharr::y $image]]
}

proc ::crimp::gradient::prewitt {image} {
    return [list \
		[::crimp::filter::prewitt::x $image] \
		[::crimp::filter::prewitt::y $image]]
}

proc ::crimp::gradient::roberts {image} {
    return [list \
		[::crimp::filter::roberts::x $image] \
		[::crimp::filter::roberts::y $image]]
}

proc ::crimp::gradient::polar {cgradient} {
    # cgradient = list (Gx Gy), c for cartesian
    # result = polar = list (magnitude angle) (hypot, atan2 (gy, gx))
    lassign $cgradient x y
    return [list \
		[::crimp::hypot $y $x] \
		[::crimp::atan2 $y $x]]
}

proc ::crimp::gradient::visual {pgradient} {
    # pgradient = list (magnitude angle), p for polar
    # result = HSV encoding magnitude as value, and angle as hue.
    # saturation is full.
    lassign $pgradient m a
    set h [::crimp::FITFLOATRANGE $a 0 360]
    set s [::crimp::blank grey8 {*}[crimp dimensions $m] 255]
    set v [::crimp::FITFLOAT $m]
    return [::crimp::convert::2rgb [::crimp::join::2hsv $h $s $v]]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::noise {
    namespace export {[a-z]*}
    namespace ensemble create
}

proc ::crimp::noise::random {w h} {
    return [::crimp::random_uniform $w $h]
}

proc ::crimp::noise::saltpepper {image {threshold 0.05}} {
    #  Also known as IMPULSE Noise
    #
    #  The parameter threshold ranges between 0 - 1.
    #
    #  The method modifies about
    #    THRESHOLD * WIDTH * HEIGHT
    # pixels of the input image.

    # Reference
    #
    # 1. Rafael C. Gonzalez,
    #    Richards E. Woods,
    #    Digital Image Processing (Third Edition) In Image Restoration and Reconstruction,
    #    Pages 316-317

    if {($threshold < 0) ||
	($threshold > 1) } {
	return -code error "Invalid salt/pepper threshold outside of \[0..\1]."
    }

    set itype [::crimp::TypeOf $image]

    set f noise_salt_pepper_$itype
    if {[::crimp::Has $f]} {
	return [::crimp::$f $image $threshold]
    } else {
	return -code error "Salt/pepper noise is not supported for image type \"$itype\" "
    }
}

proc ::crimp::noise::gaussian {image {mean 0} {variance 0.05}} {
    # Adds gaussian noise of the specified MEAN and VARIANCE

    # Reference
    #
    # 1. Rafael C. Gonzalez,
    #    Richards E. Woods,
    #    Digital Image Processing (Third Edition) In Image Restoration and Reconstruction,
    #    Pages 314-315

    set itype [::crimp::TypeOf $image]

    if {$itype in {grey8 grey16 grey32}} {
	return [::crimp::noise_gaussian_$itype $image $mean $variance]

    } elseif {$itype in {rgb rgba}} {
	# TODO: Could maybe moved to C as well.
	set CHAN [::crimp::split $image]
	set filtered {}
	foreach chan [lrange $CHAN 0 2] {
	    lappend filtered [::crimp::noise_gaussian_grey8 $chan $mean $variance]
	}
	if { $itype eq "rgba"} {
	    lappend filtered [lindex $CHAN 3]
	}
	return [::crimp::join_2$itype {*}$filtered]

    } else {
	return -code error "Gaussian noise is not supported for image type \"$itype\", must be grey8, grey16, grey32, rgb OR rgba "
    }
}

proc ::crimp::noise::speckle {image {variance 0.05}} {
    # Also known as MULTIPLICATIVE noise

    # It is in direct proportion to the grey level PIXEL VALUE in any
    # area. Adds RANDOM Noise of ZERO mean and the specified VARIANCE.

    # Reference
    #
    # 1. Rafael C. Gonzalez,
    #    Richards E. Woods,
    #    Digital Image Processing (Third Edition)
    #    Pages 315-316,  In Image Restoration and Reconstruction

    set itype [::crimp::TypeOf $image]

    if {$itype in {grey8 grey16 grey32}} {
	return [::crimp::convert::2$itype \
		    [::crimp::FITFLOAT  \
			 [::crimp::noise_speckle_$itype \
			      $image $variance]]]

    } elseif {$itype in {rgb rgba}} {
	set CHAN [::crimp::split $image]
	set filtered {}
	foreach chan [lrange $CHAN 0 2] {
	    lappend filtered  [::crimp::convert::2grey8 \
				   [::crimp::FITFLOAT  \
					[::crimp::noise_speckle_grey8 \
					     $chan $variance]]]
	}
	if { $itype eq "rgba"} {
	    lappend filtered [lindex $CHAN 3]
	}
	return [::crimp::join_2$itype {*}$filtered]
    } else {
	return -code error "Speckle noise is not supported for image type \"$itype\" must be grey8, grey16, grey32, rgb OR rgba"
    }
}

# # ## ### ##### ######## #############

namespace eval ::crimp::complex {
    namespace export {[a-z]*}
    namespace ensemble create
}

proc ::crimp::complex::magnitude {image} {
    set itype [::crimp::TypeOf $image]
    if { $itype ne "fpcomplex" } {
	return -code error "Magnitude of Complex Image is not supported for image type \"$itype\" must be fpcomplex "
    } else {
	return [crimp::magnitude_fpcomplex $image]
    }
}

proc ::crimp::complex::2complex {image} {
    return [::crimp::convert::2complex $image]
}

proc ::crimp::complex::real {image} {
    set itype [::crimp::TypeOf $image]
    if {$itype ne "fpcomplex"} {
	return -code error "Extraction of the real part is not supported for type \"$itype\", only \"fpcomplex\""
    }
    return [::crimp::convert_2float_fpcomplex $image]
}

proc ::crimp::complex::imaginary {image} {
    set itype [::crimp::TypeOf $image]
    if {$itype ne "fpcomplex"} {
	return -code error "Extraction of the imaginary part is not supported for type \"$itype\", only \"fpcomplex\""
    }
    return [crimp::imaginary_fpcomplex $image]
}

proc ::crimp::complex::conjugate {image} {
    set itype [::crimp::TypeOf $image]
    if { $itype ne "fpcomplex" } {
	return -code error "Conjugate can only be find for fpcomplex images "
    } else {
	return [crimp::conjugate_fpcomplex $image]
    }
}

# # ## ### ##### ######## #############

proc ::crimp::window { image }  {
    set itype [::crimp::TypeOf $image]

    if {[::crimp::Has window_$itype]} {
	return [::crimp::window_$itype  $image]
    } else {
	return -code error "Window function is not supported for image type \"$itype\" "
    }
}

# # ## ### ##### ######## #############

proc ::crimp::matchgeo {image bbox} {
    # Modify the image to match the bounding box. This works only if
    # the image is fully contained in that box. We check this by
    # testing that the union of image and box is the box itself.

    lassign $bbox                           x y w h
    lassign [bbox2 [geometry $image] $bbox] a b c d

    if {($x != $a) || ($y != $b) || ($w != c) || ($h != d)} {
	return -code error "The is image not fully contained in the bounding box to match to."
    }

    lassign [geometry $image] ix iy iw ih

    # Due to the 'contained' check above we can be sure of the
    # following contraints of image geometry to bounding box.

    # (1) ix      >= x
    # (2) iy      >= y
    # (3) (ix+iw) <= (x+w)
    # (4) (iy+ih) <= (y+h)

    # This then provides us easily with the sizes of the various areas
    # by which to extend the image to match that bounding box.

    set w [expr {$ix - $x}]
    set e [expr {$x+$w-$ix-$iw}]
    set n [expr {$iy - $y}]
    set s [expr {$y+$h-$iy-$ih}]

    return [expand const $image $w $n $e $s 0]
}

proc ::crimp::matchsize {image1 image2} {

    lassign [dimensions $image1] w1 h1
    lassign [dimensions $image2] w2 h2

    if { $w1 > $w2 } {
	set dw [expr {($w1 - $w2) / 2}]
	set image2 [::crimp expand const $image2 $dw 0 $dw 0 0]
    } elseif { $w1 < $w2 } {
	set dw [expr {($w2 - $w1) / 2}]
	set image1 [::crimp expand const $image1 $dw 0 $dw 0 0]
    }

    if { $h1 > $h2 } {
	set dh [expr {($h1 - $h2) / 2}]
	set image2 [::crimp expand const $image2 0 $dh 0 $dh 0]
    } elseif { $h1 < $h2 } {
	set dh [expr {($h2 - $h1) / 2}]
	set image1 [::crimp expand const $image1 0 $dh 0 $dh 0]
    }

    # 2nd half, handles the case dw/dh odd above, by extending only
    # one side, by the last pixel.

    lassign [dimensions $image1] w1 h1
    lassign [dimensions $image2] w2 h2

    if { $w1 > $w2 } {
	set image2 [::crimp expand const $image2 0 0 1 0 0]
    } elseif { $w1 < $w2 } {
	set image1 [::crimp expand const $image1 0 0 1 0 0]
    }

    if { $h1 > $h2 } {
	set image2 [::crimp expand const $image2 0 0 0 1 0]
    } elseif { $h1 < $h2 } {
	set image1 [::crimp expand const $image1 0 0 0 1 0]
    }

    return [list $image1 $image2]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::register {
    namespace export {[a-z]*}
    namespace ensemble create
}

proc ::crimp::register::translation {needle haystack} {
    set needle   [::crimp::convert::2grey8 $needle]
    set haystack [::crimp::convert::2grey8 $haystack]

    # ZERO pading to make both images of the same size

    lassign [::crimp::matchsize $needle $haystack] needle haystack

    # Window both images, to reduce likelyhood of false matches
    # between linear features of one image and borders of the other.

    set needle   [crimp::window $needle]
    set haystack [crimp::window $haystack]

    lassign [TranslationCore $needle $haystack] dx dy

    # The raw translation values are _unsigned_ in the range 0 to
    # image width/height. Convert to signed.

    lassign [::crimp::dimensions $needle] w h
    if {$dx > $w/2} { set dx [expr {$dx - $w}] }
    if {$dy > $h/2} { set dy [expr {$dy - $h}] }

    return [dict create \
		Xshift $dx \
		Yshift $dy]
}

# # ## ### ##### ######## #############

proc ::crimp::register::TranslationCore {needle haystack} {
    # Assumptions: needle and haystack have the same size, are of type
    # grey8, and windowed.

    #lassign [::crimp::dimensions $needle] w h

    # Perform a phase correlation on the FFTs of the inputs.
    set fftn [::crimp::fft::forward [::crimp::convert::2complex $needle]]
    set ffth [::crimp::fft::forward [::crimp::convert::2complex $haystack]]

    set correlation [::crimp::divide \
			 [::crimp::multiply \
			      $ffth [::crimp::complex::conjugate $fftn]] \
			 [::crimp::multiply \
			      [::crimp::convert::2complex \
				   [crimp::complex::magnitude $fftn]] \
			      [::crimp::convert::2complex \
				   [crimp::complex::magnitude $ffth]]]]

    # And back to the pixel domain. Our input were 'real'-only complex
    # images, so the output is the same, modulo round-off. Just
    # stripping off the imaginary part is enough, after the inverse
    # FFT was run.

    set immag [::crimp::convert_2float_fpcomplex \
		   [::crimp::fft::backward $correlation]]

    # At last, find the coorrdinates of the brightest pixel, i.e. of
    # the correlation peak.

    set stat [::crimp::statistics basic $immag]

    #log "S max  = [format %.11f [dict get $stat channel value max]] @ [dict get $stat channel value max@]"
    #log "S min  = [format %.11f [dict get $stat channel value min]] @ [dict get $stat channel value min@]"

    lassign [dict get $stat channel value max@] dx dy

    # The raw translation values are _unsigned_ in the range 0 to
    # image width/height. Convert to signed.

    #if {$dx > $w/2} { set dx [expr {$dx - $w}] }
    #if {$dy > $h/2} { set dy [expr {$dy - $h}] }

    # Our result are translation offsets from the needle into the
    # haystack.

    return [list $dx $dy]
}

# # ## ### ##### ######## #############
## Commands for the creation and manipulation of transformation
## matrices. We are using 3x3 matrices to allow the full range of
## projective transforms, i.e. perspective.

namespace eval ::crimp::transform {
    namespace export {[a-z]*}
    namespace ensemble create
    namespace import ::tcl::mathfunc::*
    namespace import ::tcl::mathop::*

    variable typecode crimp/transform
}

proc ::crimp::transform::projective {a b c d e f g h} {
    #                   | a b c |
    # Create the matrix | d e f | for a projective transform.
    #		        | g h 1 |

    return [MAKE [::crimp::read::tcl float \
		[list \
		     [list $a $b $c] \
		     [list $d $e $f] \
		     [list $g $h 1]]]]
}

proc ::crimp::transform::affine {a b c d e f} {
    # An affine transform is a special case of the projective, without
    # perspective warping. Its matrix is | a b c |
    #                                    | d e f |
    return [projective $a $b $c $d $e $f 0 0]
}

proc ::crimp::transform::translate {dx dy} {
    # Translate in the x, y directions
    return [affine 1 0 $dx 0 1 $dy]
}

proc ::crimp::transform::scale {sx sy} {
    # Scale in the x, y directions
    return [affine $sx 0 0 0 $sy 0]
}

proc ::crimp::transform::shear {sx sy} {
    # Shear in the x, y directions
    return [affine 1 $sx $sy 1 0 0]
}

namespace eval ::crimp::transform::reflect {
    namespace export line x y
    namespace ensemble create
    # TODO line segment (arbitrary line).
}

proc ::crimp::transform::reflect::line {lx ly} {
    # Reflect along the line (lx, ly) through the origin.
    # This can be handled as a chain of
    # (a) rotation through the origin to map the line to either x- or y-axis
    # (b) reflection along the chosen axis,
    # (c) and rotation back to the chosen line.
    # Here we use the direct approach.
    # See http://en.wikipedia.org/wiki/Transformation_matrix

    # Note: A reflection through an arbitrary line (i.e. not through
    # the origin), needs two additional steps. After the first
    # rotation the line is parallel to an axis, and has to be
    # translated on it. Ditto we have to undo the translation before
    # rotating back. As the rotation is through an arbitray point it
    # also needs translations, which can be combined, by proper choice
    # of the rotation point.

    set a [expr {$lx*$lx-$ly*$ly}]
    set b [expr {2*$lx*$ly}]
    set c [expr {$ly*$ly-$lx*$lx}]
    return [affine $a $b 0 $b $c 0]
}

proc ::crimp::transform::reflect::x {} {
    # Reflect along the x-axis.
    return [affine -1 0 0 1 0 0]
}

proc ::crimp::transform::reflect::y {} {
    # Reflect along the y-axis
    return [affine 1 0 0 -1 0 0]
}

proc ::crimp::transform::rotate {theta {p {0 0}}} {
    # Rotate around around a point, by default (0,0), i.e. the upper
    # left corner. Rotation around any other point is done by
    # translation that point to (0,0), rotating, and then translating
    # everything back.

    # convert angle from degree to radians.
    set s  [sin [* $theta 0.017453292519943295769236907684886]]
    set c  [cos [* $theta 0.017453292519943295769236907684886]]
    set sn [- $s]

    set r [affine $c $s 0 $sn $c 0]
    if {$p ne {0 0}} {
	lassign $p x y
	set dx [- $x]
	set dy [- $y]
	set r [chain [translate $x $y] $r [translate $dx $dy]]
    }

    return $r
}

proc ::crimp::transform::quadrilateral {src dst} {
    # A quadrilateral is a set of 4 arbitrary points connected by
    # lines, convex. It is the most general form of a convex polygon
    # through 4 points.
    #
    # A transform based on quadrilaterals maps from a source quad to a
    # destination quad. This can be captured as perspective, i.e.
    # projective transform.

    return [chain [Q2UNIT $dst] [invert [Q2UNIT $src]]]
    #              ~~~~~~~~~~~   ~~~~~~~~~~~~~~~~
    #         unit rect -> dst   src -> unit rect
}

proc ::crimp::transform::chain {t args} {
    if {[llength $args] == 0} {
	return $t
    }
    set args [linsert $args 0 $t]
    while {[llength $args] > 1} {
	set args [lreplace $args end-1 end \
		      [MAKE [::crimp::matmul3x3_float \
				 [CHECK [lindex $args end-1]] \
				 [CHECK [lindex $args end]]]]]
    }
    return [lindex $args 0]
}

proc ::crimp::transform::invert {a} {
    return [MAKE [::crimp::matinv3x3_float [CHECK $a]]]
}

proc ::crimp::transform::Q2UNIT {quad} {
    # Calculate the transform from the unit rectangle to the specified
    # quad.
    # Derived from the paper.
    # A Planar Perspective Image Matching using Point Correspondences and Rectangle-to-Quadrilateral Mapping
    # Dong-Keun Kim, Byung-Tae Jang, Chi-Jung Hwang
    # http://portal.acm.org/citation.cfm?id=884607
    # http://www.informatik.uni-trier.de/~ley/db/conf/ssiai/ssiai2002.html

    lassign $quad pa pb pc pd
    lassign $pa ax ay
    lassign $pb bx by
    lassign $pc cx cy
    lassign $pd dx dy

    set dxb [expr {$bx - $cx}]
    set dxc [expr {$dx - $cx}]
    set dxd [expr {$ax - $bx + $cx - $dx}]

    set dyb [expr {$by - $cy}]
    set dyc [expr {$dy - $cy}]
    set dyd [expr {$ay - $by + $cy - $dy}]

    set D [expr {($dxb*$dyc - $dyb*$dxc)}]
    set g [expr {($dxd*$dyd - $dxc*$dyd)/double($D)}]
    set h [expr {($dxb*$dyd - $dyb*$dxd)/double($D)}]

    set a [expr {$bx * (1+$g) - $ax}]
    set b [expr {$dx * (1+$h) - $ax}]
    set c $ax

    set d [expr {$by * (1+$g) - $ay}]
    set e [expr {$dy * (1+$h) - $ay}]
    set f $ay

    return [projective $a $b $c $d $e $f $g $h]
}

proc ::crimp::transform::MAKE {m} {
    variable typecode
    return [list $typecode $m]
}

proc ::crimp::transform::CHECK {transform {prefix {}}} {
    variable typecode
    if {
	[catch {llength $transform} len] ||
	($len != 2) ||
	([lindex $transform 0] ne $typecode) ||
	[catch {::crimp::TypeOf [set m [lindex $transform 1]]} t] ||
	($t ne "float") ||
	([::crimp::dimensions $m] ne {3 3})
    } {
	return -code error "${prefix}expected projective transform, this is not it."
    }
    return $m
}

# # ## ### ##### ######## #############

proc ::crimp::logpolar {image rwidth rheight {xcenter 0} {ycenter 0} {corners 1}} {
    set itype [::crimp::TypeOf $image]
    if {[::crimp::Has lpt_$itype]} {
	lassign [::crimp::dimensions $image] width height

	set hcenter [expr {$width  / 2 + $xcenter}]
	set vcenter [expr {$height / 2 + $ycenter}]

	return [::crimp::lpt_$itype $image $hcenter $vcenter $rwidth $rheight $corners]
    } else {
	return -code error "The log-polar transformation is not supported for image type \"$itype\" "
    }
}

# # ## ### ##### ######## #############
## warping images

namespace eval ::crimp::warp {
    namespace export {[a-z]*}
    namespace ensemble create
}

# Alt syntax: Single vector field, this will require a 2d-float type.
proc ::crimp::warp::field {args} {
    return [Field [::crimp::INTERPOLATE args] {*}$args]
}

proc ::crimp::warp::Field {interpolation image xvec yvec} {
    # General warping. Two images of identical size in all dimensions
    # providing for each pixel of the result the x and y coordinates
    # in the input image to sample from.

    if {[::crimp::dimensions $xvec] ne [::crimp::dimensions $yvec]} {
	return -code error "Unable to warp, expected equally-sized coordinate fields"
    }

    set xvec [::crimp::convert::2float $xvec]
    set yvec [::crimp::convert::2float $yvec]

    set rtype [::crimp::TypeOf $image]
    if {$rtype in {rgb rgba hsv grey8}} {
	set ftype mbyte
    } else {
	set ftype $rtype
    }

    set f warp_${ftype}_field_$interpolation
    if {![::crimp::Has $f]} {
	return -code error "Unable to warp, the image type ${rtype} is not supported for $interpolation interpolation"
    }

    return [::crimp::$f $image $xvec $yvec]
}

proc ::crimp::warp::projective {args} {
    return [Projective [::crimp::INTERPOLATE args] {*}$args]
}

proc ::crimp::warp::Projective {interpolation image transform} {
    # Warping using a projective transform. We could handle this by
    # computing src coordinates, saved into float fields, and then
    # calling on the general 'warp'. However, this is so common that
    # we have a special primitive which does all that in less memory.

    set rtype [::crimp::TypeOf $image]
    if {$rtype in {rgb rgba hsv grey8}} {
	set ftype mbyte
    } else {
	set ftype $rtype
    }

    set f warp_${ftype}_projective_$interpolation
    if {![::crimp::Has $f]} {
	return -code error "Unable to warp, the image type ${rtype} is not supported for $interpolation interpolation"
    }

    return [::crimp::$f $image [::crimp::transform::CHECK $transform "Unable to warp, "]]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::kernel {
    namespace export *
    namespace ensemble create
}

proc ::crimp::kernel::make {kernelmatrix {scale {}} {offset {}}} {
    # The input matrix is signed -128...127. Convert this into the
    # range 0..255, 2-complement notation.

    set tmpmatrix {}
    set tmpscale 0
    foreach r $kernelmatrix {
	set tmprow {}
	foreach v $r {
	    set v [::crimp::table::CLAMPS $v]
	    incr tmpscale $v ; # scale is computed before converting unsigned two-complement.
	    set v [expr {($v >= 0) ? $v : (256+$v)}]
	    lappend tmprow $v
	}
	lappend tmpmatrix $tmprow
    }

    # auto-scale, if needed
    if {$scale eq {}} {
	if {$tmpscale == 0} {
	    set scale 1
	} else {
	    set scale $tmpscale
	}
    }

    # auto-offset, if needed
    if {$offset eq {}} {
	if {$tmpscale == 0} {
	    set offset 128
	} else {
	    set offset 0
	}
    }

    set kernel [::crimp::read::tcl grey8 $tmpmatrix]

    lassign [::crimp::dimensions $kernel] w h

    if {!($w % 2) || !($h % 2)} {
	# Keep in sync with the convolve primitives.
	# FUTURE :: Have an API to set the messages used by the primitives.
	return -code error "bad kernel dimensions, expected odd size"
    }

    set kw [expr {$w/2}]
    set kh [expr {$h/2}]

    return [list $kw $kh $kernel $scale $offset]
}

proc ::crimp::kernel::fpmake {kernelmatrix {offset {}}} {
    set matsum 0
    foreach row $kernelmatrix {
	foreach v $row {
	    set matsum [expr {$matsum + $v}]
	}
    }

    # auto-offset, if needed
    if {$offset eq {}} {
	# TODO :: Check against a suitable epsilon instead of exact zero.
	if {$matsum == 0} {
	    set offset 128
	} else {
	    set offset 0
	}
    }

    set kernel [::crimp::read::tcl float $kernelmatrix]

    lassign [::crimp::dimensions $kernel] w h

    if {!($w % 2) || !($h % 2)} {
	# Keep in sync with the convolve primitives.
	# FUTURE :: Have an API to set the messages used by the primitives.
	return -code error "bad kernel dimensions, expected odd size"
    }

    set kw [expr {$w/2}]
    set kh [expr {$h/2}]

    # The scale is fixed at 1, fp-kernels are assumed to have any
    # scaling built in.
    return [list $kw $kh $kernel 1 $offset]
}


proc ::crimp::kernel::transpose {kernel} {
    lassign $kernel w h K scale offset
    set Kt [::crimp::flip::transpose $K]
    return [list $h $w $Kt $scale $offset]
}

proc ::crimp::kernel::image {kernel} {
    return [lindex $kernel 2]
}

# # ## ### ##### ######## #############
## Image pyramids

namespace eval ::crimp::pyramid {
    namespace export *
    namespace ensemble create
}

proc ::crimp::pyramid::run {image steps stepfun} {
    set     res {}
    lappend res $image

    set iter $image
    while {$steps > 0} {
	lassign [{*}$stepfun $iter] result iter
	lappend res $result
	incr steps -1
    }
    lappend res $iter
    return $res
}

proc ::crimp::pyramid::gauss {image steps} {
    lrange [run $image $steps [list ::apply {{kernel image} {
	set low [::crimp::decimate::xy $image 2 $kernel]
	return [list $low $low]
    }} [::crimp::kernel::make {{1 4 6 4 1}}]]] 0 end-1
}

proc ::crimp::pyramid::laplace {image steps} {
    run $image $steps [list ::apply {{kerneld kerneli image} {
	set low  [::crimp::decimate::xy    $image 2 $kerneld]
	set up   [::crimp::interpolate::xy $low   2 $kerneli]

	# Handle problem with input image size not a multiple of
	# two. Then the interpolated result is smaller by one pixel.
	set dx [expr {[::crimp::width $image] - [::crimp::width $up]}]
	if {$dx > 0} {
	    set up [::crimp::expand const $up 0 0 $dx 0]
	}
	set dy [expr {[::crimp::height $image] - [::crimp::height $up]}]
	if {$dy > 0} {
	    set up [::crimp::expand const $up 0 0 0 $dy]
	}

	set high [::crimp::subtract $image $up]
	return [list $high $low]
    }} [::crimp::kernel::make {{1 4 6 4 1}}] \
       [::crimp::kernel::make {{1 4 6 4 1}} 8]]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::fft {
    namespace export {[a-z]*}
    namespace ensemble create
}

proc ::crimp::fft::forward {image} {
    set type [::crimp::TypeOf $image]
    set f fftx_$type
    if {![::crimp::Has $f]} {
	return -code error "Unable to fourier transform images of type \"$type\""
    }

    # 2d-fft as sequence of 1d-fft's, first horizontal, then vertical.
    # As a shortcut to the implementation the vertical is done by
    # transposing, horizontal fftp, and transposing back.  This
    # sequence will be replaced by a vertical fftp primitive when we
    # have it (And the transpositions will be implicit in its
    # implementation). As the result of the fft is a float-type image
    # we directly call on the appropriate primitives without the need
    # for dynamic dispatch.

    if {  $type eq "fpcomplex"  } {
	return [::crimp::flip_transpose_fpcomplex \
		    [::crimp::fftx_fpcomplex \
			 [::crimp::flip_transpose_fpcomplex \
			      [::crimp::fftx_fpcomplex $image]]]]
    } else {
	return [::crimp::flip_transpose_float \
		    [::crimp::fftx_float \
			 [::crimp::flip_transpose_float \
			      [::crimp::$f $image]]]]
    }
}

proc ::crimp::fft::backward {image} {
    set type [::crimp::TypeOf $image]
    set f ifftx_$type
    if {![::crimp::Has $f]} {
	return -code error "Unable to reverse fourier transform images of type \"$type\""
    }

    # 2d-ifft as sequence of 1d-ifft's, first horizontal, then vertical.
    # As a shortcut to the implementation the vertical is done by
    # transposing, horizontal fftp, and transposing back.  This
    # sequence will be replaced by a vertical fftp primitive when we
    # have it (And the transpositions will be implicit in its
    # implementation). As the result of the fft is a float-type image
    # we directly call on the appropriate primitives without the need
    # for dynamic dispatch.

    if {  $type eq "fpcomplex" } {
	return [::crimp::flip_transpose_fpcomplex \
		    [::crimp::ifftx_fpcomplex \
			 [::crimp::flip_transpose_fpcomplex \
			      [::crimp::ifftx_fpcomplex $image]]]]
    } else {
	return [::crimp::flip_transpose_float \
		    [::crimp::ifftx_float \
			 [::crimp::flip_transpose_float \
			      [::crimp::$f $image]]]]
    }
}

# # ## ### ##### ######## #############

namespace eval ::crimp::statistics {
    namespace export {[a-z]*}
    namespace ensemble create
}

proc ::crimp::statistics::basic {image} {
    array set stat {}

    # Basics
    set stat(channels)   [::crimp::channels   $image]
    set stat(dimensions) [::crimp::dimensions $image]
    set stat(height)     [::crimp::height     $image]
    set stat(width)      [::crimp::width      $image]
    set stat(type)       [::crimp::TypeOf     $image]
    set stat(pixels)     [set n [expr {$stat(width) * $stat(height)}]]

    # Type specific statistics primitive available ? If yes, then this
    # has priority over us doing the histogram and pulling the data
    # out of it.

    set f stats_$stat(type)
    if {[::crimp::Has $f]} {
	set stat(channel) [::crimp::$f $image]
	return [array get stat]
    }

    # No primitive, go through the histogram. The types which have the
    # histogram are also served by the 'stats_multi' primitive which
    # provides the major parts of the statistics.

    set stat(channel) [::crimp::stats_multi $image]
    upvar 0 stat(channel) result

    # Add the histogram and derived data, per channel.

    foreach {c h} [::crimp::histogram $image] {
	#puts <$c>
	set hf     [dict values $h]
	#puts H|[llength $hf]||$hf
	set cdf    [::crimp::CUMULATE $hf]
	#puts C|[llength $cdf]|$cdf
	set cdf255 [::crimp::FIT $cdf 255]

	# Merge with result.
	dict set result $c histogram $h
	dict set result $c hf        $hf
	dict set result $c cdf       $cdf
	dict set result $c cdf255    $cdf255

	set min [dict get $result $c min]
	set max [dict get $result $c max]

	# Median
	if {$min == $max} {
	    set median $min
	} else {
	    set median 0
	    foreach {p count} $h s $cdf255 {
		if {$s <= 127} continue
		set median $p
		break
	    }
	}

	dict set result $c median $median
	# geom mean
    }

    return [array get stat]
}

proc ::crimp::statistics::otsu {basic} {
    foreach c [dict get $basic channels] {
	dict set basic channel $c otsu \
	    [OTSU [dict get $basic channel $c histogram]]
    }
    return $basic
}

proc ::crimp::statistics::OTSU {histogram} {
    # Code based on the explanations at
    # http://www.labbookpages.co.uk/software/imgProc/otsuThreshold.html
    # See also http://en.wikipedia.org/wiki/Otsu%27s_method

    set weightAll 0
    set sumAll    0
    set wlist     {}
    foreach {pixel count} $histogram {
	set w [expr {$pixel * $count}]
	lappend wlist $w
	incr sumAll    $w
	incr weightAll $count
    }

    set sumBg       0
    set sumFg       $sumAll
    set threshold   0          ; # And the associated threshold.
    set varianceMax 0          ; # Maxium of variance found so far.
    set weightBg    0          ; # Weight of background pixels
    set weightFg    $weightAll ; # Weight of foreground pixels

    foreach {pixel count} $histogram w $wlist {
	# update weights.
	incr weightBg  $count ; if {!$weightBg} continue
	incr weightFg -$count ; if {!$weightFg} break

	incr sumBg  $w
	incr sumFg -$w

	# Mean values for current threshold.
	set meanBg [expr {double($sumBg) / $weightBg}]
	set meanFg [expr {double($sumFg) / $weightFg}]

	# Variance between the classes.
	set varianceBetween [expr {$weightBg * $weightFg * ($meanBg - $meanFg)**2}]

	# And update the guess on the threshold.
	if {$varianceBetween > $varianceMax} {
	    set varianceMax $varianceBetween
	    set threshold   $pixel
	}
    }

    return $threshold
}

# # ## ### ##### ######## #############
# # ## ### ##### ######## #############

namespace eval ::crimp::gradient {
    namespace export {[a-z]*}
    namespace ensemble create
}

# TODO :: Force/check proper input ranges for pixel values.

proc ::crimp::gradient::grey8 {s e size} {
    if {$size < 2} {
	return -code error "Minimum size is 2"
    }

    set steps [expr {$size - 1}]

    set d [expr {($e - $s)/double($steps)}]

    for {set t 0} {$steps >= 0} {
	incr steps -1
	incr t
    } {
	lappend pixels [expr {round($s + $t * $d)}]
    }

    return [::crimp::read::tcl grey8 [list $pixels]]
}

proc ::crimp::gradient::rgb {s e size} {
    if {$size < 2} {
	return -code error "Minimum size is 2"
    }

    set steps [expr {$size - 1}]
    lassign $s sr sg sb
    lassign $e er eg eb

    set dr [expr {($er - $sr)/double($steps)}]
    set dg [expr {($eg - $sg)/double($steps)}]
    set db [expr {($eb - $sb)/double($steps)}]

    for {set t 0} {$steps >= 0} {
	incr steps -1
	incr t
    } {
	lappend r [expr {round($sr + $t * $dr)}]
	lappend g [expr {round($sg + $t * $dg)}]
	lappend b [expr {round($sb + $t * $db)}]
    }

    return [::crimp::join::2rgb \
		[::crimp::read::tcl grey8 [list $r]] \
		[::crimp::read::tcl grey8 [list $g]] \
		[::crimp::read::tcl grey8 [list $b]]]
}

proc ::crimp::gradient::rgba {s e size} {
    if {$size < 2} {
	return -code error "Minimum size is 2"
    }

    set steps [expr {$size - 1}]
    lassign $s sr sg sb sa
    lassign $e er eg eb ea

    set dr [expr {($er - $sr)/double($steps)}]
    set dg [expr {($eg - $sg)/double($steps)}]
    set db [expr {($eb - $sb)/double($steps)}]
    set da [expr {($ea - $sa)/double($steps)}]

    for {set t 0} {$steps >= 0} {
	incr steps -1
	incr t
    } {
	lappend r [expr {round($sr + $t * $dr)}]
	lappend g [expr {round($sg + $t * $dg)}]
	lappend b [expr {round($sb + $t * $db)}]
	lappend a [expr {round($sa + $t * $da)}]
    }

    return [::crimp::join::2rgba \
		[::crimp::read::tcl grey8 [list $r]] \
		[::crimp::read::tcl grey8 [list $g]] \
		[::crimp::read::tcl grey8 [list $b]] \
		[::crimp::read::tcl grey8 [list $a]]]
}

proc ::crimp::gradient::hsv {s e steps} {
    if {$size < 2} {
	return -code error "Minimum size is 2"
    }

    set steps [expr {$size - 1}]
    lassign $s sh ss sv
    lassign $e eh es ev

    set dh [expr {($eh - $sh)/double($steps)}]
    set ds [expr {($es - $ss)/double($steps)}]
    set dv [expr {($ev - $sv)/double($steps)}]

    for {set t 0} {$steps >= 0} {
	incr steps -1
	incr t
    } {
	lappend h [expr {round($sh + $t * $dh)}]
	lappend s [expr {round($ss + $t * $ds)}]
	lappend v [expr {round($sv + $t * $dv)}]
    }

    return [::crimp::join::2hsv \
		[::crimp::read::tcl grey8 [list $h]] \
		[::crimp::read::tcl grey8 [list $s]] \
		[::crimp::read::tcl grey8 [list $v]]]
}

# # ## ### ##### ######## #############
## Tables and maps.
## For performance we should memoize results.
## This is not needed to just get things working howver.

proc ::crimp::map {args} {
    return [read::tcl grey8 [list [table {*}$args]]]
}

proc ::crimp::mapof {table} {
    return [read::tcl grey8 [list $table]]
}

namespace eval ::crimp::table {
    namespace export {[a-z]*}
    namespace ensemble create
}

# NOTE: From now on the use of the builtin 'eval' command in the table
# namespace requires '::eval'.

namespace eval ::crimp::table::eval {
    namespace export wrap clamp
    namespace ensemble create
}

proc ::crimp::table::eval::wrap {cmdprefix} {
    for {set i 0} {$i < 256} {incr i} {
	lappend table [::crimp::table::WRAP \
			   [expr {round([uplevel #0 [list {*}$cmdprefix $i]])}]]
    }
    return $table
}

proc ::crimp::table::eval::clamp {cmdprefix} {
    for {set i 0} {$i < 256} {incr i} {
	lappend table [::crimp::table::CLAMP \
			   [expr {round([uplevel #0 [list {*}$cmdprefix $i]])}]]
    }
    return $table
}

proc ::crimp::table::compose {f g} {
    # f and g are tables! representing functions, not command
    # prefixes.

    set table {}
    for {set i 0} {$i < 256} {incr i} {
	lappend table [lindex $f [lindex $g $i]]
    }
    return $table
}

proc ::crimp::table::identity {} {
    for {set i 0} {$i < 256} {incr i} {
	lappend table $i
    }
    return $table
}

proc ::crimp::table::invers {} {
    return [lreverse [identity]]
}

proc ::crimp::table::solarize {n} {
    if {$n < 0}   { set n 0   }
    if {$n > 256} { set n 256 }

    # n is the threshold above which we invert the pixel values.
    # Anything less is left untouched. This implies that 256 inverts
    # nothing, as everything is less; and 0 inverts all, as everything
    # is larger or equal.

    set t {}
    for {set i 0} {$i < 256} {incr i} {
	if {$i < $n} {
	    lappend t $i
	} else {
	    lappend t [expr {255 - $i}]
	}
    }
    return $t

    # In terms of existing tables, and joining parts ... When we
    # memoize results in the future the code below should be faster,
    # as it will have quick access to the (invers) identity
    # tables. When computing from scratch the cont. recalc of these
    # should be slower, hence the loop above.

    if {$n == 0} {
	# Full solarization
	return [invers]
    } elseif {$n == 256} {
	# No solarization
	return [identity]
    } else {
	# Take part of identity, and part of invers, as per the chosen
	# threshold.
	set l [expr {$n - 1}]
	set     t    [lrange [identity] 0 $l]
	lappend t {*}[lrange [invers] $n end]
	return $t
    }
}

proc ::crimp::table::gamma {y} {
    # Note: gamma operates in range [0..1], our data is [0..255]. We
    # have to scale down before applying the gamma, then scale back.

    #eval::clamp [list ::apply {{y i} {expr {(($i/255.0) ** $y)*255.0}}} $y]

    for {set i 0} {$i < 256} {incr i} {
	lappend table [CLAMP [expr {round ((($i/255.0) ** $y)*255.0)}]]
    }
    return $table
}

proc ::crimp::table::degamma {y} {
    # Note: gamma operates in range [0..1], our data is [0..255]. We
    # have to scale down before applying the gamma, then scale back.

    set dy [expr {1.0/$y}]
    #eval::clamp [list ::apply {{dy i} {expr {(($i/255.0) ** $dy)*255.0}}} $dy]

    for {set i 0} {$i < 256} {incr i} {
	lappend table [CLAMP [expr {round ((($i/255.0) ** $dy)*255.0)}]]
    }
    return $table
}

proc ::crimp::table::sqrt {{max 255}} {
    # y = r*sqrt(x)
    # ==> 255 = r*sqrt(max)
    # <=> r = 255/sqrt(max)
    # (r == 1) <=> (sqrt(max) == 255)

    set r [expr {255.0/sqrt($max)}]
    #eval::clamp [list ::apply {{r i} {expr {$r*sqrt($i)}}} $r]

    for {set i 0} {$i < 256} {incr i} {
	lappend table [CLAMP [expr {round ($r*sqrt($i))}]]
    }
    return $table
}

proc ::crimp::table::log {{max 255}} {
    #       y = c*log(1+x)
    # ==> 255 = c*log(1+max)
    # <=> c = 255/log(1+max)
    # (c == 1) <=> (log(1+max) == 255)

    set c [expr {255.0/log(1.0+$max)}]
    #eval::clamp [list ::apply {{c i} {expr {$c*log(1+$i)}}} $r]

    # i = 1..256 instead of 0..255 i.e. 1+x is implied by the change
    # in the iteration range.
    for {set i 1} {$i < 257} {incr i} {
	lappend table [CLAMP [expr {round($c*log($i))}]]
    }
    return $table
}

namespace eval ::crimp::table::linear {
    namespace export wrap clamp
    namespace ensemble create
}

proc ::crimp::table::linear::wrap {gain offset} {
    return [::crimp::table::eval::wrap [list ::apply {{gain offset i} {
	expr {double($gain) * $i + double($offset)}
    }} $gain $offset]]
}

proc ::crimp::table::linear::clamp {gain offset} {
    return [::crimp::table::eval::clamp [list ::apply {{gain offset i} {
	expr {double($gain) * $i + double($offset)}
    }} $gain $offset]]
}

proc ::crimp::table::stretch {min max} {
    # min => 0, max => 255, linear interpolation between them.
    #
    #     gain*max+offs = 255
    #     gain*min+offs = 0        <=> gain*min = 0-offs
    # <=> gain(max-min) = 255-0  | <=> offs = -gain*min
    # <=> GAIN = 255/(max-min)
    #

    set gain   [expr {255.0/($max - $min)}]
    set offset [expr {- ($min * $gain)}]

    return [linear::clamp $gain $offset]
}

namespace eval ::crimp::table::threshold {
    namespace export *
    namespace ensemble create
}

# [below T] <=> (x < T) <=> [invert [above T]]
# [above T] <=> (x >= T)

proc ::crimp::table::threshold::below {threshold} {
    for {set x 0} {$x < 256} {incr x} {
	lappend table [expr {($x <= $threshold) ? 255 : 0}]
    }
    return $table
}

proc ::crimp::table::threshold::above {threshold} {
    for {set x 0} {$x < 256} {incr x} {
	lappend table [expr {($x > $threshold) ? 255 : 0}]
    }
    return $table
}

# [inside  Tmin Tmax] <=> (Tmin < x)  && (x < Tmax) <=> [invert [outside Tmin Tmax]],
# [outside Tmin Tmax] <=> (x <= Tmin) || (x >= Tmax)

proc ::crimp::table::threshold::inside {min max} {
    for {set x 0} {$x < 256} {incr x} {
	lappend table [expr {($min <= $x) && ($x <= $max) ? 255 : 0}]
    }
    return $table
}

proc ::crimp::table::threshold::outside {min max} {
    for {set x 0} {$x < 256} {incr x} {
	lappend table [expr {($min <= $x) && ($x <= $max) ? 0 : 255}]
    }
    return $table
}

proc ::crimp::table::gauss {sigma} {
    # Sampled gaussian.
    # For the discrete gaussian I need 'modified bessel functions of
    # integer order'. Check if tcllib/math contains them.

    # a*e^(-(((x-b)^2)/(2c^2)))
    # a = 255, b = 127.5, c = sigma

    for {set x 0} {$x < 256} {incr x} {
	lappend table [expr {round(255*exp(-(($x-127.5)**2/(2*$sigma**2))))}]
    }
    return $table
}

# Reference: http://en.wikipedia.org/wiki/Scale_space_implementation
namespace eval ::crimp::table::fgauss {
    namespace export discrete sampled
    namespace ensemble create
}

proc ::crimp::table::fgauss::discrete {sigma {r {}}} {
    # Discrete gaussian.

    # Reference: http://en.wikipedia.org/wiki/Scale_space_implementation#The_discrete_Gaussian_kernel
    # G(x,sigma) = e^(-t)*I_x(t), where t = sigma^2
    # and I_x = Modified Bessel function of Order x
    package require math::special

    if {$sigma <= 0} {
	return -code error -errorCode {ARITH DOMAIN INVALID} {Invalid sigma, expected number > 0}
    }

    # Determine kernel radius from the sigma, if not overriden by the caller.
    if {([llength [info level 0]] < 3) || ($r eq {})} {
	set r [expr {int(ceil(3*$sigma))}]
	if {$r < 1} { set r 1 }
    }

    # Compute the upper half of the kernel (0...3*sigma).
    set table {}
    set t [expr {$sigma ** 2}]

    for {set x 0} {$x <= $r} {incr x} {
        set v [expr {exp(-$t)*[math::special::I_n $x $t]}]
	lappend table $v
    }

    # Then reflect this to get the lower half, and join the two. This
    # also ensures that the generated table is of odd length, as
    # expected for convolution kernels.

    if {[llength $table] > 1} {
	set table [linsert $table 0 {*}[lreverse [lrange $table 1 end]]]
    }

    # Last step, get the sum over the table, and then adjust all
    # elements to make this sum equial to 1.

    set s 0    ; foreach t $table {set s [expr {$s+$t}]}
    set tmp {} ; foreach t $table {lappend tmp [expr {$t/$s}]}

    return $tmp
}

proc ::crimp::table::fgauss::sampled {sigma {r {}}} {
    # Sampled gaussian

    # Reference: http://en.wikipedia.org/wiki/Scale_space_implementation#The_sampled_Gaussian_kernel
    # G(x,sigma) =  1/sqrt(2*t*pi)*e^(-x^2/(2*t))
    # where t = sigma^2
    package require math::constants
    math::constants::constants pi

    if {$sigma <= 0} {
	return -code error -errorCode {ARITH DOMAIN INVALID} {Invalid sigma, expected number > 0}
    }

    # Determine kernel radius from the sigma, if not overriden by the caller.
    if {([llength [info level 0]] < 3) || ($r eq {})} {
	set r [expr {int(ceil(3*$sigma))}]
	if {$r < 1} { set r 1 }
    }

    # Compute upper half of the kernel (0...3*sigma).
    set table {}
    set scale  [expr {1.0 / ($sigma * sqrt(2 * $pi))}]
    set escale [expr {2 * $sigma ** 2}]

    for {set x 0} {$x <= $r} {incr x} {
	lappend table [expr {$scale * exp(-($x**2/$escale))}]
    }

    # Then reflect this to get the lower half, and join the two. This
    # also ensures that the generated table is of odd length, as
    # expected for convolution kernels.

    if {[llength $table] > 1} {
	set table [linsert $table 0 {*}[lreverse [lrange $table 1 end]]]
    }

    # Last step, get the sum over the table, and then adjust all
    # elements to make this sum equial to 1.

    set s 0    ; foreach t $table {set s [expr {$s+$t}]}
    set tmp {} ; foreach t $table {lappend tmp [expr {$t/$s}]}

    return $tmp
}

# # ## ### ##### ######## #############

namespace eval ::crimp::table::quantize {
    namespace export {[a-z]*}
    namespace ensemble create

    variable  pmap
    array set pmap {
	low  0   down 0   min 0   median 50
	high 100 up   100 max 100
    }
}

proc ::crimp::table::quantize::histogram {n p h} {
    # Get the histogram as function, integrate it, and scale to the
    # standard range 0...255 before using it to compute a
    # quantization.

    if {$n < 2} {
	return -code error "Unable to calculate 1-color quantization"
    }

    return [::crimp::table::quantize::Core $n $p \
		[::crimp::FIT \
		     [::crimp::CUMULATE [dict values $h]] \
		     255]]
}

proc ::crimp::table::quantize::Core {n p cdf} {
    variable pmap

    if {$n < 2} {
	return -code error "Unable to calculate 1-color quantization"
    }

    if {[info exists pmap($p)]} {
	set p $pmap($p)
    }

    # First compute the quantization steps as the (255/n)'th
    # percentiles in the histogram, and the associated high value in
    # the range the final value is chosen from.

    set res 0
    set percentile [expr {255.0/$n}]
    set threshold  $percentile

    set step  {}
    set color {}

    foreach pv [::crimp::table::identity] sum $cdf {
	if {$sum <= $threshold} continue
	lappend step   $pv
	lappend color [expr {round($threshold)}]
	set threshold [expr {$threshold + $percentile}]
	if {[llength $step] == $n} break
    }
    lappend step  256
    lappend color 255

    #puts |$step|
    #puts |$color|

    # As the second and last step compute the remapping table from the
    # steps and color ranges.
    set at 0
    set l  0

    set threshold [lindex $step  $at]
    set h         [lindex $color $at]
    set c [expr {round($l + ($p/100.0)*($h - $l))}]
    #puts =<$threshold|$l|$h|=$c

    set table {}
    for {set pix 0} {$pix < 256} {incr pix} {
	while {$pix >= $threshold} {
	    incr at
	    set  l $h

	    set threshold [lindex $step  $at]
	    set h         [lindex $color $at]
	    set c [expr {round($l + ($p/100.0)*($h - $l))}]
	    #puts +<$threshold|$l|$h|=$c
	}
	# assert (c in (0...255))
	lappend table $c
    }

    #puts [llength $table] (== 256 /assert)
    return $table
}

# # ## ### ##### ######## #############

proc ::crimp::table::CLAMPS {x} {
    if {$x < -128 } { return -128 }
    if {$x >  127 } { return  127 }
    return $x
}

proc ::crimp::table::CLAMP {x} {
    if {$x < 0  } { return 0   }
    if {$x > 255} { return 255 }
    return $x
}

proc ::crimp::table::WRAP {x} {
    while {$x < 0  } {
	incr x 255
    }
    while {$x > 255} {
	incr x -255
    }
    return $x
}
# series(int) --> series (int)
proc ::crimp::CUMULATE {series} {
    set res {}
    set sum 0
    foreach x $series {
	incr sum $x
	lappend res $sum
    }
    return $res
}

# series(int/float) --> series(int), all(x): x <= max
proc ::crimp::FIT {series max} {
    # Assumes that the input is a monotonically increasing
    # series. The maximum value of the series is at the end.
    set top [lindex $series end]

    if {$top == 0} {
	# The inputs fits regardless of maximum.
	return $series
    }

    #puts /$top/
    set f   [expr {double($max) / double($top)}]
    set res {}

    foreach x $series {
	lappend res [expr {round(double($x)*$f)}]
    }
    return $res
}

# Compress (or expand) a float image into the full 0...255 range of grey8.
proc ::crimp::FITFLOAT {i} {
    return [FITFLOATRANGE $i {*}[FLOATMINMAX $i]]
}

proc ::crimp::FITFLOATB {i {sigma 1.2}} {
    return [FITFLOATRANGE $i {*}[FLOATMEANSTDDEV $i $sigma]]
}

proc ::crimp::FITFLOATRANGE {i min max} {
    set offset [expr {-1 * $min}]
    set scale  [expr {255.0/($max - $min)}]

    return [crimp::convert_2grey8_float \
		[crimp::scale_float \
		     [crimp::offset_float $i $offset] \
		     $scale]]
}

proc ::crimp::FLOATMINMAX {i} {
    set statistics [crimp statistics basic $i]
    set min        [dict get $statistics channel value min]
    set max        [dict get $statistics channel value max]
    return [list $min $max]
}

proc ::crimp::FLOATMEANSTDDEV {i {sigma 1.2}} {
    set statistics [crimp statistics basic $i]
    set mean       [dict get $statistics channel value mean]
    set var        [dict get $statistics channel value stddev]
    set min        [expr {$mean - $var * $sigma}]
    set max        [expr {$mean + $var * $sigma}]
    return [list $min $max]
}

# # ## ### ##### ######## #############

namespace eval ::crimp {
    namespace export type width height dimensions channels cut color
    namespace export read write convert join flip split table hypot
    namespace export invert solarize gamma degamma remap map atan2
    namespace export wavy psychedelia matrix blank filter crop scale
    namespace export alpha histogram max min screen add pixel
    namespace export subtract difference multiply pyramid mapof
    namespace export downsample upsample decimate interpolate logpolar
    namespace export kernel expand threshold gradient effect register
    namespace export statistics rotate montage morph integrate divide
    namespace export fft square resize warp transform contrast noise
    #
    namespace ensemble create
}

# # ## ### ##### ######## #############
return
