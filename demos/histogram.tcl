def effect_histogram {
    label Histogram
    setup {

	array set TMP [crimp histogram [base]]
	array set TMP [crimp histogram [crimp convert 2grey8 [base]]]
	array set TMP [crimp histogram [crimp convert 2hsv   [base]]]
	set ::HR [dict values $TMP(red)]
	set ::HG [dict values $TMP(green)]
	set ::HB [dict values $TMP(blue)]
	set ::HL [dict values $TMP(luma)]
	set ::HH [dict values $TMP(hue)]
	set ::HS [dict values $TMP(saturation)]
	set ::HV [dict values $TMP(value)]

	# For the sake of the display we cut out the pure white and
	# black, as they are likely outliers with an extreme number of
	# pixels using them.

	lset ::HR 0 0 ; lset ::HR 255 0
	lset ::HG 0 0 ; lset ::HG 255 0
	lset ::HB 0 0 ; lset ::HB 255 0
	lset ::HL 0 0 ; lset ::HL 255 0

	lset ::HS 0 0 ; lset ::HS 255 0
	lset ::HV 0 0 ; lset ::HV 255 0
	
	plot  .left.hr -variable ::HR -locked 0
	plot  .left.hg -variable ::HG -locked 0
	plot  .left.hb -variable ::HB -locked 0

	plot  .top.hl -variable ::HL -locked 0
	plot  .top.hh -variable ::HH -locked 0
	plot  .top.hs -variable ::HS -locked 0
	plot  .top.hv -variable ::HV -locked 0

	grid .left.hr -row 0 -column 0 -sticky swen
	grid .left.hg -row 1 -column 0 -sticky swen
	grid .left.hb -row 2 -column 0 -sticky swen

	grid .top.hl -row 0 -column 0 -sticky swen
	grid .top.hh -row 0 -column 1 -sticky swen
	grid .top.hs -row 0 -column 2 -sticky swen
	grid .top.hv -row 0 -column 3 -sticky swen
    }
    shutdown {
	unset ::HR ::HG ::HB ::HL ::HH ::HS ::HV
    }
}
