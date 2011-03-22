# -*- tcl -*- 
# # ## ### ##### ######## #############
# Writing images in the PGM format (Portable Grey Map).
# See http://en.wikipedia.org/wiki/Netpbm_format

namespace eval ::crimp {}

proc ::crimp::writes_pgm-plain_grey8 {image} {
    # assert TypeOf (image) == grey8
    set res "P2 [crimp dimensions $image] 255"
    foreach c [::split [crimp pixel $image] {}] {
	binary scan $c cu g
	append res " " $g
    }
    return $res
}

proc ::crimp::writes_pgm-raw_grey8 {image} {
    # assert TypeOf (image) == grey8
    return "P5 [crimp dimensions $image] 255 [crimp pixel $image]"
}

proc ::crimp::writec_pgm-plain_grey8 {chan image} {
    # assert TypeOf (image) == grey8
    puts -nonewline $chan "P2 [crimp dimensions $image] 255"
    foreach c [::split [crimp pixel $image] {}] {
	binary scan $c cu g
	puts -nonewline $chan " $g"
    }
    puts $chan ""
    return
}

proc ::crimp::writec_pgm-raw_grey8 {chan image} {
    # assert TypeOf (image) == grey8
    puts -nonewline $chan "P5 [crimp dimensions $image] 255 "
    puts -nonewline $chan [crimp pixel $image]
    return
}

# # ## ### ##### ######## #############

proc ::crimp::writes_pgm-plain_rgb {image} {
    # assert TypeOf (image) == rgb
    return [writes_pgm-plain_grey8 [crimp convert 2grey8 $image]]
}

proc ::crimp::writes_pgm-raw_rgb {image} {
    # assert TypeOf (image) == rgb
    return [writes_pgm-raw_grey8 [crimp convert 2grey8 $image]]
}

proc ::crimp::writec_pgm-plain_rgb {chan image} {
    # assert TypeOf (image) == rgb
    writec_pgm-plain_grey8 $chan [crimp convert 2grey8 $image]
    return
}

proc ::crimp::writec_pgm-raw_rgb {chan image} {
    # assert TypeOf (image) == rgb
    writec_pgm-raw_grey8 $chan [crimp convert 2grey8 $image]
    return
}

# # ## ### ##### ######## #############

proc ::crimp::writes_pgm-plain_rgba {image} {
    # assert TypeOf (image) == rgba
    return [writes_pgm-plain_grey8 [crimp convert 2grey8 $image]]
}

proc ::crimp::writes_pgm-raw_rgba {image} {
    # assert TypeOf (image) == rgba
    return [writes_pgm-raw_grey8 [crimp convert 2grey8 $image]]
}

proc ::crimp::writec_pgm-plain_rgba {chan image} {
    # assert TypeOf (image) == rgba
    writec_pgm-plain_grey8 $chan [crimp convert 2grey8 $image]
    return
}

proc ::crimp::writec_pgm-raw_rgba {chan image} {
    # assert TypeOf (image) == rgba
    writec_pgm-raw_grey8 $chan [crimp convert 2grey8 $image]
    return
}

# # ## ### ##### ######## #############

proc ::crimp::writes_pgm-plain_hsv {image} {
    # assert TypeOf (image) == hsv
    return [writes_pgm-plain_grey8 [crimp convert 2grey8 [crimp convert 2rgb $image]]]
}

proc ::crimp::writes_pgm-raw_hsv {image} {
    # assert TypeOf (image) == hsv
    return [writes_pgm-raw_grey8 [crimp convert 2grey8 [crimp convert 2rgb $image]]]
}

proc ::crimp::writec_pgm-plain_hsv {chan image} {
    # assert TypeOf (image) == hsv
    writec_pgm-plain_grey8 $chan [crimp convert 2grey8 [crimp convert 2rgb $image]]
    return
}

proc ::crimp::writec_pgm-raw_hsv {chan image} {
    # assert TypeOf (image) == hsv
    writec_pgm-raw_grey8 $chan [crimp convert 2grey8 [crimp convert 2rgb $image]]
    return
}

# # ## ### ##### ######## #############
return
