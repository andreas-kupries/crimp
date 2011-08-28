def op_Registration_translation {
    label {Registration_translation }
    active {
	expr {[bases] == 1}
    }
    setup_image {
	variable  image1 [base] 
	variable xshift 90
	
	show
    }
    setup {
	
	
	proc show {args} {
	    
	    variable  image1
	    variable  xshift
	    
	    set tranrotate  [::crimp::transform rotate [expr {360 - $xshift } ] ] 
	    set image2      [::crimp::warp::projective $image1 $tranrotate]
	    
	    set lpt1 [crimp::transform::logpolar $image1 360 360 ]
	    set lpt2 [crimp::transform::logpolar $image2 360 360 ]
	    

	    
	    set statstrans [::crimp::imregs::translation $lpt1 $lpt2 ]
	    log "\n\n"
	    log $statstrans
	    set disp [::crimp::montage::horizontal $lpt1 $lpt2 ]
	    show_image     $disp
	    return
	}

	scale .left.xshift -variable ::DEMO::xshift \
	    -from 0 -to 360 -resolution 10 -length 360\
	    -orient vertical \
	    -command ::DEMO::show
	
   	grid .left.xshift     -row 0 -column 0 -sticky swen
	
	
    }
}
