def op_gamma_invers {
    label Degamma
    setup {
	set ::DEGAMMA 1
	set ::TABLE   {}

	plot  .left.p -variable ::TABLE
	scale .left.g -variable ::DEGAMMA \
	    -from 5 -to 1 -resolution 0.01 \
	    -orient vertical \
	    -command [list ::apply {{gamma} {
		set ::TABLE [crimp table degamma  $gamma]
		show_image  [crimp degamma [base] $gamma]
	    }}]

	grid .left.p -row 0 -column 0 -sticky swen
	grid .left.g -row 0 -column 1 -sticky swen
    }
    shutdown {
	unset ::DEGAMMA ::TABLE
    }
}
