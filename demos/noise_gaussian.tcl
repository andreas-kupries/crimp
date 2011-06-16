def op_Noise_Gaussian {
    label {NOISE GAUSSIAN }
    active {
	expr {[bases] == 1}
    }
    setup_image {
	variable L  [base]
	show
    }
    setup {
	variable mean      0
	variable variance  0.005
	
	
	
	proc show {args} {
	    variable L
        variable mean      
	    variable variance  
		

	   show_image    [crimp noise gaussian $L  $mean $variance ]  
	        return
	}

	scale .left.mean -variable ::DEMO::mean \
	    -from 0 -to 1 -resolution .005 -length 400\
	    -orient vertical \
	    -command ::DEMO::show
		
    scale .left.variance -variable ::DEMO::variance \
	    -from 0 -to 1 -resolution .005 -length 400\
	    -orient vertical \
	    -command ::DEMO::show
		

	grid .left.mean     -row 0 -column 0 -sticky swen
	grid .left.variance -row 0 -column 1 -sticky swen
    

    }
}
