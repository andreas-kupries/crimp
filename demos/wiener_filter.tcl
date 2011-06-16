def op_Wiener_Filter {
    label {Wiener Filter }
    setup_image {
	variable L [base]
	UNMODIFIED 
    }
    setup {
	variable mean      0
	variable variance  0.005
    variable radius    2
	
	
	proc UNMODIFIED {} {
	    variable L  
	    variable temp
		
		set temp  $L
	    show_image  $temp
		return
	}

	proc NOISE { i } {
	    
		variable L  
		variable temp
	    variable mean     
	    variable variance  

		set temp  [crimp noise gaussian $L  $mean $variance ]  
	    show_image $temp
		return
	}

	proc WIENERFILTER { } {
	    
		variable temp
	    variable radius
	 
       set temp   [crimp filter wiener  $temp  $radius ]  
	   show_image    $temp
	   return

	    
	}

	ttk::button .top.unmo -text UNMODIFIED     -command ::DEMO::UNMODIFIED
	ttk::button .top.wifl -text WIENERFILTER   -command ::DEMO::WIENERFILTER

	scale .left.mean -variable ::DEMO::mean \
	    -from 0 -to 1 -resolution .005 -length 400\
	    -orient vertical \
	    -command ::DEMO::NOISE
		
    scale .left.variance -variable ::DEMO::variance \
	    -from 0 -to 0.1 -resolution .0005 -length 400\
	    -orient vertical \
	    -command ::DEMO::NOISE
	
	scale .left.radius -variable ::DEMO::radius \
	    -from 1 -to 10 -resolution 1 -length 100 \
	    -orient vertical 
		
    grid .top.unmo -row 0 -column 0 -sticky swen
	grid .top.wifl -row 0 -column 1 -sticky swen	
	
	grid .left.mean     -row 1 -column 0 -sticky swen
	grid .left.variance -row 1 -column 1 -sticky swen	
	grid .left.radius   -row 1 -column 2 -sticky swen
	
	
	
	
    }
}
