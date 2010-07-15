def op_gamma {
    label Gamma
    setup {
	variable gamma 1
	variable table {}

	plot  .left.p -variable ::DEMO::table -title Gamma
	scale .left.s -variable ::DEMO::gamma \
	    -from 5 -to 1 -resolution 0.01 \
	    -orient vertical \
	    -command [list ::apply {{thegamma} {
		variable table [crimp table gamma  $thegamma]
		show_image     [crimp gamma [base] $thegamma]
	    } ::DEMO}]

	grid .left.p -row 0 -column 0 -sticky swen
	grid .left.s -row 0 -column 1 -sticky swen
    }
}
