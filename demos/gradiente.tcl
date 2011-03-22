def effect_gradient_simple {
    label {Gradient Calculation}
    setup_image {
	variable greybase [crimp convert 2grey8 [base]]
	PLAIN
    }
    setup {
	variable greybase
	variable low  25
	variable high 75

	proc row {args} {
	    crimp montage horizontal {*}$args
	}

	proc stack {args} {
	    crimp montage vertical {*}$args
	}

	proc b {i} {
	    crimp expand const [rgb $i] \
		5 5 5 5 \
		0 0 255
	}

	proc e {i {n 1}} {
	    crimp expand const $i $n $n $n $n
	}

	proc fg {i} {
	    set s [crimp statistics basic $i]
	    set min [dict get $s channel value min]
	    set max [dict get $s channel value max]
	    # Compress (or expand) into the 0...255 range of grey8.
	    set offset [expr {-1 * $min}]
	    set scale  [expr {255.0/($max - $min)}]
	    crimp convert 2grey8 [crimp::scale_float [crimp::offset_float $i $offset] $scale]
	}

	proc % {i} {
	    set s [crimp statistics basic $i]
	    set min [dict get $s channel value min]
	    set max [dict get $s channel value max]
	    # Compress (or expand) into the range 0...100 (percent).
	    set offset [expr {-1 * $min}]
	    set scale  [expr {100.0/($max - $min)}]
	    return [crimp::scale_float [crimp::offset_float $i $offset] $scale]
	}

	proc rgb {i} {
	    crimp convert 2rgb $i
	}

	proc space {i} {
	    crimp blank rgb {*}[crimp dimensions $i] 0 0 255
	}

	proc PLAIN {} {
	    show_image [base]
	    return
	}

	proc GRADIENT {type} {
	    variable no
	    variable gc
	    variable gp
	    variable gv
	    variable greybase
	    set im [crimp convert 2float $greybase]
	    set gc [crimp gradient $type  $im]
	    set gp [crimp gradient polar  $gc]
	    set gv [crimp gradient visual $gp]

	    # Do canny edge detection...
	    lassign $gc x y
	    lassign $gp m a
	    set ca [crimp::non_max_suppression [e $m] [e $a]]
	    set no [% $ca]

	    RETRACE
	    return
	}

	proc RETRACE {args} {
	    variable no
	    variable gc
	    variable gp
	    variable gv
	    variable greybase
	    variable low
	    variable high

	    if {![info exists no]} return

	    set ed [crimp::trace_hysteresis $no $low $high]

	    lassign $gc x y
	    lassign $gp m a
	    show_image \
		[stack \
		     [row [b [base]]  [b $greybase]] \
		     [row [b [fg $x]] [b [fg $y]]] \
		     [row [b [fg $m]] [b [fg $a]]] \
		     [row [b $gv]     [b $ed]]]
	    return
	}

	proc SOBEL   {} { GRADIENT sobel   }
	proc SCHARR  {} { GRADIENT scharr  }
	proc PREWITT {} { GRADIENT prewitt }

	ttk::button .top.plain -text Plain   -command ::DEMO::PLAIN
	ttk::button .top.sobel -text Sobel   -command ::DEMO::SOBEL
	ttk::button .top.schar -text Scharr  -command ::DEMO::SCHARR
	ttk::button .top.prewi -text Prewitt -command ::DEMO::PREWITT

	grid .top.plain -row 0 -column 0 -sticky swen
	grid .top.prewi -row 0 -column 1 -sticky swen
	grid .top.sobel -row 0 -column 2 -sticky swen
	grid .top.schar -row 0 -column 3 -sticky swen

	scale .left.l -variable ::DEMO::low \
	    -from 0 -to 100 -resolution 0.1 \
	    -orient vertical \
	    -command ::DEMO::RETRACE

	scale .left.h -variable ::DEMO::high \
	    -from 0 -to 100 -resolution 0.1 \
	    -orient vertical \
	    -command ::DEMO::RETRACE

	grid .left.l -row 0 -column 0 -sticky swen -rowspan 4
	grid .left.h -row 0 -column 1 -sticky swen -rowspan 4
    }
}
