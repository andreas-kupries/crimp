#!/bin/sh
# -*- tcl -*- \
exec tclsh "$0" ${1+"$@"}
# # ## ### ##### ######## ############# ######################
## Requisites

package require Tcl 8.5

# # ## ### ##### ######## ############# ######################
## Configuration

set simple_types {float grey32 grey16 grey8}
set multi_types  {rgb rgba fpcomplex}

array set accessor {
    float     {FLOATP v}
    grey32    {GREY32 v}
    grey16    {GREY16 v}
    grey8     {GREY8  v}
    hsv       {H h S s V v}
    rgb       {R r G g B b}
    rgba      {R r G g B b A a}
    fpcomplex {RE re IM im}
}

array set ctype {
    float     double
    grey32    int
    grey16    int
    grey8     int
    hsv       int
    rgb       int
    rgba      int
    fpcomplex double
}

# # ## ### ##### ######## ############# ######################
## Input

set basedir  [file dirname [file normalize [info script]]]
set template [apply {{template} {
    set c [open $template r]
    set data [read $c]
    close $c
    return $data
}} [file join $basedir unop_template.c]]

# # ## ### ##### ######## ############# ######################
## Generator core.

proc retrieve {type image zero {expand 0} {alpha {}}} {
    global ctype accessor
    upvar 1 lines lines
    set variables {}

    set vprefix _
    set guard   inside
    set ox      pxi
    set oy      pyi

    foreach {get var} $accessor($type) {
	lappend lines "$ctype($type) $vprefix$var = $guard ? $get ($image, $ox, $oy) : $zero;"
	lappend variables $vprefix$var
    }

    if {$expand} {
	set v [lindex $variables end]
	while {[llength $variables] < $expand} { lappend variables $v }
    }

    if {$alpha ne {}} {
	set var a
	lappend lines "$ctype($type) $vprefix$var = $guard ? OPAQUE : $zero;"
	lappend variables $vprefix$var
    }

    return $variables
}

proc assign {type avariables} {
    upvar 1 lines lines
    global accessor

    lappend lines {}
    foreach {put _} $accessor($type) av $avariables {
	lappend lines "$put (result, px, py) = UNOP ($av);"
    }
    return
}

proc assignA {type avariables} {
    upvar 1 lines lines
    global accessor

    lappend lines {}
    foreach {put _} $accessor($type) av $avariables {
	if {$put eq "A"} {
	    lappend lines "$put (result, px, py) = $av;"
	} else {
	    lappend lines "$put (result, px, py) = UNOP ($av);"
	}
    }
    return
}

proc gen {a z} {
    global basedir template
    upvar 1 lines lines

    lappend map @TYPE_IN@    $a
    lappend map @TYPE_OUT@   $z
    lappend map @TRANSFORM@ \t[join $lines \n\t]

    #puts \t[join $lines \n\t]

    set dst [file join $basedir unop_${a}.c]
    set ch  [open $dst w]
    puts -nonewline $ch [string map $map $template]
    close $ch
}

proc generate {a z} {
    global accessor

    puts -nonewline "Generating $z = $a ... "

    set la [dict size $accessor($a)]
    set lz [dict size $accessor($z)]

    # .... generation with A channel ...

    if {($la == $lz) &&
	[dict exists $accessor($a) A]} {
	puts {Av/A}
	# A vector, element-wise operation.

	set av [retrieve $a image BLACK]
	assignA $z $av
	gen $a $z
	return
    }

    # Generation without A channel.

    if {($la == $lz)} {
	puts {Av}
	# A vector, element-wise operation.

	set av [retrieve $a image BLACK]
	assign $z $av
	gen $a $z
	return
    }

    puts "ERR"
    return -code error "Bad configuration ($z = $a x $b)"
}

# # ## ### ##### ######## ############# ######################
## Generate the various configurations

# # ## ### ##### ######## ############# ######################

generate float     float
generate grey16    grey16
generate grey32    grey32
generate grey8     grey8

generate fpcomplex fpcomplex
generate rgb       rgb
generate rgba      rgba
generate hsv       hsv

# # ## ### ##### ######## ############# ######################
exit

