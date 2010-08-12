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
	proc [::crimp::P $fun] {detail} [string map [list @ $fun] {
	    @ $detail
	}]
    }

    # Readers implemented as Tcl procedures.
    foreach file [glob -nocomplain -directory $dir/reader *.tcl] {
	source $file
    }
} ::crimp::read} [file dirname [file normalize [info script]]]

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
		if {![::crimp::Has write_@_${type}]} {
		    return -code error "Unable to write images of type \"$type\" to \"@\""
		}
		return [::crimp::write_@_${type} $dst $image]
	    }]
    }

    # Writers implemented as Tcl procedures.
    foreach file [glob -nocomplain -directory $dir/writer *.tcl] {
	source $file
    }
} ::crimp::write} [file dirname [file normalize [info script]]]

namespace eval ::crimp::convert {
    namespace export *
    namespace ensemble create
    variable fun
    foreach fun [::crimp::List convert_*] {
	proc [lindex [::crimp::P $fun] 0] {image} \
	    [string map [list @ [lindex [::crimp::P $fun] 0]] {
		set type [::crimp::TypeOf $image]
		if {![::crimp::Has convert_@_${type}]} {
		    return -code error "Unable to convert images of type \"$type\" to \"@\""
		}
		return [::crimp::convert_@_${type} $image]
	    }]
    }
    unset fun
}

namespace eval ::crimp::join {
    namespace export *
    namespace ensemble create
    variable fun
    foreach fun [::crimp::List join_*] {
	proc [::crimp::P $fun] {args} [string map [list @ $fun] {
	    return [@ {*}$args]
	}]
    }
    unset fun
}

namespace eval ::crimp::flip {
    namespace export *
    namespace ensemble create
    variable fun
    foreach fun [::crimp::List flip_*] {
	proc [lindex [::crimp::P $fun] 0] {image} \
	    [string map [list @ [lindex [::crimp::P $fun] 0]] {
		set type [::crimp::TypeOf $image]
		if {![::crimp::Has flip_@_$type]} {
		    return -code error "Unable to flip @ images of type \"$type\""
		}
		return [::crimp::flip_@_$type $image]
	    }]
    }
    unset fun
}


# # ## ### ##### ######## #############

proc ::crimp::invert {image} {
    remap $image [map invers]
}

proc ::crimp::solarize {image n} {
    remap $image [map solarize $n]
}

proc ::crimp::threshold-le {image n} {
    remap $image [map threshold-le $n]
}

proc ::crimp::threshold-ge {image n} {
    remap $image [map threshold-ge $n]
}

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

proc ::crimp::downsample {image factor} {
    set type [TypeOf $image]
    set f downsample_$type
    if {![Has $f]} {
	return -code error "Unable to downsample images of type \"$type\""
    }

    return [$f $image $factor]
}

proc ::crimp::upsample {image factor} {
    set type [TypeOf $image]
    set f upsample_$type
    if {![Has $f]} {
	return -code error "Unable to upsample images of type \"$type\""
    }

    return [$f $image $factor]
}

proc ::crimp::decimate {image factor kernel} {
    # Combines downsampling with a pre-processing step applying a
    # low-pass filter to avoid aliasing of higher image frequencies.

    # We assume that the low-pass filter is separable, and the kernel
    # is the 1-D horizontal form of it. We compute the vertical form
    # on our own, transposing the kernel.

    # NOTE: This implementation, while easy conceptually, is not very
    # efficient, because it does the filtering on the input image,
    # before downsampling.

    # FUTURE: Write C level primitive integrating filter and sampler,
    # computing the filter only for the pixels which go into the
    # result.

    return [downsample \
		[convolve $image $kernel [kernel transpose $kernel]] \
		$factor]
}

proc ::crimp::interpolate {image factor kernel} {
    # Combines upsampling with a post-processing step applying a
    # low-pass filter to copies of the image at higher image
    # frequencies.

    # We assume that the low-pass filter is separable, and the kernel
    # is the 1-D horizontal form of it. We compute the vertical form
    # on our own, transposing the kernel.

    # NOTE: This implementation, while easy conceptually, is not very
    # efficient, because it does the filtering on the full output image,
    # after upsampling.

    # FUTURE: Write C level primitive integrating filter and sampler,
    # computing the filter only for the actually new pixels, and use
    # polyphase restructuring.

    # DANGER: This assumes that the filter, applied to the original
    # pixels leaves them untouched. I.e. scaled center weight is 1.
    # The easy implementation here does not have this assumption.

    return [convolve [upsample $image $factor] \
		$kernel [kernel transpose $kernel]]
}

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
    set ftype [crimp::TypeOf $fore]
    set btype [crimp::TypeOf $back]
    set f     alpha_blend_${ftype}_$btype
    if {![crimp::Has $f]} {
	return -code error "Blend is not supported for a foreground of type \"$ftype\" and a background of type \"$btype\""
    }
    return [crimp::$f $fore $back [table::CLAMP $alpha]]
}

# # ## ### ##### ######## #############

proc ::crimp::alpha::over {fore back} {
    set ftype [crimp::TypeOf $fore]
    set btype [crimp::TypeOf $back]
    set f     alpha_over_${ftype}_$btype
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
    namespace export *
    namespace ensemble create
}

# # ## ### ##### ######## #############

