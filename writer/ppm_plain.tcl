# -*- tcl -*-
# # ## ### ##### ######## #############
# Writing images to the plain (ASCII) sub-format of the PPM format
# (Portable Pix Map).
# See http://en.wikipedia.org/wiki/Netpbm_format

namespace eval ::crimp::write {}

proc ::crimp::write::2ppmplain {path image} {
    set type [crimp::TypeOf $image]

    if {$type ne "rgb"} {
	# Strip the alpha channel, or transform the colorspace, before
	# running the result through the writer.
	set image [crimp convert 2rgb $image]
    }

    # Note how the internal pixel data is already in the sequence
    # needed by the format, only conversion to ASCII is needed.

    set res "P3 [crimp dimensions $image] 255"
    foreach c [split [crimp pixel $image]] {
	binary scan $c cu g
	append res " " $g
    }

    fileutil::writeFile $path $res
    return
}

# # ## ### ##### ######## #############
return
