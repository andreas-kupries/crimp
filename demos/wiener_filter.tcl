def op_Wiener_Filter {
    label {Wiener Filter }
    active {
	expr {[bases] == 1}
    }
    setup_image {
	variable L  [base]
	show
    }
    setup {
	variable radius  2
	
	
	
	proc show {args} {
	    variable L
        variable radius
	 

	   show_image    [crimp filter wiener  [crimp convert 2grey8 $L ] $radius ]  
	        return
	}

	scale .left.radius -variable ::DEMO::radius \
	    -from 1 -to 10 -resolution 1 -length 100\
	    -orient vertical \
	    -command ::DEMO::show

	grid .left.radius -row 0 -column 0 -sticky swen
	
    

    }
}