proc ::crimp::filter::convolve {image args} {
    # args = ?-border spec? kernel...

    set type [crimp::TypeOf $image]
    set fc convolve_${type}
    if {![crimp::Has $fc]} {
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
		set value [lindex $at $args]
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

    # kernel = list (kw kh kernelimage scale)
    # Kernel x in [-kw ... kw], 2*kw+1 values
    # Kernel y in [-kh ... kh], 2*kh+1 values
    # Shrinkage by 2*kw, 2*kh. Compensate using the chosen border type.

    foreach kernel $args {
	lassign $kernel kw kh K scale
	set image [crimp::$fc [crimp::$fe $image $kw $kh $kw $kh {*}$values] $K $scale]
    }

    return $image
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
		set value [lindex $at $args]
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

proc ::crimp::kernel::make {kernelmatrix {scale {}}} {
    # auto-scale, if needed
    if {[llength [info level 0]] < 3} {
	set scale 0
	foreach r $kernelmatrix { foreach v $r { incr scale $v } }
    }

    set kernel [crimp read tcl $kernelmatrix]

    lassign [crimp::dimensions $kernel] w h

    if {!($w % 2) || !($h % 2)} {
	# Keep in sync with the convolve primitives.
	# FUTURE :: Have an API to set the messages used by the primitives.
	return -code error "bad kernel dimensions, expected odd size"
    }

    set kw [expr {$w/2}]
    set kh [expr {$h/2}]

    return [list $kw $kh $kernel $scale]
}

proc ::crimp::kernel::transpose {kernel} {
    lassign $kernel w h K scale
    set Kt [crimp flip transpose $K]
    return [list $h $w $Kt $scale]
}

# # ## ### ##### ######## #############
## Image pyramids

namespace eval ::crimp::pyramid {
    namespace export *
    namespace ensemble create
}

proc crimp::pyramid::run {image steps stepfun} {
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

proc crimp::pyramid::gauss {image steps} {
    lrange [run $image $steps [list ::apply {{kernel image} {
	set low [crimp decimate $image 2 $kernel]
	return [list $low $low]
    }} [crimp kernel make {{1 4 6 4 1}}]]] 0 end-1
}

proc crimp::pyramid::laplace {image steps} {
    run $image $steps [list ::apply {{kerneld kerneli image} {
	set low  [crimp decimate $image 2 $kerneld]
	set up   [crimp interpolate $low 2 $kerneli]

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

proc ::crimp::statistics {image} {
    array set stat {}

    # Basics
    set stat(channels)   [channels   $image]
    set stat(dimensions) [dimensions $image]
    set stat(height)     [height     $image]
    set stat(width)      [width      $image]
    set stat(type)       [TypeOf     $image]
    set stat(pixels)     [set n [expr {$stat(width) * $stat(height)}]]

    # Histogram and derived data, per channel.
    foreach {c h} [histogram $image] {
	#puts <$c>
	set hf     [dict values $h]
	#puts H|[llength $hf]||$hf
	set cdf    [CUMULATE $hf]
	#puts C|[llength $cdf]|$cdf
	set cdf255 [FIT $cdf 255]

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
	} else {
	    set median 0
	    foreach {p count} $h s $cdf255 {
		if {$s <= 127} continue
		set median $p
		break
	    }
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

	# Save the statistics
	set key [list channel $c]
	set stat($key) [dict create        \
			    min       $min  \
			    max       $max   \
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

# # ## ### ##### ######## #############
## Tables and maps.
## For performance we should memoize results.
## This is not needed to just get things working howver.

proc ::crimp::map {args} {
    return [read tcl [list [table {*}$args]]]
}

namespace eval ::crimp::table {
    namespace export *
    namespace ensemble create
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
    for {set i 0} {$i < 256} {incr i} {
	lappend table [CLAMP [expr {round ((($i/255.0) ** $y)*255.0)}]]
    }
    return $table
}

proc ::crimp::table::degamma {y} {
    # Note: gamma operates in range [0..1], our data is [0..255]. We
    # have to scale down before applying the gamma, then scale back.
    set dy [expr {1.0/$y}]
    for {set i 0} {$i < 256} {incr i} {
	lappend table [CLAMP [expr {round ((($i/255.0) ** $dy)*255.0)}]]
    }
    return $table
}

proc ::crimp::table::gain {gain {bias 0}} {
    for {set x 0} {$x < 256} {incr x} {
	lappend table [CLAMP [expr {round(double($gain) * $x + double($bias))}]]
    }
    return $table
}

proc ::crimp::table::gainw {gain {bias 0}} {
    for {set x 0} {$x < 256} {incr x} {
	lappend table [WRAP [expr {round(double($gain) * $x + double($bias))}]]
    }
    return $table
}

proc ::crimp::table::threshold-le {threshold} {
    for {set x 0} {$x < 256} {incr x} {
	lappend table [expr {($x <= $threshold) ? 0 : 255}]
    }
    return $table
}

proc ::crimp::table::threshold-ge {threshold} {
    for {set x 0} {$x < 256} {incr x} {
	lappend table [expr {($x >= $threshold) ? 0 : 255}]
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

# # ## ### ##### ######## #############

namespace eval ::crimp {
    namespace export type width height dimensions channels cut
    namespace export read write convert join flip split table
    namespace export invert solarize gamma degamma remap map
    namespace export wavy psychedelia matrix blank filter crop
    namespace export alpha histogram max min screen add
    namespace export subtract difference multiply pyramid
    namespace export downsample upsample decimate interpolate
    namespace export kernel expand threshold-le threshold-ge
    namespace export statistics
    #
    namespace ensemble create
}

# # ## ### ##### ######## #############
return
