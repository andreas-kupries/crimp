## -*- tcl -*-
# # ## ### ##### ######## #############
## This file defines a number of commands on top of the C primitives
## which are easier to use than directly calling on the latter.

namespace eval ::crimp {}

# # ## ### ##### ######## #############

proc ::crimp::List {pattern} {
    # We have to look at both actually registered commands, and
    # potentially registered commands. The first are defined when
    # loading crimp as package, the latter when using crimp in
    # immediate mode (the cproc's etc. are only registered in
    # auto_index, compilation and actualy registriation is defered
    # until actual usage of a command).
    return [list \
		{*}[info commands            ::crimp::$pattern] \
		{*}[array names ::auto_index ::crimp::$pattern]]
}

proc ::crimp::Has {name} {
    # See List above for why we look into the auto_index.
    return [expr {
	  [llength [info commands            ::crimp::$name]] ||
	  [llength [array names ::auto_index ::crimp::$name]]
      }]
}

proc ::crimp::P {fqn} {
    return [lrange [::split [namespace tail $fqn] _] 1 end]
}

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
    return [crimp::$fe $image $w $n $e $s {*}$values]
}

proc ::crimp::BORDER {imagetype spec} {
    set values [lassign $spec bordertype]

    if {![llength [List expand_*_$bordertype]]} {
	# TODO :: Compute/memoize available border types.
	return -code error "Unknown border type \"$bordertype\", expected one of ..."
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
		grey8 {
		    if {![llength $values]} {
			set values {0}
		    } elseif {[llength $values] > 1} {
			set values [lrange $values 0 0]
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

proc ::crimp::meta {image {meta {}}} {

    if {[llength [info level 0]] == 3} {
	return [meta_set [K $image [unset image]] $meta]
    } else {
	return [meta_get $image]
    }
}

# # ## ### ##### ######## #############
## Read is done via sub methods, one per format to read from.
#
## Ditto write, convert, and join, one per destination format. Note
## that for write and convert the input format is determined
## automatically from the image.

namespace eval ::crimp::read {
    namespace export *
    namespace ensemble create
}

::apply {{dir} {
    # Readers implemented as C primitives
    foreach fun [::crimp::List read_*] {
	# Ignore the read_tcl_ primitives. They have their own setup
	# in a moment.
	if {[string match *::read_tcl_* $fun]} continue

	proc [::crimp::P $fun] {detail} [string map [list @ $fun] {
	    @ $detail
	}]
    }

    proc tcl {format detail} {
	set f read_tcl_$format
	if {![::crimp::Has $f]} {
	    return -code error "Unable to generate images of type \"$format\" from Tcl values"
	}
	return [::crimp::$f $detail]
    }

    # Readers implemented as Tcl procedures.
    #
    # Note: This is for the case of crimp getting dynamically
    # compiled.  In the prebuild case no files will match, and the
    # relevant files are sources as part of the package index.

    foreach file [glob -nocomplain -directory $dir/reader *.tcl] {
	source $file
    }
} ::crimp::read} [file dirname [file normalize [info script]]]

# # ## ### ##### ######## #############

namespace eval ::crimp::write {
    namespace export *
    namespace ensemble create
}

::apply {{dir} {
    # Writers implemented as C primitives
    foreach fun [::crimp::List write_*] {
	proc [lindex [::crimp::P $fun] 0] {dst image} \
	    [string map [list @ [lindex [::crimp::P $fun] 0]] {
		set type [::crimp::TypeOf $image]
		set f    write_@_${type}
		if {![::crimp::Has $f]} {
		    return -code error "Unable to write images of type \"$type\" to \"@\""
		}
		return [::crimp::$f $dst $image]
	    }]
    }

    # Writers implemented as Tcl procedures.
    #
    # Note: This is for the case of crimp getting dynamically
    # compiled.  In the prebuild case no files will match, and the
    # relevant files are sources as part of the package index.

    foreach file [glob -nocomplain -directory $dir/writer *.tcl] {
	source $file
    }
} ::crimp::write} [file dirname [file normalize [info script]]]

proc ::crimp::write::2file {format path image} {
    set chan [open $path w]
    fconfigure $chan -encoding binary
    2chan $format $chan $image
    close $chan
    return
}

proc ::crimp::write::2chan {format chan image} {
    set type [::crimp::TypeOf $image]
    set f    writec_${format}_${type}

    if {![::crimp::Has $f]} {
	puts -nonewline $chan [2string $format $image]
	return
    }
    ::crimp::$f $chan $image
    return
}

proc ::crimp::write::2string {format image} {
    set type [::crimp::TypeOf $image]
    set f    writes_${format}_${type}

    if {![::crimp::Has $f]} {
	return -code error "Unable to write images of type \"$type\" to strings for \"$format\""
    }
    return [::crimp::$f $image]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::convert {
    namespace export *
    namespace ensemble create
}

::apply {{} {
    # Converters implemented as C primitives
    foreach fun [::crimp::List convert_*] {

	if {[string match {*_2[rh]*_grey8} $fun]} {
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
			    set gradient [crimp gradient % <B> <W> 256]
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
    return [crimp flip vertical [crimp flip transpose $image]]
}

proc ::crimp::rotate::cw {image} {
    return [crimp flip horizontal [crimp flip transpose $image]]
}

proc ::crimp::rotate::half {image} {
    return [crimp flip horizontal [crimp flip vertical $image]]
}

# # ## ### ##### ######## #############
## All morphology operations are currently based on a single
## structuring element, the flat 3x3 brick.

namespace eval ::crimp::morph {
    namespace export *
    namespace ensemble create
}

proc ::crimp::morph::erode {image} {
    return [crimp filter rank $image 1 99.99]
}

proc ::crimp::morph::dilate {image} {
    return [crimp filter rank $image 1 0]
}

proc ::crimp::morph::open {image} {
    return [dilate [erode $image]]
}

proc ::crimp::morph::close {image} {
    return [erode [dilate $image]]
}

proc ::crimp::morph::gradient {image} {
    return [::crimp subtract [dilate $image] [erode $image]]
}

proc ::crimp::morph::igradient {image} {
    return [::crimp subtract $image [erode $image]]
}

proc ::crimp::morph::egradient {image} {
    return [::crimp subtract [dilate $image] $image]
}

proc ::crimp::morph::tophatw {image} {
    return [::crimp subtract $image [open $image]]
}

proc ::crimp::morph::tophatb {image} {
    return [::crimp subtract [close $image] $image]
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
	set height [tcl::mathfunc::max $height [::crimp height $image]]
    }	

    lassign [crimp::BORDER $type $border] fe values

    set f montageh_${type}
    if {![::crimp::Has $f]} {
	return -code error "Unable to montage images of type \"$type\""
    }

    # todo: investigate ability of critcl to have typed var-args
    # commands.
    set remainder [lassign $args result]
    set result    [crimp::ALIGN $result $height $alignment $fe $values]
    foreach image $remainder {
	set image [crimp::ALIGN $image $height $alignment $fe $values]
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
	set width [tcl::mathfunc::max $width [::crimp width $image]]
    }	

    lassign [crimp::BORDER $type $border] fe values

    set f montagev_${type}
    if {![::crimp::Has $f]} {
	return -code error "Unable to montage images of type \"$type\""
    }

    # todo: investigate ability of critcl to have typed var-args
    # commands.
    set remainder [lassign $args result]
    set result    [crimp::ALIGN $result $width $alignment $fe $values]
    foreach image $remainder {
	set image [crimp::ALIGN $image $width $alignment $fe $values]
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
    return [crimp filter convolve $image \
		[crimp kernel make {
		    { 0  -1  0}
		    {-1   5 -1}
		    { 0  -1  0}} 1]]
}

proc ::crimp::effect::emboss {image} {
    # http://wiki.tcl.tk/9521 (Suchenwirth)
    return [crimp filter convolve $image \
		[crimp kernel make {
		    {2  0  0}
		    {0 -1  0}
		    {0  0 -1}}]]
}

proc ::crimp::effect::charcoal {image} {
    return [crimp morph gradient [crimp convert 2grey8 $image]]
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
    return [::crimp remap $image [::crimp map threshold below $n]]
}

proc ::crimp::threshold::global::above {image n} {
    return [::crimp remap $image [::crimp map threshold above $n]]
}

proc ::crimp::threshold::global::inside {image min max} {
    return [::crimp remap $image [::crimp map threshold inside $min $max]]
}

proc ::crimp::threshold::global::outside {image min max} {
    return [::crimp remap $image [::crimp map threshold outside $min $max]]
}

proc ::crimp::threshold::global::otsu {image} {
    set maps {}
    set stat [::crimp statistics otsu [::crimp statistics basic $image]]
    foreach c [dict get $stat channels] {
	lappend maps \
	    [::crimp map threshold below \
		 [dict get $stat channel $c otsu]]
    }
    return [::crimp remap $image {*}$maps]
}

proc ::crimp::threshold::global::middle {image} {
    set maps {}
    set stat [::crimp statistics basic $image]
    foreach c [dict get $stat channels] {
	lappend maps \
	    [::crimp map threshold below \
		 [dict get $stat channel $c middle]]
    }
    return [::crimp remap $image {*}$maps]
}

proc ::crimp::threshold::global::mean {image} {
    set maps {}
    set stat [::crimp statistics basic $image]
    foreach c [dict get $stat channels] {
	lappend maps \
	    [::crimp map threshold below \
		 [dict get $stat channel $c mean]]
    }
    return [::crimp remap $image {*}$maps]
}

proc ::crimp::threshold::global::median {image} {
    set maps {}
    set stat [::crimp statistics basic $image]
    foreach c [dict get $stat channels] {
	lappend maps \
	    [::crimp map threshold below \
		 [dict get $stat channel $c median]]
    }
    return [::crimp remap $image {*}$maps]
}

proc ::crimp::threshold::local {image args} {
    if {![llength $args]} {
	return -code error "wrong\#args: expected image map..."
    }

    set itype [::crimp::TypeOf $image]
    set mtype [::crimp::TypeOf [lindex $args 0]]

    foreach map $args {
	set xtype [::crimp::TypeOf $map]
	if {$xtype ne $ntype} {
	    return -code error "Map type mismatch between \"$mtype\" and \"$xtype\", all maps have to have the same type."
	}
    }

    set f threshold_${itype}_$mtype
    if {![::crimp::Has $f]} {
	return -code error "Unable to locally threshold images of type \"$itype\" with maps of type \"$mtype\""
    }

    # Shrink or extend the set of thresholding maps if too many or not
    # enough were specified, the latter by replicating the last map.

    switch -- $itype/$mtype {
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
	}
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

proc ::crimp::integrate {image} {
    set type [TypeOf $image]
    set f integrate_$type
    if {![Has $f]} {
	return -code error "Unable to integrate images of type \"$type\""
    }

    return [$f $image]
}

# # ## ### ##### ######## #############

proc ::crimp::resize {image w h} {
    # Resize the image to new width and height.
    # Done separately for each dimension.
    #
    # NOTE: Between the up- and down-sample steps of each dimension we
    # have to have a smoothing filter. Not just to prevent sampling
    # artifacts. Without we may sample the black pixels generated by
    # the up-step during the down-step.
    #
    # THEREFORE, this code is incomplete. The question is, which
    # filter to use. Well, a gaussian, but what is the proper radius ?
    #
    # FUTURE: Consider creation of the necessary combined primitives.
    #
    # ALSO, consider to have separate commands for x- and y-only
    # resizing.

    set wo [width $image]
    if {$w != $wo} {
	# resample w/wo <=> [downsample [upsample w] wo]
	# To keep the factors small and thus memory usage down we
	# actually use w/g, wo/g, where g = gcd(w,wo)

	set g  [GCD $w $wo]
	set w  [expr {$w  / $g}]
	set wo [expr {$wo / $g}]

	# Note: The resample ops have a quick path if the factor is
	# 1. No need to check and optimize this in the Tcl layer.

	set image [downsample::x [upsample::x $image $w] $wo]
    }

    set ho [height $image]
    if {$h != $ho} {
	# resample h/ho <=> [downsample [upsample h] ho]
	# To keep the factors small and thus memory usage down we
	# actually use h/g, ho/g, where g = gcd(h,ho)

	set g  [GCD $h $ho]
	set h  [expr {$h  / $g}]
	set ho [expr {$ho / $g}]

	# Note: The resample ops have a quick path if the factor is
	# 1. No need to check and optimize this in the Tcl layer.

	set image [downsample::y [upsample::y $image $h] $ho]
    }

    return $image
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
    if {![crimp::Has $f]} {
	return -code error "Cropping is not supported for images of type \"$type\""
    }
    return [crimp::$f $image $ww $hn $we $hs]
}

proc ::crimp::cut {image x y w h} {
    lassign [dimensions $image] iw ih

    set south [expr {$y + $h}]
    set east  [expr {$x + $w}]
    if {$south > $ih} { set south $ih }
    if {$east  > $iw} { set east  $iw }
    set dw [expr {$iw - $east}]
    set dh [expr {$ih - $south}]

    return [crop $image $x $y $dw $dh]
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
    ::set itype [crimp::TypeOf $image]
    ::set mtype [crimp::TypeOf $mask]
    ::set f     setalpha_${itype}_$mtype
    if {![crimp::Has $f]} {
	return -code error "Setting the alpha channel is not supported for images of type \"$itype\" and mask of type \"$mtype\""
    }
    return [crimp::$f $image $mask]
}

# # ## ### ##### ######## #############

proc ::crimp::alpha::opaque {image} {
    ::set itype [crimp::TypeOf $image]
    if {$itype ne "rgba"} { return $image }
    # alpha::set
    return [set $image [crimp blank grey8 {*}[crimp dimensions $image] 255]]
}

# # ## ### ##### ######## #############

proc ::crimp::alpha::blend {fore back alpha} {
    ::set ftype [crimp::TypeOf $fore]
    ::set btype [crimp::TypeOf $back]
    ::set f     alpha_blend_${ftype}_$btype
    if {![crimp::Has $f]} {
	return -code error "Blend is not supported for a foreground of type \"$ftype\" and a background of type \"$btype\""
    }
    return [crimp::$f $fore $back [::crimp::table::CLAMP $alpha]]
}

# # ## ### ##### ######## #############

proc ::crimp::alpha::over {fore back} {
    ::set ftype [crimp::TypeOf $fore]
    ::set btype [crimp::TypeOf $back]
    ::set f     alpha_over_${ftype}_$btype
    if {![crimp::Has $f]} {
	return -code error "Over is not supported for a foreground of type \"$ftype\" and a background of type \"$btype\""
    }
    return [crimp::$f $fore $back]
}

# # ## ### ##### ######## #############

proc ::crimp::add {a b {scale 1} {offset 0}} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]

    set f add_${atype}_$btype
    if {[Has $f]} {
	return [$f $a $b $scale $offset]
    }

    set f add_${btype}_$atype
    if {[Has $f]} {
	return [$f $b $a $scale $offset]
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

    set f difference_${btype}_$atype
    if {[Has $f]} {
	return [$f $b $a]
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

    set f multiply_${btype}_$atype
    if {[Has $f]} {
	return [$f $b $a]
    }

    return -code error "Multiply is not supported for the combination of \"$atype\" and \"$btype\""
}

# # ## ### ##### ######## #############

proc ::crimp::divide {a b {scale 1} {offset 0}} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]
    set f     div_${atype}_$btype
    if {![Has $f]} {
	return -code error "Division is not supported for the combination of \"$atype\" and \"$btype\""
    }
    return [$f $a $b $scale $offset]
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

    set f min_${btype}_$atype
    if {[Has $f]} {
	return [$f $b $a]
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

    set f max_${btype}_$atype
    if {[Has $f]} {
	return [$f $b $a]
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

    set f screen_${btype}_$atype
    if {[Has $f]} {
	return [$f $b $a]
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

    set type [crimp::TypeOf $image]
    set fc convolve_*_${type}
    if {![llength [crimp::List $fc]]} {
	return -code error "Convolution is not supported for image type \"$type\""
    }

    # Default settings for border expansion.
    lassign [crimp::BORDER $type const] fe values

    set at 0
    while {1} {
	set opt [lindex $args $at]
	if {![string match -* $opt]} break
	incr at
	switch -- $opt {
	    -border {
		set value [lindex $args $at]
		lassign [crimp::BORDER $type $value] fe values
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

	set ktype [crimp::TypeOf $K]
	set fc convolve_${ktype}_${type}
	if {![crimp::Has $fc]} {
	    return -code error "Convolution kernel type \"$ktype\" is not supported for image type \"$type\""
	}

	set image [crimp::$fc [crimp::$fe $image $kw $kh $kw $kh {*}$values] $K $scale $offset]
    }

    return $image
}

# # ## ### ##### ######## #############

proc ::crimp::filter::ahe {image args} {
    # args = ?-border spec? ?radius?

    set type [crimp::TypeOf $image]
    set fc ahe_${type}
    if {![crimp::Has $fc]} {
	return -code error "AHE filtering is not supported for image type \"$type\""
    }

    # Default settings for border expansion.
    lassign [crimp::BORDER $type const] fe values

    set at 0
    while {1} {
	set opt [lindex $args $at]
	if {![string match -* $opt]} break
	incr at
	switch -- $opt {
	    -border {
		set value [lindex $args $at]
		lassign [crimp::BORDER $type $value] fe values
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

    return [crimp::$fc [crimp::$fe $image $radius $radius $radius $radius {*}$values] \
		$radius]
}

# # ## ### ##### ######## #############

proc ::crimp::filter::mean {image args} {
    # args = ?-border spec? ?radius?

    set type [crimp::TypeOf $image]

    # Multi-channel images are handled by splitting them and
    # processing each channel separately (invoking the method
    # recursively).
    switch -exact -- $type {
	rgb - rgba - hsv {
	    set r {}
	    foreach c [crimp split $image] {
		lappend r [mean $c {*}$args]
	    }
	    return [crimp join 2$type {*}$r]
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
    lassign [crimp::BORDER $type mirror] fe values

    set at 0
    while {1} {
	set opt [lindex $args $at]
	if {![string match -* $opt]} break
	incr at
	switch -- $opt {
	    -border {
		set value [lindex $args $at]
		lassign [crimp::BORDER $type $value] fe values
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

    return [crimp convert 2$type \
		[crimp::scale_float \
		     [crimp::region_sum \
			  [crimp integrate \
			       [crimp::$fe $image $expand $expand $expand $expand {*}$values]] \
			  $radius] $factor]]
}

# # ## ### ##### ######## #############

proc ::crimp::filter::stddev {image args} {
    # args = ?-border spec? ?radius?

    set type [crimp::TypeOf $image]

    # Multi-channel images are not handled, because the output is a
    # float, which we cannot join.
    if {[llength [crimp channels $image]] > 1} {
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
    lassign [crimp::BORDER $type mirror] fe values

    set at 0
    while {1} {
	set opt [lindex $args $at]
	if {![string match -* $opt]} break
	incr at
	switch -- $opt {
	    -border {
		set value [lindex $args $at]
		lassign [crimp::BORDER $type $value] fe values
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

    set expanded [crimp::$fe $image $expand $expand $expand $expand {*}$values]
    set mean     [crimp::scale_float \
		      [crimp::region_sum \
			   [crimp integrate $expanded] \
			   $radius] \
		      $factor]

    set stddev   [crimp::sqrt_float \
		      [crimp subtract \
			   [crimp::scale_float \
				[crimp::region_sum \
				     [crimp integrate \
					  [crimp square \
					       [crimp convert 2float $expanded]]] \
				     $radius] \
				$factor] \
			   [crimp square $mean]]]

    return [list $mean $stddev]
}

# # ## ### ##### ######## #############

proc ::crimp::filter::rank {image args} {
    # args = ?-border spec? ?radius ?percentile??

    set type [crimp::TypeOf $image]
    set fc rof_${type}
    if {![crimp::Has $fc]} {
	return -code error "Rank filtering is not supported for image type \"$type\""
    }

    # Default settings for border expansion.
    lassign [crimp::BORDER $type const] fe values

    set at 0
    while {1} {
	set opt [lindex $args $at]
	if {![string match -* $opt]} break
	incr at
	switch -- $opt {
	    -border {
		set value [lindex $args $at]
		lassign [crimp::BORDER $type $value] fe values
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

    return [crimp::$fc [crimp::$fe $image $radius $radius $radius $radius {*}$values] \
		$radius $percentile]
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

    set kernel [crimp read tcl grey8 $tmpmatrix]

    lassign [crimp::dimensions $kernel] w h

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

    set kernel [crimp read tcl float $kernelmatrix]

    lassign [crimp::dimensions $kernel] w h

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
    set Kt [crimp flip transpose $K]
    return [list $h $w $Kt $scale $offset]
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
	set low [crimp decimate xy $image 2 $kernel]
	return [list $low $low]
    }} [crimp kernel make {{1 4 6 4 1}}]]] 0 end-1
}

proc ::crimp::pyramid::laplace {image steps} {
    run $image $steps [list ::apply {{kerneld kerneli image} {
	set low  [crimp decimate xy $image 2 $kerneld]
	set up   [crimp interpolate xy $low 2 $kerneli]

	# Handle problem with input image size not a multiple of
	# two. Then the interpolated result is smaller by one pixel.
	set dx [expr {[crimp width $image] - [crimp width $up]}]
	if {$dx > 0} {
	    set up [crimp expand const $up 0 0 $dx 0]
	}
	set dy [expr {[crimp height $image] - [crimp height $up]}]
	if {$dy > 0} {
	    set up [crimp expand const $up 0 0 0 $dy]
	}

	set high [crimp subtract $image $up]
	return [list $high $low]
    }} [crimp kernel make {{1 4 6 4 1}}] \
       [crimp kernel make {{1 4 6 4 1}} 8]]
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

    return [::crimp::flip_transpose_float \
		[::crimp::fftx_float \
		     [::crimp::flip_transpose_float \
			  [::crimp::$f $image]]]]
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

    return [::crimp::flip_transpose_float \
		[::crimp::ifftx_float \
		     [::crimp::flip_transpose_float \
			  [::crimp::$f $image]]]]
}

# # ## ### ##### ######## #############

namespace eval ::crimp::statistics {
    namespace export {[a-z]*}
    namespace ensemble create
}

proc ::crimp::statistics::basic {image} {
    array set stat {}

    # Basics
    set stat(channels)   [crimp channels   $image]
    set stat(dimensions) [crimp dimensions $image]
    set stat(height)     [crimp height     $image]
    set stat(width)      [crimp width      $image]
    set stat(type)       [crimp::TypeOf    $image]
    set stat(pixels)     [set n [expr {$stat(width) * $stat(height)}]]

    # Histogram and derived data, per channel.
    foreach {c h} [crimp histogram $image] {
	#puts <$c>
	set hf     [dict values $h]
	#puts H|[llength $hf]||$hf
	set cdf    [crimp::CUMULATE $hf]
	#puts C|[llength $cdf]|$cdf
	set cdf255 [crimp::FIT $cdf 255]

	# Min, max, plus pre-processing for the mean
	set min 255
	set max 0
	set sum 0
	foreach {p count} $h {
	    if {!$count} continue
	    set min [tcl::mathfunc::min $min $p]
	    set max [tcl::mathfunc::max $max $p]
	    incr sum [expr {$p * $count}]
	}

	# Arithmetic mean
	set mean [expr {double($sum) / $n}]

	# Median
	if {$min == $max} {
	    set median $min
	    set middle $min
	} else {
	    set median 0
	    foreach {p count} $h s $cdf255 {
		if {$s <= 127} continue
		set median $p
		break
	    }
	    set middle [expr {($min+$max)/2}]
	}

	# Variance
	# http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Compensated_variant
	set sum2 0
	set sumc 0
	foreach {p count} $h {
	    if {!$count} continue
	    set x [expr {$p - $mean}]
	    set sum2 [expr {$sum2 + $count * $x * $x}]
	    set sumc [expr {$sumc + $count * $x}]
	}
	set variance [expr {($sum2 - $sumc**2/$n)/($n - 1)}]
	set stddev   [expr {sqrt($variance)}]

	# Save the channel statistics
	lappend stat(channel) $c [dict create        \
			    min       $min  \
			    max       $max   \
			    middle    $middle \
			    median    $median \
			    mean      $mean    \
			    stddev    $stddev   \
			    variance  $variance \
			    histogram $h       \
			    hf        $hf     \
			    cdf       $cdf    \
			    cdf255    $cdf255 \
			  ]
	# geom mean, stddev
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

    return [crimp read tcl grey8 [list $pixels]]
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

    return [crimp join 2rgb \
		[crimp read tcl grey8 [list $r]] \
		[crimp read tcl grey8 [list $g]] \
		[crimp read tcl grey8 [list $b]]]
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

    return [crimp join 2rgba \
		[crimp read tcl grey8 [list $r]] \
		[crimp read tcl grey8 [list $g]] \
		[crimp read tcl grey8 [list $b]] \
		[crimp read tcl grey8 [list $a]]]
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

    return [crimp join 2hsv \
		[crimp read tcl grey8 [list $h]] \
		[crimp read tcl grey8 [list $s]] \
		[crimp read tcl grey8 [list $v]]]
}

# # ## ### ##### ######## #############
## Tables and maps.
## For performance we should memoize results.
## This is not needed to just get things working howver.

proc ::crimp::map {args} {
    return [read tcl grey8 [list [table {*}$args]]]
}

proc ::crimp::mapof {table} {
    return [read tcl grey8 [list $table]]
}

namespace eval ::crimp::table {
    namespace export {[a-z]*}
    namespace ensemble create
}

# NOTE: From now on the use of the builtin 'eval' command in the table
# namespace requires '::eval'.
proc ::crimp::table::eval {args} {
    lassign [ProcessWrap args 1 cmdprefix] wrap cmdprefix
    if {$wrap} {
	return [EvalWrap $cmdprefix]
    } else {
	return [EvalSaturate $cmdprefix]
    }
}

proc ::crimp::table::ProcessWrap {argv n usage} {
    upvar 1 $argv args
    array set opt [cmdline::getoptions args {
	{wrap 0 {}}
    }]
    if {[llength $args] != $n} {
	return -code error "wrong#args: Expected ?-wrap bool? $usage"
    }
    return [list $opt(wrap) {*}$args]
}

proc ::crimp::table::EvalWrap {cmdprefix} {
    for {set i 0} {$i < 256} {incr i} {
	lappend table [WRAP [expr {round([uplevel #0 [list {*}$cmdprefix $i]])}]]
    }
    return $table
}

proc ::crimp::table::EvalSaturate {cmdprefix} {
    for {set i 0} {$i < 256} {incr i} {
	lappend table [CLAMP [expr {round([uplevel #0 [list {*}$cmdprefix $i]])}]]
    }
    return $table
}

proc ::crimp::table::compose {f g} {
    # f and g are tables! representing functions, not command
    # prefixes.
    return [eval [list apply {{f g x} {
	# z = f(g(x))
	return [lindex $f [lindex $g $x]]
    }} $f $g]]
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

    #EvalSaturate [list ::apply {{y i} {expr {(($i/255.0) ** $y)*255.0}}} $y]

    for {set i 0} {$i < 256} {incr i} {
	lappend table [CLAMP [expr {round ((($i/255.0) ** $y)*255.0)}]]
    }
    return $table
}

proc ::crimp::table::degamma {y} {
    # Note: gamma operates in range [0..1], our data is [0..255]. We
    # have to scale down before applying the gamma, then scale back.

    set dy [expr {1.0/$y}]
    #EvalSaturate [list ::apply {{dy i} {expr {(($i/255.0) ** $dy)*255.0}}} $dy]

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
    #EvalSaturate [list ::apply {{r i} {expr {$r*sqrt($i)}}} $r]

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
    #EvalSaturate [list ::apply {{c i} {expr {$c*log(1+$i)}}} $r]

    # i = 1..256 instead of 0..255 i.e. 1+x is implied by the change
    # in the iteration range.
    for {set i 1} {$i < 257} {incr i} {
	lappend table [CLAMP [expr {round($c*log($i))}]]
    }
    return $table
}

proc ::crimp::table::linear {args} {
    lassign [ProcessWrap args 2 {gain offset}] wrap gain offset
    set cmdprefix [list ::apply {{gain offset i} {
	expr {double($gain) * $i + double($offset)}
    }} $gain $offset]
    if {$wrap} {
	return [EvalWrap $cmdprefix]
    } else {
	return [EvalSaturate $cmdprefix]
    }
}

proc ::crimp::table::stretch {min max} {
    # min => 0, max => 255, linear interpolation between them.
    #
    #     gain*max+offs = 255
    #     gain*min+offs = 0        <=> gain*min = 0-offs
    # <=> gain(max-min) = 255-0  | <=> offs = -gain*min
    # <=> GAIN = 255/(max-min)
    # 

    set gain [expr {255.0*($max - $min)}]
    set offs [expr {- ($min * $gain)}]
    return [linear $gain $offs]
}

namespace eval ::crimp::table::threshold {
    namespace export *
    namespace ensemble create
}

# [below T] <=> (x < T) <=> [invert [above T]]
# [above T] <=> (x >= T)

proc ::crimp::table::threshold::below {threshold} {
    for {set x 0} {$x < 256} {incr x} {
	lappend table [expr {($x < $threshold) ? 0 : 255}]
    }
    return $table
}

proc ::crimp::table::threshold::above {threshold} {
    for {set x 0} {$x < 256} {incr x} {
	lappend table [expr {($x < $threshold) ? 255 : 0}]
    }
    return $table
}

# [inside  Tmin Tmax] <=> (Tmin < x)  && (x < Tmax) <=> [invert [outside Tmin Tmax]],
# [outside Tmin Tmax] <=> (x <= Tmin) || (x >= Tmax)

proc ::crimp::table::threshold::inside {min max} {
    for {set x 0} {$x < 256} {incr x} {
	lappend table [expr {($min < $x) && ($x < $max) ? 0 : 255}]
    }
    return $table
}

proc ::crimp::table::threshold::outside {min max} {
    for {set x 0} {$x < 256} {incr x} {
	lappend table [expr {($min < $x) && ($x < $max) ? 255 : 0}]
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

# # ## ### ##### ######## #############

namespace eval ::crimp::table::quantize {
    namespace export *
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

    return [crimp::table::QuantizeCore $n $p \
		[crimp::FIT \
		     [crimp::CUMULATE [dict values $h]] \
		     255]]
}

proc ::crimp::table::QuantizeCore {n p cdf} {
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

    foreach pv [crimp::table::identity] sum $cdf {
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

# # ## ### ##### ######## #############

proc ::crimp::TypeOf {image} {
    return [namespace tail [type $image]]
}

proc ::crimp::K {x y} {
    return $x
}

# # ## ### ##### ######## #############

namespace eval ::crimp {
    namespace export type width height dimensions channels cut
    namespace export read write convert join flip split table
    namespace export invert solarize gamma degamma remap map
    namespace export wavy psychedelia matrix blank filter crop
    namespace export alpha histogram max min screen add pixel
    namespace export subtract difference multiply pyramid mapof
    namespace export downsample upsample decimate interpolate
    namespace export kernel expand threshold gradient effect
    namespace export statistics rotate montage morph integrate
    namespace export fft square resize
    #
    namespace ensemble create
}

# # ## ### ##### ######## #############
return
