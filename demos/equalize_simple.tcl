def effect_equalize_simple {
    label {Equalize/S}
    setup_image {
	variable greybase [crimp convert 2grey8 [base]]
	variable mask     [lindex [crimp split [base]] end]
	PLAIN
    }
    setup {
	variable greybase
	variable TL {0 1}

	proc HISTOG {image} {
	    variable TL
	    array set TMP [crimp histogram $image]
	    set TL [crimp::CUMULATE [dict values $TMP(luma)]]
	    return
	}

	proc PLAIN {} {
	    show_image [base]
	    return
	}

	proc EQUAL_LUMA {} {
	    variable greybase
	    HISTOG  $greybase
	    variable TL
	    show_image [crimp remap $greybase [crimp mapof [crimp::FIT $TL 255]]]
	    return
	}

	proc EQUAL_RGB2 {} {
	    variable greybase
	    HISTOG   $greybase
	    variable TL
	    show_image [crimp remap [base] [crimp mapof [crimp::FIT $TL 255]]]
	    return
	}

	variable TR {0 1}
	variable TG {0 1}
	variable TB {0 1}

	proc HISTORGB {image} {
	    variable TR ; variable TG ; variable TB
	    array set TMP [crimp histogram $image]
	    set TR [crimp::CUMULATE [dict values $TMP(red)]]
	    set TG [crimp::CUMULATE [dict values $TMP(green)]]
	    set TB [crimp::CUMULATE [dict values $TMP(blue)]]
	    return
	}

	proc EQUAL_RGB {} {
	    demo_time_hook equalize {
		HISTORGB [base]
		variable TR ; variable TG ; variable TB

		set r [crimp mapof [crimp::FIT $TR 255]]
		set g [crimp mapof [crimp::FIT $TG 255]]
		set b [crimp mapof [crimp::FIT $TB 255]]

		show_image [crimp remap [base] $r $g $b]
	    }
	    return
	}

	variable TS {0 1}
	variable TV {0 1}
	variable mask

	proc HISTOHSV {image} {
	    variable TS ; variable TV 
	    array set TMP [crimp histogram [crimp convert 2hsv   $image]]
	    set TS [crimp::CUMULATE [dict values $TMP(saturation)]]
	    set TV [crimp::CUMULATE [dict values $TMP(value)]]
	    return
	}

	proc EQUAL_SV {} {
	    demo_time_hook equalize {
		HISTOHSV [base]
		# H is not stretched. Does not make sense for HUE.
		variable TS ; variable TV
		variable mask

		set h [crimp map identity]
		set s [crimp mapof [crimp::FIT $TS 255]]
		set v [crimp mapof [crimp::FIT $TV 255]]

		show_image [crimp alpha set \
				[crimp convert 2rgb \
				     [crimp remap \
					  [crimp convert 2hsv [base]] \
					  $h $s $v]] \
				$mask]
	    }
	    return
	}

	proc EQUAL_V {} {
	    demo_time_hook equalize {
		HISTOHSV [base]
		# H & S are not stretched. Does not make sense for HUE, and not good for Saturation.
		variable TV
		variable mask

		set i [crimp map identity]
		set v [crimp mapof [crimp::FIT $TV 255]]

		show_image [crimp alpha set \
				[crimp convert 2rgb \
				     [crimp remap \
					  [crimp convert 2hsv [base]] \
					  $i $i $v]] \
				$mask]
	    }
	    return
	}

	proc EQUAL_AHE {} {
	    demo_time_hook ahe {
		show_image [crimp convert 2rgb \
				[crimp filter ahe \
				     [crimp convert 2hsv [base]] \
				     100]]
	    }
	    return
	}

	ttk::button .top.plain   -text Plain       -command ::DEMO::PLAIN
	ttk::button .top.equallu -text Eq/Luma     -command ::DEMO::EQUAL_LUMA
	ttk::button .top.equalr2 -text Eq/RGB/Luma -command ::DEMO::EQUAL_RGB2
	ttk::button .top.equalrg -text Eq/RGB      -command ::DEMO::EQUAL_RGB
	ttk::button .top.equalsv -text Eq/SV       -command ::DEMO::EQUAL_SV
	ttk::button .top.equalvv -text Eq/V        -command ::DEMO::EQUAL_V
	ttk::button .top.equalah -text Eq/AHE      -command ::DEMO::EQUAL_AHE

	grid .top.plain   -row 0 -column 0 -sticky swen
	grid .top.equallu -row 0 -column 1 -sticky swen
	grid .top.equalr2 -row 0 -column 2 -sticky swen
	grid .top.equalrg -row 0 -column 3 -sticky swen
	grid .top.equalsv -row 0 -column 4 -sticky swen
	grid .top.equalvv -row 0 -column 5 -sticky swen
	grid .top.equalah -row 0 -column 6 -sticky swen
    }
}
