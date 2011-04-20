def op_gauss_gradient_mag_luma {
    label {Gauss IIR Gradient Magnitude Luma}
    setup {
	variable sigma 0.2
	variable table     {}

	proc show {thesigma} {
	    variable L
	    if {![info exists L]} return
	    set blurred	    [crimp::gaussian_gradient_mag_float \
				$L $thesigma]
	    set stats	    [crimp::stats_float $blurred]
	    set offset	    [expr {- [dict get $stats value min]}]
	    set range 	    [expr {[dict get $stats value max] 
				   - [dict get $stats value min]}]
	    set scale	    [expr {255.0 / $range}]
	    set blurred	    [crimp::offset_float $blurred $offset]
	    set blurred     [crimp::scale_float $blurred $scale]
	    set blurred	    [crimp::convert 2grey8 $blurred]
	    show_image	    $blurred
	    return
	}

	proc showit {} {
	    variable sigma
	    show $sigma
	    return
	}

	scale .left.s -variable ::DEMO::sigma \
	    -from 0.1 -to 60 -resolution 0.1 -length 450 \
	    -orient vertical \
	    -command ::DEMO::show

	grid .left.s -row 0 -column 0 -sticky swen
    }
    setup_image {
	variable L [crimp convert 2float [crimp convert 2grey8 [base]]]
	showit
    }
}
