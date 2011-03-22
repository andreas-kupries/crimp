# -*- tcl -*- 
# # ## ### ##### ######## #############
# Reader for strimj formatted images.
# See http://wiki.tcl.tk/_//search?S=strimj
# Code derived from http://wiki.tcl.tk/15325

namespace eval ::crimp::read::strimj {
    variable colors {
	{ } {0   0   0   0}
	@   {0   0   0   255}
	b   {0   0   255 255}
	g   {0   255 0   255}
	c   {0   255 255 255}
	r   {255 0   0   255}
	m   {255 0   255 255}
	o   {255 165 0   255}
	y   {255 255 0   255}
	.   {255 255 255 255}
    }
}

proc ::crimp::read::strimj {text {colormap {}}} {
    variable strimj::colors
    array set map $colors
    array set map $colormap

    set rr {} ; set ri {}
    set gr {} ; set gi {}
    set br {} ; set bi {}
    set ar {} ; set ai {}

    foreach line [split [string trimright $text \n] \n] {
	foreach pixel [split $line {}] {
	    lassign $map($pixel) r g b a
	    lappend rr $r
	    lappend gr $g
	    lappend br $b
	    lappend ar $a
	}

	lappend ri $rr ; set rr {}
	lappend gi $gr ; set gr {}
	lappend bi $br ; set br {}
	lappend ai $ar ; set ar {}
    }

   return [crimp join 2rgba \
	       [tcl grey8 $ri] \
	       [tcl grey8 $gi] \
	       [tcl grey8 $bi] \
	       [tcl grey8 $ai]]
}

# # ## ### ##### ######## #############
return
