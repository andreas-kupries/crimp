# -*- tcl -*-
# # ## ### ##### ######## #############
# Writing images to the plain (ASCII) sub-format of the PGM format
# (Portable Grey Map).
# See http://en.wikipedia.org/wiki/Netpbm_format

namespace eval ::crimp::write {}
proc ::crimp::write::2pgmplain {path image} {

    set type [crimp::TypeOf $image]
    if {$type ne "grey8"} {
	return -code error "expected image type grey8"
    }

    # Note how the internal pixel data is already in the sequence
    # needed by the format, only conversion to ASCII is needed.

    set res "P2 [crimp dimensions $image] 255"
    foreach c [split [crimp pixel $image] {}] {
	binary scan $c cu g
	append res " " $g
    }

    fileutil::writeFile $path $res
    return
}

# # ## ### ##### ######## #############
return
