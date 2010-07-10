def op_gamma {
    label Gamma
    setup {
	set ::GAMMA 1
	set ::TABLE {}

	plot  .left.p -variable ::TABLE
	scale .left.g -variable ::GAMMA \
	    -from 5 -to 1 -resolution 0.01 \
	    -orient vertical \
	    -command [list ::apply {{gamma} {
		set ::TABLE [crimp table gamma  $gamma]
		show_image  [crimp gamma [base] $gamma]
	    }}]

	grid .left.p -row 0 -column 0 -sticky swen
	grid .left.g -row 0 -column 1 -sticky swen
    }
    shutdown {
	unset ::GAMMA ::TABLE
    }
}
