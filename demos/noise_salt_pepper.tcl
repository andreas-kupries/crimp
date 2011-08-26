def op_Noise_Salt_Pepper {
    label {Noise - Salt/Pepper}
    active {
	expr {[bases] == 1}
    }
    setup_image {
	show
    }
    setup {
	variable threshold 0.05

	proc show {args} {
	    variable threshold
	    show_image [crimp noise saltpepper [base] $threshold]
	    return
	}

	scale .left.threshold -variable ::DEMO::threshold \
	    -from 0 -to 1 -resolution .01 -length 500 \
	    -orient vertical \
	    -command ::DEMO::show

	grid .left.threshold -row 0 -column 0 -sticky swen
    }
}
