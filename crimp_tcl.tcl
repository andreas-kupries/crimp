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
    set type [TypeOf $image]
    if {![Has invert_$type]} {
	return -code error "Unable to invert images of type \"$type\""
    }
    return [invert_$type $image]
}

proc ::crimp::map {image args} {
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
		    lappend args [identitymap]
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

proc ::crimp::identitymap {} {
    variable identity
    if {![info exists identity]} {
	for {set i 0} {$i < 256} {incr i} {
	    lappend map $i
	}
	set identity [crimp read tcl [list $map]]
    }
    return $identity
}

# # ## ### ##### ######## #############

proc ::crimp::TypeOf {image} {
    return [namespace tail [type $image]]
}

# # ## ### ##### ######## #############

namespace eval ::crimp {
    namespace export type width height dimensions
    namespace export read write convert join flip
    namespace export invert map split identitymap
    namespace ensemble create
}

# # ## ### ##### ######## #############
return
