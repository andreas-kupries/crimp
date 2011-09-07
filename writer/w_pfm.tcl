# -*- tcl -*- 
# # ## ### ##### ######## #############
# Writing images as portable float map, in analogy to Portable Grey Maps, aka PGM.
# See http://en.wikipedia.org/wiki/Netpbm_format
# The type codes used for PFM are FAKE, i.e. made up.

namespace eval ::crimp {}

proc ::crimp::writes_pfm-plain_float {image} {
    # assert TypeOf (image) == float
    set res "F2 [crimp dimensions $image]"

    binary scan [crimp pixel $image] f* values
    foreach v $values {
	append res " " $v
    }
    return $res
}

proc ::crimp::writes_pfm-raw_float {image} {
    # assert TypeOf (image) == float
    return "F5 [crimp dimensions $image] [crimp pixel $image]"
}

proc ::crimp::writec_pfm-plain_float {chan image} {
    # assert TypeOf (image) == float
    puts -nonewline $chan "F2 [crimp dimensions $image] "

    binary scan [crimp pixel $image] f* values
    foreach v $values {
	puts -nonewline $chan " $v"
    }
    return
}

proc ::crimp::writec_pfm-raw_float {chan image} {
    # assert TypeOf (image) == float
    puts -nonewline $chan "F5 [crimp dimensions $image] "
    puts -nonewline $chan [crimp pixel $image]
    return
}

# # ## ### ##### ######## #############

proc ::crimp::writes_pfm-plain_fpcomplex {image} {
    # assert TypeOf (image) == fpcomplex
    set res "C2 [crimp dimensions $image]"

    binary scan [crimp pixel $image] f* values
    foreach v $values {
	append res " " $v
    }
    return $res
}

proc ::crimp::writes_pfm-raw_fpcomplex {image} {
    # assert TypeOf (image) == fpcomplex
    return "C5 [crimp dimensions $image] [crimp pixel $image]"
}

proc ::crimp::writec_pfm-plain_fpcomplex {chan image} {
    # assert TypeOf (image) == fpcomplex
    puts -nonewline $chan "C2 [crimp dimensions $image] "

    binary scan [crimp pixel $image] f* values
    foreach v $values {
	puts -nonewline $chan " $v"
    }
    return
}

proc ::crimp::writec_pfm-raw_fpcomplex {chan image} {
    # assert TypeOf (image) == fpcomplex
    puts -nonewline $chan "C5 [crimp dimensions $image] "
    puts -nonewline $chan [crimp pixel $image]
    return
}

# # ## ### ##### ######## #############
return
