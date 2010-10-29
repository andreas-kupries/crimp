def op_threshold_le {
    label "Threshold \u2264"
    setup {
	variable threshold 256
	variable table     {}

	proc show {thethreshold} {
	    # (x < threshold) ==> black, else white
	    #
	    # (threshold == -1)  ==> all white
	    # (threshold == 256) ==> all black

	    variable table [crimp table threshold below  $thethreshold]
	    show_image     [crimp threshold global below [base] $thethreshold]
	    return
	}

	proc showit {} {
	    variable threshold
	    show $threshold
	    return
	}

	# Demo various ways of for the automatic calculation of a
	# global threshold.

	proc showbase {} {
	    show_image [base]
	    return
	}

	proc average {} {
	    variable threshold
	    array set s [crimp statistics basic [crimp convert 2grey8 [base]]]
	    array set s $s(channel)
	    array set s $s(luma)
	    set threshold $s(mean)
	    showit
	    return
	}

	proc median {} {
	    variable threshold
	    array set s [crimp statistics basic [crimp convert 2grey8 [base]]]
	    array set s $s(channel)
	    array set s $s(luma)
	    set threshold $s(median)
	    showit
	    return
	}

	proc middle {} {
	    variable threshold
	    array set s [crimp statistics basic [crimp convert 2grey8 [base]]]
	    array set s $s(channel)
	    array set s $s(luma)
	    set threshold $s(middle)
	    showit
	    return
	}

	proc k-means {} {
	    variable threshold
	    array set s [crimp statistics basic [crimp convert 2grey8 [base]]]
	    array set s $s(channel)
	    array set s $s(luma)
	    # TODO ... classify $s(histogram) 0 255 ...
	    showit
	    return
	}

	proc otsu {} {
	    variable threshold
	    array set s [crimp statistics otsu [crimp statistics basic [crimp convert 2grey8 [base]]]]
	    array set s $s(channel)
	    array set s $s(luma)
	    set threshold $s(otsu)
	    showit
	    return
	}

	plot  .left.p -variable ::DEMO::table -title Threshold
	scale .left.s -variable ::DEMO::threshold \
	    -from -1 -to 256 \
	    -orient horizontal \
	    -command ::DEMO::show

	button .left.base   -text Base    -command ::DEMO::showbase
	button .left.middle -text Middle  -command ::DEMO::middle
	button .left.avg    -text Average -command ::DEMO::average
	button .left.med    -text Median  -command ::DEMO::median
	button .left.otsu   -text Otsu    -command ::DEMO::otsu

	grid .left.s      -row 0 -column 0 -sticky swen
	grid .left.p      -row 1 -column 0 -sticky swen

	grid .left.base   -row 2 -column 0 -sticky swen
	grid .left.avg    -row 3 -column 0 -sticky swen
	grid .left.med    -row 4 -column 0 -sticky swen
	grid .left.middle -row 5 -column 0 -sticky swen
	grid .left.otsu   -row 6 -column 0 -sticky swen
    }
    setup_image {
	showit
    }
}
