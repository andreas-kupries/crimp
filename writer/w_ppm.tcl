# -*- tcl -*-
# # ## ### ##### ######## #############
# Writing images in the PPM format (Portable Pix Map).
# See http://en.wikipedia.org/wiki/Netpbm_format

namespace eval ::crimp {}

proc ::crimp::writes_ppm-plain_rgb {image} {
    # assert TypeOf (image) == rgb
    set res "P3 [crimp dimensions $image] 255"
    foreach c [::split [crimp pixel $image] {}] {
	binary scan $c cu g
	append res " " $g
    }
    return $res
}

proc ::crimp::writes_ppm-raw_rgb {image} {
    # assert TypeOf (image) == rgb
    return "P6 [crimp dimensions $image] 255 [crimp pixel $image]"
}

proc ::crimp::writec_ppm-plain_rgb {chan image} {
    # assert TypeOf (image) == rgb
    puts -nonewline $chan "P3 [crimp dimensions $image] 255"
    foreach c [::split [crimp pixel $image] {}] {
	binary scan $c cu g
	puts -nonewline $chan " $g"
    }
    return
}

proc ::crimp::writec_ppm-raw_rgb {chan image} {
    # assert TypeOf (image) == rgb
    puts -nonewline $chan "P6 [crimp dimensions $image] 255 "
    puts -nonewline $chan [crimp pixel $image]
    return
}

# # ## ### ##### ######## #############

proc ::crimp::writes_ppm-plain_rgba {image} {
    # assert TypeOf (image) == rgba
    return [writes_ppm-plain_rgb [crimp convert 2rgb $image]]
}

proc ::crimp::writes_ppm-raw_rgba {image} {
    # assert TypeOf (image) == rgba
    return [writes_ppm-raw_rgb [crimp convert 2rgb $image]]
}

proc ::crimp::writec_ppm-plain_rgba {chan image} {
    # assert TypeOf (image) == rgba
    writec_ppm-plain_rgb $chan [crimp convert 2rgb $image]
    return
}

proc ::crimp::writec_ppm-raw_rgba {chan image} {
    # assert TypeOf (image) == rgba
    writec_ppm-raw_rgb $chan [crimp convert 2rgb $image]
    return
}

# # ## ### ##### ######## #############

proc ::crimp::writes_ppm-plain_hsv {image} {
    # assert TypeOf (image) == hsv
    return [writes_ppm-plain_rgb [crimp convert 2rgb $image]]
}

proc ::crimp::writes_ppm-raw_hsv {image} {
    # assert TypeOf (image) == hsv
    return [writes_ppm-raw_rgb [crimp convert 2rgb $image]]
}

proc ::crimp::writec_ppm-plain_hsv {chan image} {
    # assert TypeOf (image) == hsv
    writec_ppm-plain_rgb $chan [crimp convert 2rgb $image]
    return
}

proc ::crimp::writec_ppm-raw_hsv {chan image} {
    # assert TypeOf (image) == hsv
    writec_ppm-raw_rgb $chan [crimp convert 2rgb $image]
    return
}

# # ## ### ##### ######## #############

proc ::crimp::writes_ppm-plain_grey8 {image} {
    # assert TypeOf (image) == grey8
    return [writes_ppm-plain_rgb [crimp convert 2rgb $image]]
}

proc ::crimp::writes_ppm-raw_grey8 {image} {
    # assert TypeOf (image) == grey8
    return [writes_ppm-raw_rgb [crimp convert 2rgb $image]]
}

proc ::crimp::writec_ppm-plain_grey8 {chan image} {
    # assert TypeOf (image) == grey8
    writec_ppm-plain_rgb $chan [crimp convert 2rgb $image]
    return
}

proc ::crimp::writec_ppm-raw_grey8 {chan image} {
    # assert TypeOf (image) == grey8
    writec_ppm-raw_rgb $chan [crimp convert 2rgb $image]
    return
}

# # ## ### ##### ######## #############
return
