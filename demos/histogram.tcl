def effect_histogram {
    label Histogram
    setup_image {
	variable mask [lindex [crimp split [base]] end]
	EQNONE
    }
    setup {
	variable TR {0 1}
	variable TG {0 1}
	variable TB {0 1}
	variable TS {0 1}
	variable TV {0 1}
	variable TL {0 1}

	variable mask

	proc HISTO {image} {
	    variable HR ; variable HG ; variable HB ; variable HL ; variable HH ; variable HS ; variable HV
	    variable TR ; variable TG ; variable TB ; variable TL ;               variable TS ; variable TV 

	    array set TMP [crimp histogram $image]
	    array set TMP [crimp histogram [crimp convert 2grey8 $image]]
	    array set TMP [crimp histogram [crimp convert 2hsv   $image]]

	    set HR [dict values $TMP(red)]   ; set TR [CUMULATE $HR]
	    set HG [dict values $TMP(green)] ; set TG [CUMULATE $HG]
	    set HB [dict values $TMP(blue)]  ; set TB [CUMULATE $HB]

	    set HL [dict values $TMP(luma)]  ; set TL [CUMULATE $HL]

	    set HH [dict values $TMP(hue)]
	    set HS [dict values $TMP(saturation)] ; set TS [CUMULATE $HS]
	    set HV [dict values $TMP(value)]      ; set TV [CUMULATE $HV]

	    # For display only, kill the two most probable outliers at
	    # the ends of each series/plot.
	    
	    lset HR 0 0 ; lset HR 255 0
	    lset HG 0 0 ; lset HG 255 0
	    lset HB 0 0 ; lset HB 255 0
	    lset HL 0 0 ; lset HL 255 0

	    lset HS 0 0 ; lset HS 255 0
	    lset HV 0 0 ; lset HV 255 0
	    return
	}

	proc EQNONE {} {
	    HISTO [base]
	    show_image [base]
	    return
	}

	proc EQHSV {} {
	    HISTO [base]
	    # H is not stretched. Does not make sense for HUE.
	    variable HH ; variable HS ; variable HV
	                  variable TS ; variable TV
	    variable mask

	    set fs [FIT $TS 255]
	    set fv [FIT $TV 255]

	    set h [crimp map identity]
	    #set s [crimp map identity]
	    #set v [crimp map identity]
	    set s [crimp read tcl [list $fs]]
	    set v [crimp read tcl [list $fv]]

	    set new [crimp setalpha \
			 [crimp convert 2rgb \
			      [crimp remap \
				   [crimp convert 2hsv [base]] \
				   $h $s $v]] \
			 $mask]

	    show_image $new
	    HISTO $new
	    return
	}

	proc EQRGB {} {
	    HISTO [base]
	    variable HR ; variable HG ; variable HB
	    variable TR ; variable TG ; variable TB

	    set fr [FIT $TR 255]
	    set fg [FIT $TG 255]
	    set fb [FIT $TB 255]

	    set r [crimp read tcl [list $fr]]
	    set g [crimp read tcl [list $fg]]
	    set b [crimp read tcl [list $fb]]

	    set new [crimp remap [base] $r $g $b]

	    show_image $new
	    HISTO $new
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

	HISTO [base]

	# For the sake of the display we cut out the pure white and
	# black, as they are likely outliers with an extreme number of
	# pixels using them.
	
	plot  .left.hr -variable ::DEMO::HR -locked 0 -title Red
	plot  .left.hg -variable ::DEMO::HG -locked 0 -title Green
	plot  .left.hb -variable ::DEMO::HB -locked 0 -title Blue

	plot  .top.hl -variable ::DEMO::HL -locked 0 -title Luma
	plot  .top.hh -variable ::DEMO::HH -locked 0 -title Hue
	plot  .top.hs -variable ::DEMO::HS -locked 0 -title Saturation
	plot  .top.hv -variable ::DEMO::HV -locked 0 -title Value

	ttk::button .right.eqhsv  -text {Equalize HSV}  -command ::DEMO::EQHSV
	ttk::button .right.eqrgb  -text {Equalize RGB}  -command ::DEMO::EQRGB
	ttk::button .right.eqnone -text {Equalize None} -command ::DEMO::EQNONE

	plot  .right.tr -variable ::DEMO::TR -locked 0 -title {CDF Red}
	plot  .right.tg -variable ::DEMO::TG -locked 0 -title {CDF Green}
	plot  .right.tb -variable ::DEMO::TB -locked 0 -title {CDF Blue}
	plot  .top.tl   -variable ::DEMO::TL -locked 0 -title {CDF Luma}
	plot  .top.ts   -variable ::DEMO::TS -locked 0 -title {CDF Saturation}
	plot  .top.tv   -variable ::DEMO::TV -locked 0 -title {CDF Value}


	grid .left.hr -row 0 -column 0 -sticky swen
	grid .left.hg -row 1 -column 0 -sticky swen
	grid .left.hb -row 2 -column 0 -sticky swen

	grid .top.hl -row 0 -column 0 -sticky swen
	grid .top.hh -row 0 -column 1 -sticky swen
	grid .top.hs -row 0 -column 2 -sticky swen
	grid .top.hv -row 0 -column 3 -sticky swen

	grid .right.eqrgb  -row 0 -column 0 -sticky swen
	grid .right.eqhsv  -row 1 -column 0 -sticky swen
	grid .right.eqnone -row 2 -column 0 -sticky swen

	grid .right.tr -row 3 -column 0 -sticky swen
	grid .right.tg -row 4 -column 0 -sticky swen
	grid .right.tb -row 5 -column 0 -sticky swen

	grid .top.tl -row 1 -column 0 -sticky swen
	grid .top.ts -row 1 -column 2 -sticky swen
	grid .top.tv -row 1 -column 3 -sticky swen
    }
}
