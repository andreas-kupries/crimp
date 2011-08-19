# -*- tcl -*- 
## Tcl level definitions for crimp::ppm.
# # ## ### ##### ######## ############# #####################
## Requirements

package require crimp ; # Using "crimp convert xxx"

# # ## ### ##### ######## ############# #####################

## Writing images in the PPM format (Portable Pix Map).
## Reference
##	http://en.wikipedia.org/wiki/Netpbm_format

# # ## ### ##### ######## ############# #####################
## Reading PPM images is handled at the C level, and the command is
## directly fit into the ::crimp::read ensemble.

# # ## ### ##### ######## ############# #####################
## Writing PPM images is handled by providing the command sets
## expected by the standard 'write 2xxx' commands in the
## "crimp::core".

proc ::crimp::write::Str_ppm-plain_rgb {image} {
    # assert TypeOf (image) == rgb
    set res "P3 [::crimp dimensions $image] 255"
    foreach c [::split [::crimp pixel $image] {}] {
	binary scan $c cu g
	append res " " $g
    }
    return $res
}

proc ::crimp::write::Str_ppm-raw_rgb {image} {
    # assert TypeOf (image) == rgb
    return "P6 [::crimp dimensions $image] 255 [::crimp pixel $image]"
}

proc ::crimp::write::Chan_ppm-plain_rgb {chan image} {
    # assert TypeOf (image) == rgb
    puts -nonewline $chan "P3 [::crimp dimensions $image] 255"
    foreach c [::split [::crimp pixel $image] {}] {
	binary scan $c cu g
	puts -nonewline $chan " $g"
    }
    return
}

proc ::crimp::write::Chan_ppm-raw_rgb {chan image} {
    # assert TypeOf (image) == rgb
    puts -nonewline $chan "P6 [::crimp dimensions $image] 255 "
    puts -nonewline $chan [::crimp pixel $image]
    return
}

# # ## ### ##### ######## ############# #####################

proc ::crimp::write::Str_ppm-plain_rgba {image} {
    # assert TypeOf (image) == rgba
    return [Str_ppm-plain_rgb [::crimp convert 2rgb $image]]
}

proc ::crimp::write::Str_ppm-raw_rgba {image} {
    # assert TypeOf (image) == rgba
    return [Str_ppm-raw_rgb [::crimp convert 2rgb $image]]
}

proc ::crimp::write::Chan_ppm-plain_rgba {chan image} {
    # assert TypeOf (image) == rgba
    Chan_ppm-plain_rgb $chan [::crimp convert 2rgb $image]
    return
}

proc ::crimp::write::Chan_ppm-raw_rgba {chan image} {
    # assert TypeOf (image) == rgba
    Chan_ppm-raw_rgb $chan [::crimp convert 2rgb $image]
    return
}

# # ## ### ##### ######## ############# #####################

proc ::crimp::write::Str_ppm-plain_hsv {image} {
    # assert TypeOf (image) == hsv
    return [Str_ppm-plain_rgb [::crimp convert 2rgb $image]]
}

proc ::crimp::write::Str_ppm-raw_hsv {image} {
    # assert TypeOf (image) == hsv
    return [Str_ppm-raw_rgb [::crimp convert 2rgb $image]]
}

proc ::crimp::write::Chan_ppm-plain_hsv {chan image} {
    # assert TypeOf (image) == hsv
    Chan_ppm-plain_rgb $chan [::crimp convert 2rgb $image]
    return
}

proc ::crimp::write::Chan_ppm-raw_hsv {chan image} {
    # assert TypeOf (image) == hsv
    Chan_ppm-raw_rgb $chan [::crimp convert 2rgb $image]
    return
}

# # ## ### ##### ######## ############# #####################

proc ::crimp::write::Str_ppm-plain_grey8 {image} {
    # assert TypeOf (image) == grey8
    return [Str_ppm-plain_rgb [::crimp convert 2rgb $image]]
}

proc ::crimp::write::Str_ppm-raw_grey8 {image} {
    # assert TypeOf (image) == grey8
    return [Str_ppm-raw_rgb [::crimp convert 2rgb $image]]
}

proc ::crimp::write::Chan_ppm-plain_grey8 {chan image} {
    # assert TypeOf (image) == grey8
    Chan_ppm-plain_rgb $chan [::crimp convert 2rgb $image]
    return
}

proc ::crimp::write::Chan_ppm-raw_grey8 {chan image} {
    # assert TypeOf (image) == grey8
    Chan_ppm-raw_rgb $chan [::crimp convert 2rgb $image]
    return
}

# # ## ### ##### ######## ############# #####################
return
