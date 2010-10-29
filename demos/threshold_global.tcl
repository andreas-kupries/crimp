def op_threshold_global {
    label "Threshold Global"
    setup {
	# Demo various ways of for the automatic calculation of a
	# global threshold.

	proc showbase {} {
	    show_image [base]
	    return
	}

	proc average {} {
	    show_image [crimp threshold global mean [base]]
	    return
	}

	proc median {} {
	    show_image [crimp threshold global median [base]]
	    return
	}

	proc middle {} {
	    show_image [crimp threshold global middle [base]]
	    return
	}

	proc k-means {} {
	    # TODO
	    return
	}

	proc otsu {} {
	    show_image [crimp threshold global otsu [base]]
	    return
	}

	button .left.base   -text Base    -command ::DEMO::showbase
	button .left.middle -text Middle  -command ::DEMO::middle
	button .left.avg    -text Average -command ::DEMO::average
	button .left.med    -text Median  -command ::DEMO::median
	button .left.otsu   -text Otsu    -command ::DEMO::otsu

	grid .left.base   -row 2 -column 0 -sticky swen
	grid .left.avg    -row 3 -column 0 -sticky swen
	grid .left.med    -row 4 -column 0 -sticky swen
	grid .left.middle -row 5 -column 0 -sticky swen
	grid .left.otsu   -row 6 -column 0 -sticky swen
    }
    setup_image {
	showbase
    }
}
