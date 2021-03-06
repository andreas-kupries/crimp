def op_gauss {
    label {Gauss Map}
    setup {
	variable sigma 42
	variable table     {}

	proc show {thesigma} {
	    variable table [crimp table gauss  $thesigma]
	    show_image     [crimp remap [base] [crimp map gauss $thesigma]]
	    return
	}

	proc showit {} {
	    variable sigma
	    show $sigma
	    return
	}

	plot  .left.p -variable ::DEMO::table -title Sigma
	scale .left.s -variable ::DEMO::sigma \
	    -from 0.1 -to 150 -resolution 0.1 \
	    -orient horizontal \
	    -command ::DEMO::show

	grid .left.s -row 0 -column 0 -sticky swen
	grid .left.p -row 1 -column 0 -sticky swen
    }
    setup_image {
	showit
    }
}
