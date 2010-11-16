def effect_warp_field_rgba {
    label {Warp/BiL rgba (Fuzz Field)}
    setup {
	variable fuzz 5
	variable mode bilinear

	proc rand {} {
	    variable fuzz
	    expr {$fuzz*(rand()*2-1)}
	}

	proc field {dim} {
	    variable fuzzf
	    lassign $dim w h
	    # Generate a random fuzzing field, simulating glass with
	    # high random scattering of light going through it.

	    set xv {}
	    set yv {}
	    for {set y 0} {$y < $h} {incr y} {
		set xvr {}
		set yvr {}
		for {set x 0} {$x < $w} {incr x} {
		    lappend xvr [expr {$x + [rand]}]
		    lappend yvr [expr {$y + [rand]}]
		}
		lappend xv $xvr
		lappend yv $yvr
	    }

	    set fuzzf [list \
			   [crimp read tcl float $xv] \
			   [crimp read tcl float $yv]]
	    return
	}

	proc showit {} {
	    variable fuzzf
	    variable mode
	    show_image [crimp warp field -interpolate $mode [base] {*}$fuzzf]
	    return
	}

	proc showf {} {
	    field [crimp dimensions [base]]
	    showit
	    return
	}

	proc show {args} {
	    variable idle
	    catch   { after cancel $idle }
	    set idle [after idle ::DEMO::showf]
	    return
	}

	proc mode {m} {
	    variable mode $m
	    showit
	    return
	}

	scale .left.s -variable ::DEMO::fuzz \
	    -from 0 -to 40 -resolution 1 \
	    -orient vertical \
	    -command ::DEMO::show

	button .top.nn -text nNeighbour -command {::DEMO::mode nneighbour}
	button .top.li -text 2linear    -command {::DEMO::mode bilinear}
	button .top.cu -text 2cubic     -command {::DEMO::mode bicubic}

	pack .left.s -side left -fill both -expand 1

	pack .top.nn -side left -fill y
	pack .top.li -side left -fill y
	pack .top.cu -side left -fill y
    }
    setup_image {
	showf
    }
}
