def effect_warp_sc_rgba {
    label {Warp/NNe rgba (Scale X/Y)}
    setup {
	variable sx 1
	variable sy 1

	proc show {args} {
	    variable sx
	    variable sy
	    variable i

	    show_image [crimp warp projective -interpolate nneighbour \
			    [base] [crimp transform scale $sx $sy]]
	    return
	}

	scale .left.sx -variable ::DEMO::sx \
	    -from 0.01 -to 5 -resolution 0.01 \
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.sy -variable ::DEMO::sy \
	    -from 0.01 -to 5 -resolution 0.01 \
	    -orient vertical \
	    -command ::DEMO::show

	pack .left.sx -side left -fill both -expand 1
	pack .left.sy -side left -fill both -expand 1
    }
    setup_image {
	show
    }
}
