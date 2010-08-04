def effect_equalize_luma {
    label {Equalize (luma)}
    setup_image {
	variable base [crimp convert 2grey8 [base]]
	PLAIN
    }
    setup {
	variable base
	variable TL {0 1}

	proc HISTO {image} {
	    variable HL
	    variable TL

	    array set TMP [crimp histogram $image]

	    set HL [dict values $TMP(luma)]
	    set TL [CUMULATE $HL]

	    # For the sake of the display we cut out the pure white
	    # and black, as they are likely outliers with an extreme
	    # number of pixels using them.
	    
	    lset HL 0 0 ; lset HL 255 0
	    return
	}

	proc PLAIN {} {
	    variable base
	    HISTO      $base
	    show_image $base
	    return
	}

	proc EQUAL {} {
	    variable base
	    HISTO $base
	    variable HL
	    variable TL

	    set fl [FIT $TL 255]
	    set l  [crimp read tcl [list $fl]]

	    set new [crimp remap $base $l]

	    show_image $new
	    HISTO      $new
	    return
	}

	# series(int) --> series (int)
	proc CUMULATE {series} {
	    set res {}
	    set sum 0
	    foreach x $series {
		lappend res $sum
		incr sum $x
	    }
	    return $res
	}

	# series(int/float) --> series(int), all(x): x <= max
	proc FIT {series max} {
	    # Assumes that the input is a monotonically increasing
	    # series. The maximum value of the series is at the end.
	    set top [lindex $series end]
	    set f   [expr {double($max) / double($top)}]
	    set res {}

	    foreach x $series {
		lappend res [expr {round(double($x)*$f)}]
	    }
	    return $res
	}

	#HISTO $base

	plot  .left.hl   -variable ::DEMO::HL -locked 0 -title Luma
	plot  .left.tl   -variable ::DEMO::TL -locked 0 -title {CDF Luma}

	ttk::button .top.equal -text Equalize -command ::DEMO::EQUAL
	ttk::button .top.plain -text Plain    -command ::DEMO::PLAIN

	grid .left.hl -row 0 -column 0 -sticky swen
	grid .left.tl -row 1 -column 0 -sticky swen

	grid .top.equal -row 0 -column 0 -sticky swen
	grid .top.plain -row 0 -column 1 -sticky swen
    }
}
