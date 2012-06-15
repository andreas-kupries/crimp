# -*- tcl -*-
# # ## ### ##### ######## ############# #####################
##
# A number of synthetic images of various types and other helper
# functions specific to crimp.

proc types {}  { return {grey8 grey16 grey32 rgb rgba hsv float fpcomplex} }
proc greys {}  { return {grey8 grey16 grey32} }
proc floats {} { return {float fpcomplex} }

proc t_ramp {} {
    for {set i 0} {$i < 256} {incr i} {
	lappend ramp $i
    }
    list $ramp
}

proc t_grey8 {} {
    return [trim {
	{ 0  1  2  3  4}
	{ 5  6  7  8  9}
	{10 11 12 13 14}
	{15 16 17 18 19}
	{20 21 22 23 24}
    }]
}

proc t_grey16 {} {
    return [trim {
	{ 0  1  2  3  4}
	{ 5  6  7  8  9}
	{10 11 12 13 14}
	{15 16 17 18 19}
	{20 21 22 23 24}
    }]
}

proc t_grey32 {} {
    return [trim {
	{ 0  1  2  3  4}
	{ 5  6  7  8  9}
	{10 11 12 13 14}
	{15 16 17 18 19}
	{20 21 22 23 24}
    }]
}

proc t_rgb {} {
    return [trim {
	{{ 0  1  2} {15 20 25} {30 31 32} {57 58 59} {60 69 74}}
	{{ 3  4  5} {16 21 26} {41 42 33} {56 55 54} {68 61 70}}
	{{ 6  7  8} {17 22 27} {40 43 34} {51 52 53} {73 67 62}}
	{{ 9 10 11} {18 23 28} {39 44 35} {50 49 48} {71 63 66}}
	{{12 13 14} {19 24 29} {38 37 36} {45 46 47} {64 65 72}}
    }]
}

proc t_rgba {} {
    return [trim {
	{{ 0  1  2 75} {15 20 25 84} {30 31 32 85} {57 58 59 86} {60 69 74 87}}
	{{ 3  4  5 76} {16 21 26 83} {41 42 33 90} {56 55 54 89} {68 61 70 88}}
	{{ 6  7  8 77} {17 22 27 82} {40 43 34 91} {51 52 53 98} {73 67 62 97}}
	{{ 9 10 11 78} {18 23 28 81} {39 44 35 92} {50 49 48 99} {71 63 66 96}}
	{{12 13 14 79} {19 24 29 80} {38 37 36 93} {45 46 47 94} {64 65 72 95}}
    }]
}

proc t_hsv {} {
    return [trim {
	{{ 0  1  2} {15 20 25} {30 31 32} {57 58 59} {60 69 74}}
	{{ 3  4  5} {16 21 26} {41 42 33} {56 55 54} {68 61 70}}
	{{ 6  7  8} {17 22 27} {40 43 34} {51 52 53} {73 67 62}}
	{{ 9 10 11} {18 23 28} {39 44 35} {50 49 48} {71 63 66}}
	{{12 13 14} {19 24 29} {38 37 36} {45 46 47} {64 65 72}}
    }]
}

proc t_float {} {
    return [F %.1f {
	{ 0  1  2  3  4}
	{ 5  6  7  8  9}
	{10 11 12 13 14}
	{15 16 17 18 19}
	{20 21 22 23 24}
    }]
}

proc t_fpcomplex {} {
    return [F %.1f {
	{{ 0  1} {15 20} {30 31} {57 58} {60 69}}
	{{ 3  4} {16 21} {41 42} {56 55} {68 61}}
	{{ 6  7} {17 22} {40 43} {51 52} {73 67}}
	{{ 9 10} {18 23} {39 44} {50 49} {71 63}}
	{{12 13} {19 24} {38 37} {45 46} {64 65}}
    }]
}

# # ## ### ##### ######## ############# #####################

proc ramp {} { crimp read tcl grey8 [t_ramp] }

proc grey8  {} { crimp read tcl grey8  [t_grey8]  }
proc grey16 {} { crimp read tcl grey16 [t_grey16] }
proc grey32 {} { crimp read tcl grey32 [t_grey32] }

proc rgb  {} { crimp read tcl rgb  [t_rgb]  }
proc rgba {} { crimp read tcl rgba [t_rgba] }
proc hsv  {} { crimp read tcl hsv  [t_hsv]  }

proc float     {} { crimp read tcl float     [t_float]     }
proc fpcomplex {} { crimp read tcl fpcomplex [t_fpcomplex] }

# # ## ### ##### ######## ############# #####################

proc fliph {p} { lmap lreverse $p }
proc flipv {p} { lreverse $p }

proc fliptp {p} {
    set w [llength [lindex $p 0]]    
    set h [llength $p]
    set out {}
    for {set x 0} {$x < $w} {incr x} {
	set row {}
	for {set y 0} {$y < $h} {incr y} {
	    lappend row [lindex $p $y $x]
	}
	lappend out $row
    }
    return $out
}
proc fliptv {p} { fliph [fliptp [fliph $p]] }

proc trim {str} {
    join [lmap {apply {{s} {
	set s [string trim $s]
	regsub -all {\s+} $s { } s
	regsub -all {\{\s} $s "\{" s
	return $s
    }}} [split [string trim $str] \n]] \n
}

proc bw {tclimage} {
    string map {{ } {}} [join [string map {1.0 * 0.0 . 255 * 0 .} $tclimage] \n]
}

proc cstat {stat key chan} {
    dict get $stat channel $chan $key
}

proc normstat {s} {
    dict for {k v} $s {
	if {$k ne "channel"} continue
	dict for {c cv} $v {
	    foreach key {mean middle variance stddev} {
		dict set cv $key [F %.2f [dict get $cv $key]]
	    }
	    dict set v $c $cv
	}
	dict set s $k $v
    }
    return $s
}

proc astcl {i} {
    # Treat as list, and replace the binary pixel data with the nested-list tcl representation.
    lreplace $i end end [join [crimp write 2string tcl $i] \n]
}

proc astclf {digits i} {
    # Treat as list, and replace the binary pixel data with the nested-list tcl representation.
    lreplace $i end end [join [F %.${digits}f [crimp write 2string tcl $i]] \n]
}

proc iconst {t x y w h p} {
    list crimp::image::$t $x $y $w $h {} [trim $p]
}

proc lmap {f list} {
    set res {}
    foreach x $list {
	lappend res [{*}$f $x]
    }
    return $res
}

proc F {fmt pixels} {
    set newpixels {}
    foreach row $pixels {
	set newrow {}
	foreach cell $row {
	    if {[llength $cell] > 1} {
		set newcell {}
		foreach c $cell {
		    lappend newcell [format $fmt $c]
		}
	    } else {
		set newcell [format $fmt $cell]
	    }
	    lappend newrow $newcell
	}
	lappend newpixels $newrow
    }
    return $newpixels
}

proc iota {n} {
    set res {}
    for {set i 0} {$i < $n} {incr i} {
	lappend res $i
    }
    return $res
}

# Use in the label of testcases to show their location when the label
# is printed. This is usually done because the test failed.
proc origin {} {
    if {[catch {
	array set _ [info frame -1]
    }]} return
    if {![info exists _(file)]} return
    if {![info exists _(line)]} return
    return (@[file tail $_(file)]:$_(line))
}

# # ## ### ##### ######## ############# #####################
return
