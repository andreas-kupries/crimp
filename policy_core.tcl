## -*- tcl -*-
## Policy script for the crimp::core.
# # ## ### ##### ######## ############# #####################
## Provides the extensibility hooks for image file format handling.

namespace eval ::crimp {}

# # ## ### ##### ######## ############# #####################
## General helpers for use by all packages built atop the core.

proc ::crimp::TypeOf {image} {
    return [namespace tail [type $image]]
}

proc ::crimp::K {x y} {
    return $x
}

# # ## ### ##### ######## ############# #####################

proc ::crimp::List {pattern} {
    return [info commands ::crimp::$pattern]
}

proc ::crimp::Has {name} {
    expr {[namespace which -command ::crimp::$name] ne {}}
}

proc ::crimp::P {fqn} {
    return [lrange [::split [namespace tail $fqn] _] 1 end]
}

# # ## ### ##### ######## ############# #####################

proc ::crimp::bbox {head args} {
    set bbox [geometry $head]
    foreach image $args {
	set bbox [bbox2 {*}$bbox {*}[geometry $image]]
    }
    return $bbox
}

# # ## ### ##### ######## ############# #####################

proc ::crimp::meta {cmd image args} {
    # The meta data as exposed through here is a dictionary. Thus we
    # expose all dictionary operations as submethods, with the
    # dictionary value/variable implied by the image.

    switch -exact -- $cmd {
	append - incr - lappend - set - unset {
	    set meta [C::meta_get $image]
	    dict $cmd meta {*}$args
	    return [C::meta_set [K $image [unset image]] $meta]
	}
	create {
	    return [C::meta_set [K $image [unset image]] [dict $cmd {*}$args]]
	}
	merge - remove - replace {
	    set meta [C::meta_get $image]
	    return [C::meta_set [K $image [unset image]] [dict $cmd $meta {*}$args]]
	}
	exists - get - info - keys - size - values {
	    return [dict $cmd [C::meta_get $image] {*}$args]
	}
	for {
	    return [uplevel 1 [list dict $cmd {*}[linsert $args 1 [C::meta_get $image]]]]
	}
	filter {
	    return [uplevel 1 [list dict $cmd [C::meta_get $image] {*}$args]]
	}
	default {
	    set x {append create exists filter for get incr info keys lappend merge remove replace set size unset values}
	    return -code error "Unknown method \"$cmd\", expected one of [linsert [::join $x {, }] end-1 or]"
	}
    }
}

# # ## ### ##### ######## ############# #####################
## Importing images into the CRIMP eco-system is handled by the 'read'
## ensemble command. It will have one method per format, handling image
## data in that format. Here we just define the ensemble, and a
## command for the most basic import (Tcl lists).
#
## A package implementing the importing of images stored in a file
## format FOO has to provide a command '::crimp::read::FOO', causing
## the ensemble to be automatically extended.

namespace eval ::crimp::read {
    namespace export {[a-z0-9]*}
    namespace ensemble create
}

proc ::crimp::read::tcl {format detail} {
    set fun read::Tcl_$format
    if {![::crimp::Has $fun]} {
	return -code error "Unable to generate images of type \"$format\" from Tcl values"
    }
    return [::crimp::$fun $detail]
}

# # ## ### ##### ######## #############

## Exporting images from the CRIMP eco-system is handled by the
## 'write' ensemble command. It defines three general methods for
## exporting an image to a string, a file, and a Tcl channel.
#
## A package implementing the exporting of image to the file format
## FOO based on the general method has to provide at least a set of
## commands matching '::crimp::write::Str_FOO_<imagetype>', writing
## images of the specified types to a string in the format FOO.
#
## It may also provide a set of commands matching
##'::crimp::write::Chan_FOO_<imagetype>' for writing to a channel.
#
## Any combination for which here is no command from this optional set
## will be handled by writing to a string and then writing this to the
## channel.
#
## Lastly, a package for a format is of course free to directly
## implement additional methods under the namespace ::crimp::write, if
## its operation doesn't fit under the umbrella of the general standard
## methods.

namespace eval ::crimp::write {
    namespace export {[a-z0-9]*}
    namespace ensemble create
}

::apply {{} {
    set le [string equal $::tcl_platform(byteOrder) littleEndian]
    variable ushort [expr {$le ? "s":"S"}]u
    variable ulong  [expr {$le ? "i":"I"}]u
} ::crimp::write}

