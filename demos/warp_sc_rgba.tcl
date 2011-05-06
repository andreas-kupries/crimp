def effect_warp_sc2_rgba {
    label {Warp/* rgba (Scale X/Y)}
    setup {
	variable sx 1
	variable sy 1

	proc border {i} {
	    crimp expand const $i \
		5 5 5 5 \
		0 0 255
	}

	proc show {args} {
	    variable sx
	    variable sy
	    variable i

	    set t [crimp transform scale $sx $sy]

	    lappend images [border [base]]
	    lappend images [border [crimp warp projective -interpolate nneighbour [base] $t]]
	    lappend images [border [crimp warp projective -interpolate bilinear   [base] $t]]
	    lappend images [border [crimp warp projective -interpolate bicubic    [base] $t]]

	    show_image [crimp montage horizontal -align top {*}$images]
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
