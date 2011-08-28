def op_Registration_complete {
    label {Registration_Complete }
    active {
	expr {[bases] == 1}
    }
    setup_image {
	variable  image1 [base] 
	variable angle 90
	variable scale 0.4
	variable xshift 100
	
	show
    }
    setup {
		
	
	proc show {args} {
	    
		variable  image1
        variable  angle
        variable  scale
		variable  xshift
        
	
		set tranrotate  [::crimp::transform rotate [expr {360 -$xshift } ] ]
        set image2      [::crimp::warp::projective $image1 $tranrotate ]
		
        set lpt1 [crimp::transform::logpolar $image1 360 360 ]
        set lpt2 [crimp::transform::logpolar $image2 360 360 ]
		
		set transcale   [::crimp::transform scale $scale $scale ] 
        set tranrotate  [::crimp::transform rotate $angle ]
        set transform   [::crimp::transform::chain $transcale $tranrotate ]
        set lpt2        [::crimp::warp::projective $lpt2 $transform]
		
			
		set statstrans [::crimp::register::complete $lpt1 $lpt2 ]
	    log "\n\n"
	    log $statstrans
		set disp [::crimp::montage::horizontal $lpt1 $lpt2 ]
           show_image     $disp
	        return
	}

	scale .left.angle -variable ::DEMO::angle \
	    -from 0 -to 360 -resolution 10 -length 360\
	    -orient vertical \
	    -command ::DEMO::show
	
	scale .left.scale -variable ::DEMO::scale \
	    -from 0 -to 2 -resolution .2 -length 10\
	    -orient vertical \
	    -command ::DEMO::show
		
	scale .left.xshift -variable ::DEMO::xshift \
	    -from 0 -to 360 -resolution 10 -length 360\
	    -orient vertical \
	    -command ::DEMO::show
		
   	grid .left.xshift    -row 0 -column 0 -sticky swen	
   	grid .left.angle     -row 0 -column 1 -sticky swen
	grid .left.scale     -row 0 -column 2 -sticky swen
		
	
    }
}
