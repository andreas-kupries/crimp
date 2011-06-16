def op_Noise_Salt_Pepper {
    label {NOISE Salt Pepper }
    active {
	expr {[bases] == 1}
    }
    setup_image {
	variable L  [base]
	show
    }
    setup {
	variable value  0.05
	
	
	
	proc show {args} {
	    variable L
        variable value
	 

	   show_image    [crimp noise saltpepper $L  $value ]  
	        return
	}

	scale .left.value -variable ::DEMO::value \
	    -from 0 -to 1 -resolution .01 -length 500\
	    -orient vertical \
	    -command ::DEMO::show

	grid .left.value -row 0 -column 0 -sticky swen
	
    

    }
}
