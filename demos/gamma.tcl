def op_gamma {
    label Gamma
    setup {
	variable gamma 2.2
	variable table {}

	proc show {thegamma} {
	    variable table [crimp table gamma  $thegamma]
	    show_image     [crimp gamma [base] $thegamma]
	    return
	}

	proc showit {} {
	    variable gamma
	    show $gamma
	    return
	}

	plot  .left.p -variable ::DEMO::table -title Gamma
	scale .left.s -variable ::DEMO::gamma \
	    -from 5 -to 1 -resolution 0.01 \
	    -orient vertical \
	    -command ::DEMO::show

	grid .left.p -row 0 -column 0 -sticky swen
	grid .left.s -row 0 -column 1 -sticky swen
    }
    setup_image {
	showit
    }
}
