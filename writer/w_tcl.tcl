# -*- tcl -*- 
# # ## ### ##### ######## #############
# Writing images in the Tcl format (List of lists of pixels (list of values))

namespace eval ::crimp {}

proc ::crimp::writes_tcl_grey8 {image} {
    # assert TypeOf (image) == grey8
    set w [crimp width $image]
    set res {}
    set line {}
    set n $w
    foreach c [::split [crimp pixel $image] {}] {
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

proc ::crimp::writes_tcl_rgb {image} {
    # assert TypeOf (image) == rgb
    set w [crimp width $image]
    set res {}
    set line {}
    set n $w
    foreach {r g b} [::split [crimp pixel $image] {}] {
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

proc ::crimp::writes_tcl_rgba {image} {
    # assert TypeOf (image) == rgba
    set w [crimp width $image]
    set res {}
    set line {}
    set n $w
    foreach {r g b a} [::split [crimp pixel $image] {}] {
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

proc ::crimp::writes_tcl_hsv {image} {
    # assert TypeOf (image) == hsv
    set w [crimp width $image]
    set res {}
    set line {}
    set n $w
    foreach {h s v} [::split [crimp pixel $image] {}] {
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
return
