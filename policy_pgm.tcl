# -*- tcl -*- 
## Tcl level definitions for crimp::pgm.
# # ## ### ##### ######## ############# #####################
## Requirements

package require crimp ; # Using "crimp convert xxx"

# # ## ### ##### ######## ############# #####################

## Writing images in the PGM format (Portable Grey Map).
## Reference
##	 http://en.wikipedia.org/wiki/Netpbm_format

# # ## ### ##### ######## ############# #####################
## Reading PPM images is handled at the C level, and the command is
## directly fit into the ::crimp::read ensemble.

# # ## ### ##### ######## ############# #####################
## Writing PPM images is handled by providing the command sets
## expected by the standard 'write 2xxx' commands in the
## "crimp::core".

proc ::crimp::write::Str_pgm-plain_grey8 {image} {
    # assert TypeOf (image) == grey8
    set res "P2 [::crimp dimensions $image] 255"
    foreach c [::split [::crimp pixel $image] {}] {
	binary scan $c cu g
	append res " " $g
    }
    return $res
}

proc ::crimp::write::Str_pgm-raw_grey8 {image} {
    # assert TypeOf (image) == grey8
    return "P5 [::crimp dimensions $image] 255 [::crimp pixel $image]"
}

proc ::crimp::write::Chan_pgm-plain_grey8 {chan image} {
    # assert TypeOf (image) == grey8
    puts -nonewline $chan "P2 [::crimp dimensions $image] 255"
    foreach c [::split [::crimp pixel $image] {}] {
	binary scan $c cu g
	puts -nonewline $chan " $g"
    }
    puts $chan ""
    return
}

proc ::crimp::write::Chan_pgm-raw_grey8 {chan image} {
    # assert TypeOf (image) == grey8
    puts -nonewline $chan "P5 [::crimp dimensions $image] 255 "
    puts -nonewline $chan [::crimp pixel $image]
    return
}

# # ## ### ##### ######## ############# #####################

proc ::crimp::write::Str_pgm-plain_rgb {image} {
    # assert TypeOf (image) == rgb
    return [Str_pgm-plain_grey8 [::crimp convert 2grey8 $image]]
}

proc ::crimp::write::Str_pgm-raw_rgb {image} {
    # assert TypeOf (image) == rgb
    return [Str_pgm-raw_grey8 [::crimp convert 2grey8 $image]]
}

proc ::crimp::write::Chan_pgm-plain_rgb {chan image} {
    # assert TypeOf (image) == rgb
    Chan_pgm-plain_grey8 $chan [::crimp convert 2grey8 $image]
    return
}

proc ::crimp::write::Chan_pgm-raw_rgb {chan image} {
    # assert TypeOf (image) == rgb
    Chan_pgm-raw_grey8 $chan [::crimp convert 2grey8 $image]
    return
}

# # ## ### ##### ######## ############# #####################

proc ::crimp::write::Str_pgm-plain_rgba {image} {
    # assert TypeOf (image) == rgba
    return [Str_pgm-plain_grey8 [::crimp convert 2grey8 $image]]
}

proc ::crimp::write::Str_pgm-raw_rgba {image} {
    # assert TypeOf (image) == rgba
    return [Str_pgm-raw_grey8 [::crimp convert 2grey8 $image]]
}

proc ::crimp::write::Chan_pgm-plain_rgba {chan image} {
    # assert TypeOf (image) == rgba
    Chan_pgm-plain_grey8 $chan [::crimp convert 2grey8 $image]
    return
}

proc ::crimp::write::Chan_pgm-raw_rgba {chan image} {
    # assert TypeOf (image) == rgba
    Chan_pgm-raw_grey8 $chan [::crimp convert 2grey8 $image]
    return
}

# # ## ### ##### ######## ############# #####################

proc ::crimp::write::Str_pgm-plain_hsv {image} {
    # assert TypeOf (image) == hsv
    return [Str_pgm-plain_grey8 [::crimp convert 2grey8 [::crimp convert 2rgb $image]]]
}

proc ::crimp::write::Str_pgm-raw_hsv {image} {
    # assert TypeOf (image) == hsv
    return [Str_pgm-raw_grey8 [::crimp convert 2grey8 [::crimp convert 2rgb $image]]]
}

proc ::crimp::write::Chan_pgm-plain_hsv {chan image} {
    # assert TypeOf (image) == hsv
    Chan_pgm-plain_grey8 $chan [::crimp convert 2grey8 [::crimp convert 2rgb $image]]
    return
}

proc ::crimp::write::Chan_pgm-raw_hsv {chan image} {
    # assert TypeOf (image) == hsv
    Chan_pgm-raw_grey8 $chan [::crimp convert 2grey8 [::crimp convert 2rgb $image]]
    return
}

# # ## ### ##### ######## ############# #####################
return
