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

# # ## ### ##### ######## #############

proc ::crimp::invert {image} {
    set type [TypeOf $image]
    if {![Has invert_$type]} {
	return -code error "Unable to invert images of type \"$type\""
    }
    return [invert_$type $image]
}

proc ::crimp::split {image} {
    set type [TypeOf $image]
    if {![Has split_$type]} {
	return -code error "Unable to split images of type \"$type\""
    }
    return [split_$type $image]
}

# # ## ### ##### ######## #############

proc ::crimp::TypeOf {image} {
    return [namespace tail [type $image]]
}

# # ## ### ##### ######## #############

namespace eval ::crimp {
    namespace export type width height dimensions read write convert invert split join
    namespace ensemble create
}

# # ## ### ##### ######## #############
return
