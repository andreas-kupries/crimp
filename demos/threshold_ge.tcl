def op_threshold_ge {
    label "Threshold \u2265"
    setup {
	variable threshold 256
	variable table     {}

	proc show {thethreshold} {
	    variable table [crimp table threshold-ge  $thethreshold]
	    show_image     [crimp threshold global ge [base] $thethreshold]
	    return
	}

	proc showit {} {
	    variable threshold
	    show $threshold
	    return
	}

	plot  .left.p -variable ::DEMO::table -title Threshold
	scale .left.s -variable ::DEMO::threshold \
	    -from 0 -to 256 \
	    -orient horizontal \
	    -command ::DEMO::show

	grid .left.s -row 0 -column 0 -sticky swen
	grid .left.p -row 1 -column 0 -sticky swen
    }
    setup_image {
	showit
    }
}
