def op_gamma_invers {
    label Degamma
    setup {
	variable gamma 2.2
	variable table {}

	proc show {thegamma} {
	    variable table [crimp table degamma  $thegamma]
	    show_image     [crimp degamma [base] $thegamma]
	    return
	}

	proc showit {} {
	    variable gamma
	    show $gamma
	    return
	}

	plot  .left.p -variable ::DEMO::table -title {Invers Gamma}
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
