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
## Importing images into the CRIMP eco-system is handled by the 'read'
## ensemble command. It will have one method per format, handling image
## data in that format. Here we just define the ensemble.
#
## A package implementing the importing of images stored in a file
## format FOO has to provide a command '::crimp::read::FOO', causing
## the ensemble to be automatically extended.

namespace eval ::crimp::read {
    namespace export {[a-z0-9]*}
    namespace ensemble create
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
## And declare the main ensemble, the umbrella under which all public
## commands will be made accessible. The 'C' child namespace is where
## any non-exported C-level primitives should be placed.

namespace eval ::crimp {
    namespace export {a-z*}
    namespace ensemble create

    namespace eval ::crimp::C {}
}

# # ## ### ##### ######## #############
return
