def op_Registration_rotscale {
    label {Registration_rotscale }
    active {
	expr {[bases] == 1}
    }
    setup_image {
	variable  image1 [base] 
	variable angle 90
	variable scale 0.4
	
	
	show
    }
    setup {
		
	
	proc show {args} {
	    
		variable  image1
        variable  angle
        variable  scale
		
		set transcale   [::crimp::transform scale $scale $scale ] 
        set tranrotate  [::crimp::transform rotate $angle ]
        set transform   [::crimp::transform::chain $transcale $tranrotate ]
        set image2      [::crimp::warp::projective $image1 $transform]
		
			
		set statstrans [::crimp::register::rotscale $image1 $image2 ]
	    log "\n\n"
	    log $statstrans
		set disp [::crimp::montage::horizontal $image1 $image2 ]
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
		
   	grid .left.angle     -row 0 -column 0 -sticky swen
	grid .left.scale     -row 0 -column 1 -sticky swen
		
	
    }
}
