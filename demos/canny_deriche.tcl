def op_Edge_Canny_Deriche {
    label {Edge Canny Deriche}
    setup_image {
	show
    }
    setup {
	variable high  150
	variable low   100
	variable sigma 0.1
	
	proc show {args} {
	    variable high
	    variable low
	    variable sigma

	    show_image [crimp filter canny deriche [base] $high $low $sigma]
	    return
	}

	scale .left.high -variable ::DEMO::high \
	    -from 0 -to 255 -resolution 5 -length 255\
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.low -variable ::DEMO::low \
	    -from 0 -to 255 -resolution 5 -length 255\
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.sigma -variable ::DEMO::sigma \
	    -from 0.1 -to 5 -resolution 0.1 -length 100 \
	    -orient vertical \
	    -command ::DEMO::show

	grid .left.high  -row 0 -column 0 -sticky swen
	grid .left.low   -row 0 -column 1 -sticky swen
	grid .left.sigma -row 0 -column 2 -sticky swen
    }
}
