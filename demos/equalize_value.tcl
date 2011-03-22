def effect_equalize_value {
    label {Equalize (HSV - Value)}
    setup_image {
	variable mask [lindex [crimp split [base]] end]
	PLAIN
    }
    setup {
	variable TS {0 1}
	variable TV {0 1}
	variable TL {0 1}

	variable mask

	proc HISTO {image} {
	    variable HL ; variable HH ; variable HS ; variable HV
	    variable TL ;               variable TS ; variable TV 

	    array set TMP [crimp histogram [crimp convert 2grey8 $image]]
	    array set TMP [crimp histogram [crimp convert 2hsv   $image]]

	    set HL [dict values $TMP(luma)]       ; set TL [crimp::CUMULATE $HL]
	    set HH [dict values $TMP(hue)]
	    set HS [dict values $TMP(saturation)] ; set TS [crimp::CUMULATE $HS]
	    set HV [dict values $TMP(value)]      ; set TV [crimp::CUMULATE $HV]


	    # For the sake of the display we cut out the pure white
	    # and black, as they are likely outliers with an extreme
	    # number of pixels using them.
	    
	    lset HL 0 0 ; lset HL 255 0
	    lset HS 0 0 ; lset HS 255 0
	    lset HV 0 0 ; lset HV 255 0
	    return
	}

	proc PLAIN {} {
	    HISTO      [base]
	    show_image [base]
	    return
	}

	proc EQUAL {} {
	    demo_time_hook equalize {
		HISTO [base]
		# H & S are not stretched. Does not make sense for HUE, and not good for Saturation.
		variable HH ; variable HV
		              variable TV
		variable mask

		set fv [crimp::FIT $TV 255]

		set i [crimp map identity]
		set v [crimp mapof $fv]

		set new [crimp alpha set \
			     [crimp convert 2rgb \
				  [crimp remap \
				       [crimp convert 2hsv [base]] \
				       $i $i $v]] \
			     $mask]
	    }

	    show_image $new
	    HISTO      $new
	    return
	}

	HISTO [base]

	plot  .left.hl   -variable ::DEMO::HL -locked 0 -title Luma
	plot  .left.tl   -variable ::DEMO::TL -locked 0 -title {CDF Luma}
	plot  .left.hh   -variable ::DEMO::HH -locked 0 -title Hue

	plot  .bottom.hs -variable ::DEMO::HS -locked 0 -title Saturation
	plot  .bottom.hv -variable ::DEMO::HV -locked 0 -title Value

	plot  .bottom.ts -variable ::DEMO::TS -locked 0 -title {CDF Saturation}
	plot  .bottom.tv -variable ::DEMO::TV -locked 0 -title {CDF Value}

	ttk::button .top.equal -text Equalize -command ::DEMO::EQUAL
	ttk::button .top.plain -text Plain    -command ::DEMO::PLAIN

	grid .left.hl -row 0 -column 0 -sticky swen
	grid .left.tl -row 1 -column 0 -sticky swen
	grid .left.hh -row 2 -column 0 -sticky swen

	grid .bottom.hs -row 0 -column 0 -sticky swen
	grid .bottom.ts -row 0 -column 1 -sticky swen
	grid .bottom.hv -row 0 -column 2 -sticky swen
	grid .bottom.tv -row 0 -column 3 -sticky swen

	grid .top.equal -row 0 -column 0 -sticky swen
	grid .top.plain -row 0 -column 1 -sticky swen
    }
}
