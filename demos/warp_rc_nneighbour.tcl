def effect_warp_rc_luma {
    label {Warp/NNe luma (Rotate around center)}
    setup {
	variable angle -150

	proc show {theangle} {
	    variable cx
	    variable cy
	    variable i

	    show_image [crimp warp projective -interpolate nneighbour \
			    $i [crimp transform rotate $theangle [list $cx $cy]]]
	    return
	}

	proc showit {} {
	    variable angle
	    show $angle
	    return
	}

	scale .left.s -variable ::DEMO::angle \
	    -from -180 -to 180 -resolution 0.01 \
	    -orient vertical \
	    -command ::DEMO::show

	pack .left.s -side left -fill both -expand 1
    }
    setup_image {
	variable i [crimp convert 2grey8 [base]]
	variable cx [expr {[crimp width  $i]/2.}]
	variable cy [expr {[crimp height $i]/2.}]
	showit
    }
}
