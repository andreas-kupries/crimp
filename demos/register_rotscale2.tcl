def op_register_rotscale_2 {
    label {Register Images: Rot/Scale (only), plain}
    active {
	expr {[bases] == 1};	# What's this?
    }
    setup_image {
	show
    }
    setup {
	variable angle 33
	variable scale 1
	variable aout {}
	variable sout {}

	proc rotate_and_scale {image angle scale} {
	    # Generate two images from the input, which are translated
	    # relative to each other, by the specified deltas. They
	    # also get a bit of noise mixed into them, to make the
	    # task of registering them more difficult.

	    set scale [expr {1./$scale}]
	    log ==========================================
	    log grey

	    set image [crimp convert 2grey8 $image]

	    log warp\t$angle\t$scale

	    # The needle is derived from the original image by
	    # rotation and scaling. To avoid the original's borders we
	    # then cut a 100x100 piece from the center.
	    set needle [::crimp::warp::projective $image \
			    [::crimp::transform::chain \
				 [::crimp::transform::rotate $angle] \
				 [::crimp::transform::scale  $scale $scale]]]

	    lassign [crimp::dimensions $needle] w h
	    set needle [crimp::cut $needle \
			    [expr {$w/2 - 50}] [expr {$h/2 - 50}] 100 100]

	    log noise

	    # Put in some noise
	    set image  [crimp::noise::gaussian $image  0 0.01]
	    set needle [crimp::noise::gaussian $needle 0 0.01]

	    return [list $needle $image]
	}

	proc SHOW {args} {
	    variable token
	    catch { after cancel $token }
	    set token [after idle DEMO::show]
	    return
	}

	proc show {} {
	    # args = scale slider info, ignored.

	    # slider locations
	    variable angle
	    variable scale

	    # result output, gui
	    variable aout
	    variable sout

	    lassign [rotate_and_scale [base] $angle $scale] a b

	    show_image [crimp::montage::horizontal $a $b]

	    log register

	    lassign [crimp register rotscale $a $b] _ ax _ sx

	    set aout [format %.2f $ax]
	    set sout [format %.2f $sx]

	    log OK
	    return
	}

	label .left.xlabel -text Angle
	label .left.ylabel -text Scale

	scale .left.angle -variable ::DEMO::angle \
	    -from -180 -to 180 -resolution 0.1 \
	    -length 300 -orient vertical \
	    -command ::DEMO::SHOW

	scale .left.scale -variable ::DEMO::scale \
	    -from 0.2 -to 20 -resolution 0.1 \
	    -length 300 -orient vertical \
	    -command ::DEMO::SHOW

	label .left.aout -textvariable ::DEMO::aout
	label .left.sout -textvariable ::DEMO::sout

	grid .left.xlabel .left.ylabel 
	grid .left.angle .left.scale -sticky ns
	grid .left.aout .left.sout
    }
}
