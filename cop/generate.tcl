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
    rgb       {R r G g B b}
    rgba      {R r G g B b A a}
    fpcomplex {RE re IM im}
}

array set ctype {
    float     double
    grey32    {int   }
    grey16    {int   }
    grey8     {int   }
    rgb       {int   }
    rgba      {int   }
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
}} [file join $basedir binop_template.c]]

# # ## ### ##### ######## ############# ######################
## Generator core.

proc retrieve {type input image zero {expand 0} {alpha {}}} {
    global ctype accessor
    upvar 1 lines lines
    set variables {}

    set vprefix ${input}_
    set guard   in$input
    set ox      ox$input
    set oy      oy$input

    foreach {get var} $accessor($type) {
	lappend lines "$ctype($type) $vprefix$var = $guard ? $get ($image, lx - $ox, ly - $oy) : $zero;"
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

proc assign {type avariables bvariables} {
    upvar 1 lines lines
    global accessor

    lappend lines {}
    foreach {put _} $accessor($type) av $avariables bv $bvariables {
	lappend lines "$put (result, px, py) = BINOP ($av, $bv);"
    }
    return
}

proc assignA {type avariables bvariables} {
    upvar 1 lines lines
    global accessor

    # Match variable lists.
    while {[llength $bvariables] < [llength $avariables]} { lappend bvariables [lindex $bvariables end] }
    while {[llength $avariables] < [llength $bvariables]} { lappend avariables [lindex $avariables end] }

    lappend lines {}
    foreach {put _} $accessor($type) av $avariables bv $bvariables {
	if {$put eq "A"} {
	    lappend lines "$put (result, px, py) = MAX   ($av, $bv);"
	} else {
	    lappend lines "$put (result, px, py) = BINOP ($av, $bv);"
	}
    }
    return
}

proc gen {a b z} {
    global basedir template
    upvar 1 lines lines

    lappend map @TYPE_A@    $a
    lappend map @TYPE_B@    $b
    lappend map @TYPE_Z@    $z
    lappend map @TRANSFORM@ \t[join $lines \n\t]

    #puts \t[join $lines \n\t]

    set dst [file join $basedir binop_${a}_${b}.c]
    set ch  [open $dst w]
    puts -nonewline $ch [string map $map $template]
    close $ch
}

proc generate {a b z} {
    global accessor

    puts -nonewline "Generating $z = $a x $b ... "

    set la [dict size $accessor($a)]
    set lb [dict size $accessor($b)]
    set lz [dict size $accessor($z)]

    # .... generation with A channel ...

    if {($la == $lb) && ($la == $lz) &&
	[dict exists $accessor($a) A] &&
	[dict exists $accessor($b) A]} {
	puts {Av/A x Bv/A}
	# A, B vectors, identical length, element-wise operation.

	set av [retrieve $a a imageA BLACK]
	set bv [retrieve $b b imageB BLACK]
	assignA $z $av $bv
	gen $a $b $z
	return
    }

    if {($la > $lb) && ($la == $lz) &&
	[dict exists $accessor($a) A]} {
	puts {Av/A x B}
	# A vector, B scalar/vector expanded to match for element-wise
	# operation, pseudo-alpha for the scalar

	incr la -1
	set av [retrieve $a a imageA BLACK]
	set bv [retrieve $b b imageB BLACK $la alpha]
	assignA $z $av $bv
	gen $a $b $z
	return
    }

    if {($lb > $la) && ($lb == $lz) &&
	[dict exists $accessor($b) A]} {
	puts {A x Bv/A}
	# B vector, A scalar/vector expanded to match for element-wise
	# operation, pseudo-alpha for the scalar

	incr lb -1
	set av [retrieve $a a imageA BLACK $lb alpha]
	set bv [retrieve $b b imageB BLACK]
	assignA $z $av $bv
	gen $a $b $z
	return
    }

    # Generation without A channel.

    if {($la == $lb) && ($la == $lz)} {
	puts {Av x Bv}
	# A, B vectors, identical length, element-wise operation.

	set av [retrieve $a a imageA BLACK]
	set bv [retrieve $b b imageB BLACK]
	assign $z $av $bv
	gen $a $b $z
	return
    }

    if {($la > $lb) && ($la == $lz) && ($lb == 1)} {
	puts {Av x B}
	# A vector, B scalar expanded to match for element-wise operation

	set av [retrieve $a a imageA BLACK]
	set bv [retrieve $b b imageB BLACK $la]
	assign $z $av $bv
	gen $a $b $z
	return
    }

    if {($lb > $la) && ($lb == $lz) && ($la == 1)} {
	puts {A x Bv}
	# B vector, A scalar expanded to match for element-wise operation

	set av [retrieve $a a imageA BLACK $lb]
	set bv [retrieve $b b imageB BLACK]
	assign $z $av $bv
	gen $a $b $z
	return
    }

    puts "ERR"
    return -code error "Bad configuration ($z = $a x $b)"
}

# # ## ### ##### ######## ############# ######################
## Generate the various configurations

# # ## ### ##### ######## ############# ######################
## Simple vs simple.

generate float     float     float
generate float     grey16    float
generate float     grey32    float
generate float     grey8     float

generate grey16    float     float
generate grey16    grey16    grey16
generate grey16    grey32    grey32
generate grey16    grey8     grey16

generate grey32    float     float
generate grey32    grey16    grey32
generate grey32    grey32    grey32
generate grey32    grey8     grey32

generate grey8     float     float
generate grey8     grey16    grey16
generate grey8     grey32    grey32
generate grey8     grey8     grey8

# # ## ### ##### ######## ############# ######################
## Complex vs. others, self and simple.

generate fpcomplex fpcomplex fpcomplex

generate fpcomplex float     fpcomplex
generate fpcomplex grey16    fpcomplex
generate fpcomplex grey32    fpcomplex
generate fpcomplex grey8     fpcomplex

generate float     fpcomplex fpcomplex
generate grey16    fpcomplex fpcomplex
generate grey32    fpcomplex fpcomplex
generate grey8     fpcomplex fpcomplex

# # ## ### ##### ######## ############# ######################
## RGB vs others, self and simple (grey8 only).

generate rgb       rgb       rgb

generate grey8     rgb       rgb
generate rgb       grey8     rgb

# # ## ### ##### ######## ############# ######################
## RGBA vs self, RGB, and simple (grey8 only).

generate rgba  rgba  rgba

generate grey8 rgba  rgba
generate rgba  grey8 rgba

generate rgb   rgba  rgba
generate rgba  rgb   rgba

# # ## ### ##### ######## ############# ######################
exit

