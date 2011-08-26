def op_Noise_SPECKLE {
    label {Noise - Speckle (Multiplicative)}
    active {
	expr {[bases] == 1}
    }
    setup_image {
	show
    }
    setup {
	variable variance  0.005
	
	proc show {args} {
	    variable variance  

	    show_image [crimp noise speckle [base] $variance]
	    return
	}

	scale .left.variance -variable ::DEMO::variance \
	    -from 0 -to 1 -resolution .005 -length 400\
	    -orient vertical \
	    -command ::DEMO::show
	
	grid .left.variance -row 0 -column 0 -sticky swen
    }
}
