def op_gauss_cleanup {
    label {Laplacian of Gaussian Cleanup}
    setup_image {
	show
    }
    active {expr 0}
    setup {
	variable high   200
	variable low    150
	variable sigma1 3.5
	variable sigma2   1

	proc show {args} {
	    variable high
	    variable low
	    variable sigma1
	    variable sigma2
	    
	    show_image [crimp filter cleanup [base] \
			    $sigma1 $high $low $sigma2]	
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

	scale .left.sigma1 -variable ::DEMO::sigma1 \
	    -from 0.1 -to 5 -resolution 0.1 -length 100 \
	    -orient vertical \
	    -command ::DEMO::show
	
	scale .left.sigma2 -variable ::DEMO::sigma2 \
	    -from 0.1 -to 5 -resolution 0.1 -length 100 \
	    -orient vertical \
	    -command ::DEMO::show

	grid .left.high   -row 0 -column 0 -sticky swen
	grid .left.low    -row 0 -column 1 -sticky swen
	grid .left.sigma1 -row 1 -column 0 -sticky swen
	grid .left.sigma2 -row 1 -column 1 -sticky swen
    }
}
