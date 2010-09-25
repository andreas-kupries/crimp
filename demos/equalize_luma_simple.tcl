def effect_equalize_luma_simple {
    label {Equalize/S (luma)}
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
	    set TL [crimp::CUMULATE $HL]

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

	    set fl [crimp::FIT $TL 255]
	    set l  [crimp mapof $fl]

	    set new [crimp remap $base $l]

	    show_image $new
	    HISTO      $new
	    return
	}

	ttk::button .top.equal -text Equalize -command ::DEMO::EQUAL
	ttk::button .top.plain -text Plain    -command ::DEMO::PLAIN

	grid .top.equal -row 0 -column 0 -sticky swen
	grid .top.plain -row 0 -column 1 -sticky swen
    }
}
