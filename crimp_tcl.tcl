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

# # ## ### ##### ######## #############
## Read is done via sub methods, one per format to read from.
#
## Ditto write, convert, and join, one per destination format. Note
## that for write and convert the input format is determined
## automatically from the image.

namespace eval ::crimp::read {
    namespace export *
    namespace ensemble create
    variable fun
    foreach fun [::crimp::List read_*] {
	proc [::crimp::P $fun] {detail} [string map [list @ $fun] {
	    @ $detail
	}]
    }
    unset fun
}

namespace eval ::crimp::write {
    namespace export *
    namespace ensemble create
    variable fun
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
    unset fun
}

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
	rgb {
	    if {[llength $args]} {
		while {[llength $args] < 3} {
		    lappend args [lindex $args end]
		}
	    }
	}
	hsv {
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

proc ::crimp::split {image} {
    set type [TypeOf $image]
    if {![Has split_$type]} {
	return -code error "Unable to split images of type \"$type\""
    }
    return [split_$type $image]
}

# # ## ### ##### ######## #############

proc ::crimp::blank {type args} {
    if {![Has blank_$type]} {
	return -code error "Unable to create blank images of type \"$type\""
    }

    # Extend the set of channel values if not enough were specified,
    # by setting to them to BLACK or TRANSPARENT, respectively.

    switch -- $type {
	rgb {
	    if {[llength $args]} {
		while {[llength $args] < 3} {
		    lappend args 0
		}
	    }
	}
	hsv {
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

    return [blank_$type {*}$args]
}

# # ## ### ##### ######## #############

proc ::crimp::setalpha {image mask} {
    set itype [TypeOf $image]
    set mtype [TypeOf $mask]
    set f     setalpha_${itype}_$mtype
    if {![Has $f]} {
	return -code error "Setting the alpha channel is not supported for images of type \"$itype\" and mask of type \"$mtype\""
    }
    return [$f $image $mask]
}

# # ## ### ##### ######## #############

proc ::crimp::blend {fore back alpha} {
    set ftype [TypeOf $fore]
    set btype [TypeOf $back]
    set f     alpha_blend_${ftype}_$btype
    if {![Has $f]} {
	return -code error "Blend is not supported for a foreground of type \"$ftype\" and a background of type \"$btype\""
    }
    return [$f $fore $back [table::CLAMP $alpha]]
}

# # ## ### ##### ######## #############

proc ::crimp::over {fore back} {
    set ftype [TypeOf $fore]
    set btype [TypeOf $back]
    set f     alpha_over_${ftype}_$btype
    if {![Has $f]} {
	return -code error "Over is not supported for a foreground of type \"$ftype\" and a background of type \"$btype\""
    }
    return [$f $fore $back]
}

# # ## ### ##### ######## #############

proc ::crimp::add {a b {scale 1} {offset 0}} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]
    set f     add_${atype}_$btype
    if {![Has $f]} {
	return -code error "Add is not supported for the combination of \"$atype\" and \"$btype\""
    }
    return [$f $a $b $scale $offset]
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
    set f     difference_${atype}_$btype
    if {![Has $f]} {
	return -code error "Difference is not supported for the combination of \"$atype\" and \"$btype\""
    }
    return [$f $a $b]
}

# # ## ### ##### ######## #############

proc ::crimp::multiply {a b} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]
    set f     multiply_${atype}_$btype
    if {![Has $f]} {
	return -code error "Multiply is not supported for the combination of \"$atype\" and \"$btype\""
    }
    return [$f $a $b]
}

# # ## ### ##### ######## #############
## min aka 'darker' as the less brighter of each pixel is chosen.

proc ::crimp::min {a b} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]
    set f     min_${atype}_$btype
    if {![Has $f]} {
	return -code error "Min is not supported for the combination of \"$atype\" and \"$btype\""
    }
    return [$f $a $b]
}

# # ## ### ##### ######## #############
## max aka 'lighter' as the brighter of each pixel is chosen.

proc ::crimp::max {a b} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]
    set f     max_${atype}_$btype
    if {![Has $f]} {
	return -code error "Max is not supported for the combination of \"$atype\" and \"$btype\""
    }
    return [$f $a $b]
}

# # ## ### ##### ######## #############
## This operation could be done at this level, using a combination of
## 'multiply' and 'invert'. Doing it in C on the other hand avoids the
## three temporary images of such an implementation.

proc ::crimp::screen {a b} {
    set atype [TypeOf $a]
    set btype [TypeOf $b]
    set f     screen_${atype}_$btype
    if {![Has $f]} {
	return -code error "Screen is not supported for the combination of \"$atype\" and \"$btype\""
    }
    return [$f $a $b]
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

# # ## ### ##### ######## #############

proc ::crimp::TypeOf {image} {
    return [namespace tail [type $image]]
}

# # ## ### ##### ######## #############

namespace eval ::crimp {
    namespace export type width height dimensions channels
    namespace export read write convert join flip split table
    namespace export invert solarize gamma degamma remap map
    namespace export wavy psychedelia matrix blend over blank
    namespace export setalpha histogram max min screen add
    namespace export subtract difference multiply
    #
    namespace ensemble create
}

# # ## ### ##### ######## #############
return
