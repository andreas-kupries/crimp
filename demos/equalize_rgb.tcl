def effect_equalize_rgb {
    label {Equalize (RGB)}
    setup_image {
	PLAIN
    }
    setup {
	variable TR {0 1}
	variable TG {0 1}
	variable TB {0 1}
	variable TL {0 1}

	proc HISTO {image} {
	    variable HL ; variable HR ; variable HG ; variable HB
	    variable TL ; variable TR ; variable TG ; variable TB

	    array set TMP [crimp histogram [crimp convert 2grey8 $image]]
	    array set TMP [crimp histogram $image]

	    set HL [dict values $TMP(luma)]  ; set TL [crimp::CUMULATE $HL]
	    set HR [dict values $TMP(red)]   ; set TR [crimp::CUMULATE $HR]
	    set HG [dict values $TMP(green)] ; set TG [crimp::CUMULATE $HG]
	    set HB [dict values $TMP(blue)]  ; set TB [crimp::CUMULATE $HB]

	    # For the sake of the display we cut out the pure white
	    # and black, as they are likely outliers with an extreme
	    # number of pixels using them.
	    
	    lset HL 0 0 ; lset HL 255 0
	    lset HR 0 0 ; lset HR 255 0
	    lset HG 0 0 ; lset HG 255 0
	    lset HB 0 0 ; lset HB 255 0
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
		variable HR ; variable HG ; variable HB
		variable TR ; variable TG ; variable TB

		set fr [crimp::FIT $TR 255]
		set fg [crimp::FIT $TG 255]
		set fb [crimp::FIT $TB 255]

		set r [crimp read tcl [list $fr]]
		set g [crimp read tcl [list $fg]]
		set b [crimp read tcl [list $fb]]

		set new [crimp remap [base] $r $g $b]
	    }

	    show_image $new
	    HISTO      $new
	    return
	}

	HISTO [base]

	plot  .left.hl   -variable ::DEMO::HL -locked 0 -title Luma
	plot  .left.tl   -variable ::DEMO::TL -locked 0 -title {CDF Luma}

	plot  .bottom.hr -variable ::DEMO::HR -locked 0 -title Red
	plot  .bottom.hg -variable ::DEMO::HG -locked 0 -title Green
	plot  .bottom.hb -variable ::DEMO::HB -locked 0 -title Blue

	plot  .bottom.tr -variable ::DEMO::TR -locked 0 -title {CDF Red}
	plot  .bottom.tg -variable ::DEMO::TG -locked 0 -title {CDF Green}
	plot  .bottom.tb -variable ::DEMO::TB -locked 0 -title {CDF Blue}

	ttk::button .top.equal -text Equalize -command ::DEMO::EQUAL
	ttk::button .top.plain -text Plain    -command ::DEMO::PLAIN

	grid .left.hl -row 0 -column 0 -sticky swen
	grid .left.tl -row 1 -column 0 -sticky swen

	grid .bottom.hr -row 0 -column 0 -sticky swen
	grid .bottom.tr -row 1 -column 0 -sticky swen
	grid .bottom.hg -row 0 -column 1 -sticky swen
	grid .bottom.tg -row 1 -column 1 -sticky swen
	grid .bottom.hb -row 0 -column 2 -sticky swen
	grid .bottom.tb -row 1 -column 2 -sticky swen

	grid .top.equal -row 0 -column 0 -sticky swen
	grid .top.plain -row 0 -column 1 -sticky swen
    }
}
