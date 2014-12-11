# -*- tcl -*-
# # ## ### ##### ######## ############# #####################
##
# A number of synthetic images of various types and other helper
# functions specific to crimp.

package require struct::matrix

proc types {}  { return {grey8 grey16 grey32 rgb rgba hsv float fpcomplex} }
proc greys {}  { return {grey8 grey16 grey32} }
proc floats {} { return {float fpcomplex} }

proc t_ramp {} {
    for {set i 0} {$i < 256} {incr i} {
	lappend ramp $i
    }
    list $ramp
}

proc t_sample {} {
    return [trim {
	{ 0.2 1.1 2.0 3.4 4.3}
	{ 1.3 2.2 3.1 4.0 0.4}
	{ 2.4 3.3 4.2 0.1 1.0}
	{ 3.0 4.4 0.3 1.2 2.1}
	{ 4.1 0.0 1.4 2.3 3.2}
    }]
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

proc t_3x3identity {} {
    return [F %.1f {
	{1 0 0}
	{0 1 0}
	{0 0 1}
    }]
}

proc t_3x3test {} {
    return [F %.1f {
	{1 0 5}
	{0 1 2}
	{0 0 1}
    }]
}

proc t_3x3idtrans {} {
    return [F %.1f {
	{0 0 1}
	{0 1 0}
	{1 0 0}
    }]
}

proc t_3x3testb {} {
    return [F %.1f {
	{0 3 0}
	{2 0 4}
	{0 5 0}
    }]
}

proc t_cross {} {
    return [trim {
	{1 0 0 0 7}
	{0 2 0 9 0}
	{0 0 3 0 0}
	{0 8 0 4 0}
	{6 0 0 0 5}
    }]
}

proc t_cross2 {} {
    return [trim {
	{1 255 255 255 7}
	{255 2 255 9 255}
	{255 255 3 255 255}
	{255 8 255 4 255}
	{6 255 255 255 5}
    }]
}

# # ## ### ##### ######## ############# #####################

proc ramp   {} { crimp read tcl grey8 [t_ramp]   }
proc sample {} { crimp read tcl float [t_sample] }

proc grey8  {} { crimp read tcl grey8  [t_grey8]  }
proc grey16 {} { crimp read tcl grey16 [t_grey16] }
proc grey32 {} { crimp read tcl grey32 [t_grey32] }

proc rgb  {} { crimp read tcl rgb  [t_rgb]  }
proc rgba {} { crimp read tcl rgba [t_rgba] }
proc hsv  {} { crimp read tcl hsv  [t_hsv]  }

proc float     {} { crimp read tcl float     [t_float]     }
proc double    {} { crimp read tcl double    [t_float]     }
proc fpcomplex {} { crimp read tcl fpcomplex [t_fpcomplex] }

proc g8  {cmd} { crimp read tcl grey8  [$cmd] }
proc g16 {cmd} { crimp read tcl grey16 [$cmd] }
proc g32 {cmd} { crimp read tcl grey32 [$cmd] }

# # ## ### ##### ######## ############# #####################
## Standard transform matrices

proc mid    {} { crimp read tcl float [t_3x3identity] }
proc midt   {} { crimp read tcl float [t_3x3idtrans] }
proc mtest  {} { crimp read tcl float [t_3x3test] }
proc mtestb {} { crimp read tcl float [t_3x3testb] }

proc dmid    {} { crimp read tcl double [t_3x3identity] }
proc dmidt   {} { crimp read tcl double [t_3x3idtrans] }
proc dmtest  {} { crimp read tcl double [t_3x3test] }
proc dmtestb {} { crimp read tcl double [t_3x3testb] }

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

proc decode_transform {actual} {
    # Validate that actual is a transform.
    # (tag + embedded 3x3 float image)
    if {[llength $actual] != 2} { error "bad transform: length 2 expected" }
    lassign $actual tag image
    if {$tag ne "crimp/transform"} { error "bad transform: bad tag $tag" }
    if {[llength $image] != 7} { error "bad transform: length 7 expected" }
    lassign $image type x y w h m p
    if {$type ne "crimp::image::double"} { error "bad transform: bad type $type" }
    if {$x != 0}  { error "bad transform: bad origin x" }
    if {$y != 0}  { error "bad transform: bad origin y" }
    if {$w != 3}  { error "bad transform: bad width" }
    if {$h != 3}  { error "bad transform: bad height" }
    if {$m ne {}} { error "bad transform: bad meta" }
    # Basic validation ok. Now unpack the pixels.
    return [join [crimp write 2string tcl $image]]
}

proc astcl {i} {
    # Treat as list, and replace the binary pixel data with the nested-list tcl representation.
    if {![crimp width $i] || ![crimp height $i]} {
	return [lreplace $i end end [crimp write 2string tcl $i]]
    }
    return [lreplace $i end end]\n[format-pix [crimp width $i] [crimp write 2string tcl $i]]
}

proc astclf {digits i} {
    if {[string match {crimp/transform *} $i]} {
	return [lreplace $i end end [astclf $digits [lindex $i end]]]
    }

    if {![crimp width $i] || ![crimp height $i]} {
	# Treat as list, and replace the binary pixel data with the nested-list tcl representation.
	return [lreplace $i end end [F %.${digits}f [crimp write 2string tcl $i]]]
    }

    # Treat as list, and replace the binary pixel data with the nested-list tcl representation.
    return [lreplace $i end end]\n[format-pix [crimp width $i] [F %.${digits}f [crimp write 2string tcl $i]]]
}

proc iconst {t x y w h p} {
    if {!$w || !$h} {
	return [list crimp::image::$t $x $y $w $h {} [trim $p]]
    }
    return [list crimp::image::$t $x $y $w $h {}]\n[format-pix $w [split [trim $p] \n]]
}

proc gconst {x y args} {
    set h   [llength $args]
    set w   [string length [lindex $args 0]]
    set pix [join [split [string trim [join $args \n]] {}] { }]
    list $x $y $w $h [string map {_ 0 . 255} $pix]
}

proc format-pix {w rows} {
    struct::matrix M
    M add columns $w
    foreach row $rows { M add row $row }
    set data [M format 2string]
    M destroy
    return $data
}

proc tconst {p} {
    list crimp/transform [iconst double 0 0 3 3 $p]
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

# # ## ### ##### ######## ############# #####################
## Check two lists of numbers for component-wise numeric equality
## (1) To within N digits after the decimal point.
##     Instantiated for N in {2, 4}
## (2) To within machine accuracy

proc matchNdigits {n expected actual} {
    if {$n <= 0} {
	set x 1e[expr {- $n}]
    } else {
	set x 1e-$n
    }
    foreach a $actual e $expected {
        if {abs($a-$e) > $x} {
	    #puts MF|$a|$e|[expr {abs($a-$e)}]
	    return 0
        }
    }
    return 1
}

proc matchdigits {expected actual} {
    math::constants::constants eps
    foreach a $actual e $expected {
        if {abs($a-$e) > $eps} {
	    #puts MF|$a|$e|[expr {abs($a-$e)}]|$eps
	    return 0
        }
    }
    return 1
}

customMatch -1digits {matchNdigits -1}
customMatch 0digits {matchNdigits 0}
customMatch 2digits {matchNdigits 2}
customMatch 4digits {matchNdigits 4}
customMatch 8digits {matchNdigits 8}
customMatch 9digits {matchNdigits 9}
customMatch 10digits {matchNdigits 10}
customMatch 12digits {matchNdigits 12}
customMatch 13digits {matchNdigits 13}
customMatch 14digits {matchNdigits 14}
customMatch epsilon matchdigits

# # ## ### ##### ######## ############# #####################
## Various 2D vector arithmetic primitives.
## Avoiding a dependency on tcllib's math::geometry.

# Create point from coordinates
proc p {x y} { list $x $y }

# Length of point as vector (from (0,0))
proc pnorm {p} {
    lassign $p x y
    expr {hypot($x,$y)}
}

proc polar {c} {
    math::constants::constants radtodeg
    # Convert cartesian point C to polar form (magnitude+angle).
    lassign $c x y
    list [expr {hypot($x,$y)}] [expr {$radtodeg * atan2($y,$x)}]
}

proc cartesian {p} {
    math::constants::constants degtorad
    # Convert polar-form P to cartesian C.
    lassign $p m a
    set a [expr {$a * $degtorad}]
    list [expr {$m * cos ($a)}] [expr {- $m * sin ($a)}]
}

# Vector difference of two points.
proc p- {a b} {
    lassign $a ax ay
    lassign $b bx by
    p [expr {$ax - $bx}] [expr {$ay - $by}]
}

# Vector addition of two points
proc p+ {a b} {
    lassign $a ax ay
    lassign $b bx by
    p [expr {$ax + $bx}] [expr {$ay + $by}]
}

# Partial vector addition/translation, in single axis, and with separate deltas.
proc p+x {a delta} {
    lassign $a ax ay
    p [expr {$ax + $delta}] $ay
}

proc p+y {a delta} {
    lassign $a ax ay
    p $ax [expr {$ay + $delta}]
}

proc p+xy {a dx dy} {
    lassign $a ax ay
    p [expr {$ax + $dx}] [expr {$ay + $dy}]
}

# Vector scaling (multiplication) by a factor.
proc p*s {p f} {
    lassign $p x y
    p [expr {$x * $f}] [expr {$y * $f}]
}

# Element-wise vector multiplication
proc p* {p f} {
    lassign $p px py
    lassign $f fx fy
    p [expr {$px * $fx}] [expr {$py * $fy}]
}

# Vector scaling (division) by a factor.
proc p/s {p f} {
    lassign $p x y
    p [expr {$x / double($f)}] [expr {$y / double($f)}]
}

# Element-wise vector division
proc p/ {a b} {
    lassign $a ax ay
    lassign $b bx by
    p \
	[expr {double($ax) / double($bx)}] \
	[expr {double($ay) / double($by)}]
}

# Generate orthogonal vector
proc portho {p} {
    lassign $p x y
    p $y [expr {- $x}]
}

# # ## ### ##### ######## ############# #####################
## Easy random numbers, uniformly distributed in a range.
## Plus convenience commands for angles and 2d-points

proc rand {a b} { expr {$a + rand()*($b - $a)} }

proc rand/0 {a b} {
    while {1} {
	set x [rand $a $b]
	if {$x != 0} { return $x }
    }
}

proc arand {} {
    rand -360 360
}

proc prand {} {
    p [rand -300 300] [rand -300 300]
}

proc prand/0 {} {
    p [rand/0 -300 300] [rand/0 -300 300]
}

# # ## ### ##### ######## ############# #####################
## geometric constructions for randomized testing.

proc a-translation {} {
    set p [prand]    ; # A point to translate
    set d [prand]    ; # A translation vector
    set r [p+ $p $d] ; # The translation result.

    # point, result, and translation parameters
    list $p $r $d
}

proc a-scaling {} {
    set p [prand]    ; # A point to scale, relative to 0
    set f [prand/0]  ; # Scale factors
    set r [p* $p $f] ; # The scaling result, relative to 0
    set c [prand]    ; # New center of scaling.

    set p  [p+ $c $p]
    set r  [p+ $c $r]

    # point, result, and scaling parameters
    list $p $r $f $c
}

proc a-reflection {} {
    math::constants::constants eps

    # To set up the reflection we choose a line to reflect about via
    # two points A, B (taking care to reject 0-length lines). The
    # line-vector and its orthogonal are an orthonormal basis of the
    # 2D plane with in which the reflection is about the y-axis
    # (A--B), making it a simple change of the sign. Assuming we
    # choose A as the null of the coordinate system. This then allows
    # us to easily create two points in the coordinate system which
    # are reflections of each other. Conversion into the regular
    # coordinate system then gives us a point plus reflection result
    # we can test the transform against.

    while {1} {
	set a [prand] ; # The line to reflect about.
	set b [prand] ; # This shall be the y-axis of
	#             ; # a custom coordinate system.
	set ya [p- $b $a]

	# Iterate until we have something which is not 0.
	set l [pnorm $ya]
	if {$l < $eps} continue
	# Normalize y-axis vector to length 1.
	set ya [p/s $ya $l]
	break
    }
    set xa [portho $ya] ;# The x-axis vector is orthogonal to y.

    # Now we can generate a point in the new coordinate system whose
    # reflection is easy to compute also (in the custom coordinates),
    # just flip the sign on the x-coordinate. Convert both to the
    # regular coordinate system.

    set u [rand -100 100] ; # x, custom
    set v [rand -100 100] ; # y, custom

    # Point and reflection, relative to custom coordinate null (== a).
    set p [p+ $a [p+ [p*s $xa          $u]   [p*s $ya $v]]]
    set r [p+ $a [p+ [p*s $xa [expr {- $u}]] [p*s $ya $v]]]

    # Side note: It would be useful to dump all the points and lines
    # as a DIAgram, for visualization.

    list $p $r $a $b
}

proc a-rotation {} {
    # Random rotations around arbitrary points.  We set them up from
    # scratch, as two vectors on the scaled unit circle, and
    # translated to the chosen center point.

    set theta1 [arand]
    set theta2 [arand]
    set scale  [rand/0 -10 10]
    while {abs($scale) < 0.5} { set scale [rand/0 -10 10] }
    # |scale| >= 0.5 ensured

    set center [prand]
    set dtheta [expr {$theta2 - $theta1}]

    set p [p+ $center [cartesian [p $scale $theta1]]]
    set r [p+ $center [cartesian [p $scale $theta2]]]

    list $p $r $center $dtheta
}

proc an-origin-rotation {} {
    # Random rotations around the origin.
    # Non random: Initial point (P) lies on the x-axis.

    set center {0 0}
    set theta  [arand]
    set len    [rand 0.5 200]

    set p [p $len 0]
    set r [cartesian [p $len $theta]]

    list $p $r $center $theta
}

proc a-shear {} {
    set p [prand] ; # A point to shear

    set sx [rand -5 5]
    set sy [rand -5 5]

    #set s [prand] ; # The shear factors per axis.

    lassign $p px py
    #lassign $s sx sy

    set r [p [expr {$px + $sy*$py}] [expr {$py + $sx*$px}]]

    list $p $r [p $sx $sy]
}

# TODO: ensure proper __convex__ quadrilateral.
# Maybe generate by types ?
# --- http://en.wikipedia.org/wiki/Quadrilateral
# - Square, Rhombus
# - Rectangle, Rhomboid
# - Parallelogram
# - Kite
# - Trapezoid, Trapezium
# - Convex

proc a-quad-square {} {
    # Square, axis-aligned.
    # p -------l- p+(l,0)
    # |           |
    # |l          |l
    # |           |
    # p+(0,l) -l- p+(l,l)
    set p [prand]
    set l [arand]
    list $p [p+x $p $l] [p+xy $p $l $l] [p+y $p $l]
}

proc a-quad-rhombus {} {
    # Rhombus (sheared square), axis-aligned
    # p -------l- p+(l,0)
    # \           \
    #  \l          \l
    #   \           \
    #    p+(o,l) -l- p+(l+o,l)
    # -o-
    set p  [prand]
    set l  [arand]
    set o  [arand]
    set lo [expr {$l + $o}]
    list $p [p+x $p $l] [p+xy $p $lo $l] [p+xy $p $o $l]
}

proc a-quad-rectangle {} {
    # Rectangle, axis-aligned.
    # p ------dx--- p+(dx,0)
    # |             |
    # |dy           |dy
    # |             |
    # p+(0,dy) -dx- p+(dx,dy)
    set p  [prand]
    set dx [arand]
    set dy [arand]
    list $p [p+x $p $dx] [p+xy $p $dx $dy] [p+y $p $dy]
}

proc a-quad-rhomboid {} {
    # Rhomboid (sheared rectangle), axis-aligned.
    # p ------dx--- p+(dx,0)
    # \             \
    #  \dy           \dy
    #   \             \
    #    p+(o,dy) -dx- p+(dx+o,dy)
    # -o-
    set p   [prand]
    set dx  [arand]
    set dy  [arand]
    set o   [arand]
    set dxo [expr {$dx + $o}]
    list $p [p+x $p $dx] [p+xy $p $dxo $dy] [p+xy $p $o $dy]
}

proc a-quad-trapezoid {} {
    # Trapezoid, axis-aligned
    # p ----------------dx- p+(dx,0)
    #  \                   /
    #   \dy               /dy
    #    \               /
    #     p+(o1,dy) --- p+(dx+o2,dy)
    # -o1-

    set p   [prand]
    set dx  [expr {3 * [arand]}]
    set dy  [arand]
    set o1  [arand]
    set o2  [arand]
    set dxo [expr {$dx + $o2}]
    set res [list $p [p+x $p $dx] [p+xy $p $dxo $dy] [p+xy $p $o1 $dy]]
    #puts P\t[join $res \nP\t]
    set res
}

# # ## ### ##### ######## ############# #####################
return
