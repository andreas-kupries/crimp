# -*- tcl -*-
# # ## ### ##### ######## ############# #####################
##
# A number of synthetic images of various types and other helper
# functions specific to crimp.

proc ramp {} {
    for {set i 0} {$i < 256} {incr i} {
	lappend ramp $i
    }

    crimp read tcl grey8 [list $ramp]
}

proc grey8 {} {
    crimp read tcl grey8 {
	{ 0  1  2  3  4}
	{ 5  6  7  8  9}
	{10 11 12 13 14}
	{15 16 17 18 19}
	{20 21 22 23 24}
    }
}

proc grey16 {} {
    crimp read tcl grey16 {
	{ 0  1  2  3  4}
	{ 5  6  7  8  9}
	{10 11 12 13 14}
	{15 16 17 18 19}
	{20 21 22 23 24}
    }
}

proc grey32 {} {
    crimp read tcl grey32 {
	{ 0  1  2  3  4}
	{ 5  6  7  8  9}
	{10 11 12 13 14}
	{15 16 17 18 19}
	{20 21 22 23 24}
    }
}

proc float {} {
    crimp read tcl float {
	{ 0  1  2  3  4}
	{ 5  6  7  8  9}
	{10 11 12 13 14}
	{15 16 17 18 19}
	{20 21 22 23 24}
    }
}

proc rgb {} {
    crimp read tcl rgb {
	{{ 0  1  2} {15 20 25} {30 31 32} {57 58 59} {60 69 74}}
	{{ 3  4  5} {16 21 26} {41 42 33} {56 55 54} {68 61 70}}
	{{ 6  7  8} {17 22 27} {40 43 34} {51 52 53} {73 67 62}}
	{{ 9 10 11} {18 23 28} {39 44 35} {50 49 48} {71 63 66}}
	{{12 13 14} {19 24 29} {38 37 36} {45 46 47} {64 65 72}}
    }
}

proc rgba {} {
    crimp read tcl rgba {
	{{ 0  1  2 75} {15 20 25 84} {30 31 32 85} {57 58 59 86} {60 69 74 87}}
	{{ 3  4  5 76} {16 21 26 83} {41 42 33 90} {56 55 54 89} {68 61 70 88}}
	{{ 6  7  8 77} {17 22 27 82} {40 43 34 91} {51 52 53 98} {73 67 62 97}}
	{{ 9 10 11 78} {18 23 28 81} {39 44 35 92} {50 49 48 99} {71 63 66 96}}
	{{12 13 14 79} {19 24 29 80} {38 37 36 93} {45 46 47 94} {64 65 72 95}}
    }
}

proc hsv {} {
    crimp read tcl hsv {
	{{ 0  1  2} {15 20 25} {30 31 32} {57 58 59} {60 69 74}}
	{{ 3  4  5} {16 21 26} {41 42 33} {56 55 54} {68 61 70}}
	{{ 6  7  8} {17 22 27} {40 43 34} {51 52 53} {73 67 62}}
	{{ 9 10 11} {18 23 28} {39 44 35} {50 49 48} {71 63 66}}
	{{12 13 14} {19 24 29} {38 37 36} {45 46 47} {64 65 72}}
    }
}

proc fpcomplex {} {
    crimp read tcl fpcomplex {
	{{ 0  1} {15 20} {30 31} {57 58} {60 69}}
	{{ 3  4} {16 21} {41 42} {56 55} {68 61}}
	{{ 6  7} {17 22} {40 43} {51 52} {73 67}}
	{{ 9 10} {18 23} {39 44} {50 49} {71 63}}
	{{12 13} {19 24} {38 37} {45 46} {64 65}}
    }
}

# # ## ### ##### ######## ############# #####################

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

# # ## ### ##### ######## ############# #####################
return