proc ::crimp::write::2file {format path image} {
    set chan [open $path w]
    fconfigure $chan -encoding binary
    2chan $format $chan $image
    close $chan
    return
}

proc ::crimp::write::2chan {format chan image} {
    set type [::crimp::TypeOf $image]
    set fun  write::Chan_${format}_${type}

    if {![::crimp::Has $fun]} {
	puts -nonewline $chan [2string $format $image]
	return
    }
    ::crimp::$fun $chan $image
    return
}

proc ::crimp::write::2string {format image} {
    set type [::crimp::TypeOf $image]
    set fun  write::Str_${format}_${type}

    if {![::crimp::Has $fun]} {
	return -code error "Unable to write images of type \"$type\" to strings for \"$format\""
    }
    return [::crimp::$fun $image]
}

# # ## ### ##### ######## #############
# Writing images in the Tcl format (List of lists of pixels (list of values))

proc ::crimp::write::Str_tcl_grey8 {image} {
    # assert TypeOf (image) == grey8
    set w [::crimp::width $image]
    set res {}
    set line {}
    set n $w
    foreach c [::split [::crimp::pixel $image] {}] {
	binary scan $c cu g
	lappend line $g
	incr n -1
	if {$n > 0} continue
	lappend res $line
	set line {}
	set n $w
    }
    return $res
}

# # ## ### ##### ######## #############

proc ::crimp::write::Str_tcl_grey16 {image} {
    variable ushort
    # assert TypeOf (image) == grey16
    set w [::crimp::width $image]
    set res {}
    set line {}
    set n $w
    foreach {a b} [::split [::crimp::pixel $image] {}] {
	binary scan $a$b $ushort g
	lappend line $g
	incr n -1
	if {$n > 0} continue
	lappend res $line
	set line {}
	set n $w
    }
    return $res
}

# # ## ### ##### ######## #############

proc ::crimp::write::Str_tcl_grey32 {image} {
    variable ulong
    # assert TypeOf (image) == grey32
    set w [::crimp::width $image]
    set res {}
    set line {}
    set n $w
    foreach {a b c d} [::split [::crimp::pixel $image] {}] {
	binary scan $a$b$c$d $ulong g
	lappend line $g
	incr n -1
	if {$n > 0} continue
	lappend res $line
	set line {}
	set n $w
    }
    return $res
}

# # ## ### ##### ######## #############

proc ::crimp::write::Str_tcl_rgb {image} {
    # assert TypeOf (image) == rgb
    set w [::crimp::width $image]
    set res {}
    set line {}
    set n $w
    foreach {r g b} [::split [::crimp::pixel $image] {}] {
	binary scan $r cu r
	binary scan $g cu g
	binary scan $b cu b
	lappend line [list $r $g $b]
	incr n -1
	if {$n > 0} continue
	lappend res $line
	set line {}
	set n $w
    }
    return $res
}

# # ## ### ##### ######## #############

proc ::crimp::write::Str_tcl_rgba {image} {
    # assert TypeOf (image) == rgba
    set w [::crimp::width $image]
    set res {}
    set line {}
    set n $w
    foreach {r g b a} [::split [::crimp::pixel $image] {}] {
	binary scan $r cu r
	binary scan $g cu g
	binary scan $b cu b
	binary scan $a cu a
	lappend line [list $r $g $b $a]
	incr n -1
	if {$n > 0} continue
	lappend res $line
	set line {}
	set n $w
    }
    return $res
}

# # ## ### ##### ######## #############

proc ::crimp::write::Str_tcl_hsv {image} {
    # assert TypeOf (image) == hsv
    set w [::crimp::width $image]
    set res {}
    set line {}
    set n $w
    foreach {h s v} [::split [::crimp::pixel $image] {}] {
	binary scan $h cu h
	binary scan $s cu s
	binary scan $v cu v
	lappend line [list $h $s $v]
	incr n -1
	if {$n > 0} continue
	lappend res $line
	set line {}
	set n $w
    }
    return $res
}

# # ## ### ##### ######## #############
## And declare the main ensemble, the umbrella under which all public
## commands will be made accessible. The 'C' child namespace is where
## any non-exported C-level primitives should be placed.

namespace eval ::crimp {
    namespace export {[a-z]*}
    namespace ensemble create

    namespace eval ::crimp::C {}
}

# # ## ### ##### ######## #############
return
