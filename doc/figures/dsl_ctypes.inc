# -*- tcl -*- tcl.tk//DSL diagram//EN//1.0

set boxheight [7 mm]
set boxwidth  [4 cm]
set movelength [1 cm]
set linelength [1 cm]


proc field {type name args} {
    set text " $type"
    if {$name ne {}} {
	append text "  $name"
    }
    set $name [box {*}$args]
    group { text with w at [last w] rjust $text }
    return
}

proc sep {args} {
    global sepcounter
    set v sep[incr sepcounter]
    global $v
    set $v [box fillcolor black height [2 mm] {*}$args]
}

proc pointer {anchor dir args} {
    # anchor reinterpretation, first element is name of the variable
    # containing the object handle <=> name of the object in the
    # diagram.

    set path [lassign $anchor main]
    upvar 1 $main obj
    set anchor [$obj {*}$path $dir]

    # Pull out the path the arrow the takes, or, if not specified a
    # default based on the chosen direction.

    set script     [lindex $args end]
    set directions [lrange $args 0 end-1]
    if {![llength $directions]} {
	set directions $dir
    }
    set path {}
    foreach d $directions {
	lappend path then $d
    }

    group {
        circle rad [1 mm] with $dir at $anchor fillcolor black
	$dir
	arrow at $anchor {*}$path
	uplevel 1 $script
    }
    return [last arrow end]
}

proc xpointer {anchor dir args} {
    # anchor reinterpretation, first element is name of the variable
    # containing the object handle <=> name of the object in the
    # diagram.

    set path [lassign $anchor main]
    upvar 1 $main obj
    set anchor [$obj {*}$path $dir]

    group {
        circle rad [1 mm] with $dir at $anchor fillcolor black
	$dir
	arrow at $anchor {*}$args
    }
    return [last arrow end]
}

proc static {args} {
    {*}$args fillcolor lightblue
}

proc allocated {args} {
    {*}$args fillcolor lightyellow
}

proc type {name args} {
    global $name
    set $name [box text $name {*}$args]
}

proc struct {name script args} {
    global $name
    set $name [block {
	south
	set L [box fillcolor green]
	group { text with w at [last w] " $name" }
	eval $script

	set Le [$L e]
	set Lw [$L w]
	set Ln [$L n]
	set Ls [$L s]

    } with Lw {*}$args]
    return [set $name]
}

proc cstring {args} { box "\"...\\0\"" {*}$args }

proc carray {type n args} {
    set x [block {
	south
	set L [box fillcolor green]
	group { text with w at [last w] { []} }
	field $type \[0\]
	field $type \[1\]
	box text ...
	field $type \[$n-1\]

	set Le [$L e]
	set Lw [$L w]
	set Ln [$L n]
	set Ls [$L s]

    } with Lw {*}$args]
    group {
	box with nw at [last nw] height [last height]
    }
    return $x
}
