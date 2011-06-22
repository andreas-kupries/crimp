def op_Log_Polar {
    label {Log Polar Transform }
    active {
	expr {[bases] == 1}
    }
    setup_image {
	variable L [base]
	show
    }
    setup {
	variable hcentre  0
	variable vcentre  0 
	variable corner    1
	
	
	
	proc show {args} {
	    variable L

		
		variable hcentre  
	    variable vcentre   
	    variable corner   	    
        
		set disp [crimp transform logpolar $L  [::crimp::width $L] [::crimp::height $L] \
											   $hcentre  $vcentre \
											    $corner ]
           show_image     $disp
	        return
	}

	scale .left.hcentre -variable ::DEMO::hcentre \
	    -from -200 -to 200 -resolution 10 -length 200 \
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.vcentre -variable ::DEMO::vcentre \
	    -from -200 -to 200 -resolution 10 -length 200 \
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.corner -variable ::DEMO::corner \
	    -from 0 -to 1 -resolution 1 -length 10 \
	    -orient horizontal \
	    -command ::DEMO::show


	grid .left.hcentre -row 1 -column 0 -sticky swen
	grid .left.vcentre  -row 1 -column 1 -sticky swen
	
	grid .left.corner  -row 0 -column 1 -sticky swen
    

    }
}
