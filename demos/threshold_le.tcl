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

	plot  .left.p -variable ::DEMO::table -title Threshold
	scale .left.s -variable ::DEMO::threshold \
	    -from -1 -to 256 \
	    -orient horizontal \
	    -command ::DEMO::show

	grid .left.s -row 0 -column 0 -sticky swen
	grid .left.p -row 1 -column 0 -sticky swen
    }
    setup_image {
	showit
    }
}
