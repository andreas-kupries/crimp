def effect_warp_rc2_rgba {
    label {Warp/BiC rgba (Rotate around center)}
    setup {
	variable angle -150

	proc show {theangle} {
	    variable cx
	    variable cy

	    show_image [crimp warp projective -interpolate bicubic [base] \
			    [crimp transform rotate $theangle [list $cx $cy]]]
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
	variable cx [expr {[crimp width  [base]]/2.}]
	variable cy [expr {[crimp height [base]]/2.}]

	showit
    }
}
