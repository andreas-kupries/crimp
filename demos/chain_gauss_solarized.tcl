def op_sol_gauus {
    label {(Solarize o Gauss) Map}
    setup {
	variable sigma      42
	variable threshold 256

	variable gtable     {}
	variable stable     {}
	variable ctable     {}

	proc showg {thesigma} {
	    variable gtable [crimp table gauss $thesigma]
	    showit
	    return
	}

	proc shows {thethreshold} {
	    variable stable [crimp table solarize $thethreshold]
	    showit
	    return
	}

	proc showit {} {
	    variable gtable
	    variable stable
	    variable ctable

	    # Block the early calls with incompletely initialized tables.
	    if {![llength $gtable]} return
	    if {![llength $stable]} return

	    # Compose and apply.
	    set ctable [crimp table compose $stable $gtable]
	    show_image [crimp remap [base] [crimp mapof $ctable]]
	    return
	}

	plot  .left.pg -variable ::DEMO::gtable -title Sigma
	plot  .left.ps -variable ::DEMO::stable -title Threshold
	plot  .left.pc -variable ::DEMO::ctable -title Composition

	scale .left.sg -variable ::DEMO::sigma     -from 0.1 -to 150 -resolution 0.1 -orient horizontal -command ::DEMO::showg
	scale .left.ss -variable ::DEMO::threshold -from 0   -to 256                 -orient horizontal -command ::DEMO::shows

	grid .left.sg -row 0 -column 0 -sticky swen
	grid .left.pg -row 1 -column 0 -sticky swen

	grid .left.ss -row 2 -column 0 -sticky swen
	grid .left.ps -row 3 -column 0 -sticky swen

	grid .left.pc -row 4 -column 0 -sticky swen
    }
    setup_image {
	showit
    }
}
