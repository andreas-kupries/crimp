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
    return [lrange [split [namespace tail $fqn] _] 1 end]
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
	proc 2[lindex [::crimp::P $fun] end] {dst image} \
	    [string map [list @ [lindex [::crimp::P $fun] end]] {
		set type [::crimp::TypeOf $image]
		if {![::crimp::Has write_${type}_@]} {
		    return -code error "Unable to write images of type \"$type\" to \"@\""
		}
		return [::crimp::write_${type}_@ $dst $image]
	    }]
    }
    unset fun
}

namespace eval ::crimp::convert {
    namespace export *
    namespace ensemble create
    variable fun
    foreach fun [::crimp::List convert_*] {
	proc 2[lindex [::crimp::P $fun] end] {image} \
	    [string map [list @ [lindex [::crimp::P $fun] end]] {
		set type [::crimp::TypeOf $image]
		if {![::crimp::Has convert_${type}_@]} {
		    return -code error "Unable to convert images of type \"$type\" to \"@\""
		}
		return [::crimp::convert_${type}_@ $image]
	    }]
    }
    unset fun
}

namespace eval ::crimp::join {
    namespace export *
    namespace ensemble create
    variable fun
    foreach fun [::crimp::List join_*] {
	proc 2[::crimp::P $fun] {args} [string map [list @ $fun] {
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
    for {set i 0} {$i < 256} {incr i} {
	lappend table [CLAMP [expr {round ($i ** $y)}]]
    }
    return $table
}

proc ::crimp::table::degamma {y} {
    set dy [expr {1.0/$y}]
    for {set i 0} {$i < 256} {incr i} {
	lappend table [CLAMP [expr {round ($i ** $dy)}]]
    }
    return $table
}

proc ::crimp::table::gain {gain {bias 0}} {
    for {set x 0} {$x < 256} {incr x} {
	lappend table [CLAMP [expr {round(double($gain) * $x + double($bias))}]]
    }
    return $table
}

# # ## ### ##### ######## #############

proc ::crimp::table::CLAMP {x} {
    if {$x < 0  } { return 0   }
    if {$x > 255} { return 255 }
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
    #
    namespace ensemble create
}

# # ## ### ##### ######## #############
return
