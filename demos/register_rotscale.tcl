def op_register_rotscale {
    label {Register Images: Rot/Scale, +intermediates}
    active {
	expr {[bases] == 1};	# What's this?
    }
    setup_image {
	show
    }
    setup {
	package require math::constants
	math::constants::constants pi

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

	# This code is a replica of crimp::register::rotscale,
	# modified to keep and then display all (important)
	# intermediate images.

	proc register {a b} {
	    variable pi
	    # The registration process starts with windowing the input images.

	    log =========================================================
	    log "A [crimp::dimensions $a]"
	    log "B [crimp::dimensions $b]"

	    lassign [::crimp::matchsize $a $b] a b
	    lassign [::crimp::dimensions $a] w h

	    set wa [crimp::convert::2float $a]
	    set wb [crimp::convert::2float $b]

	    set wa [crimp::window $wa]
	    set wb [crimp::window $wb]

	    # LA and LB are the log-polar transforms of the windowed inputs.

	    set la [::crimp::transform::logpolar $wa 360 400]
	    set lb [::crimp::transform::logpolar $wb 360 400]

	    # FA and FB are the Fourier transforms of the log-polar transforms.
	    # TODO - We need 2-d real-to-complex FFT!

	    set fa [crimp::fft::forward [crimp::convert::2complex $la]]
	    set fb [crimp::fft::forward [crimp::convert::2complex $lb]]

	    # MA and MB are the magnitudes of the components of FA and FB
	    set ma [crimp::complex::magnitude $fa]
	    set mb [crimp::complex::magnitude $fb]

	    # denom is MA*MB; numer is conj(FA)*FB

	    set denom [crimp::convert::2complex [crimp::multiply $ma $mb]]
	    set numer [crimp::multiply $fb [crimp::complex::conjugate $fa]]

	    # numer is also the amplitude-phase correlation; whereas
	    # numer/denom is the proper phase-correlation.

	    set correl [crimp::divide $numer $denom]

	    # CAMP and CPHASE are the two correlations converted back
	    # into the pixel domain.

	    set camp   [::crimp::convert_2float_fpcomplex [crimp::fft::backward $numer]]
	    set cphase [::crimp::convert_2float_fpcomplex [crimp::fft::backward $correl]]

	    # For debugging we now show all the inputs, intermediate
	    # images, and results. The return value is the translation data however.

	    # We show	left		right
	    #		Input A		Input B
	    #		Input A		Input B	(windowed)
	    #		log-polar A	log-polar B
	    #		FFT A		FFT B	(log domain!)
	    #		C AMP		C PHASE

	    show_image [crimp::montage::vertical \
			    [crimp::montage::horizontal $a $b] \
			    [crimp::FITFLOAT [crimp::montage::horizontal $wa $wb]] \
			    [crimp::FITFLOAT [crimp::montage::horizontal $la $lb]] \
			    [crimp::FITFLOAT [crimp::montage::horizontal \
						  [crimp::log_float $ma] \
						  [crimp::log_float $mb]]] \
			    [crimp::montage::horizontal \
				 [crimp::FITFLOAT $camp] \
				 [crimp::FITFLOAT $cphase]]]

	    set st [crimp statistics basic $camp]
	    log "A max  = [format %.11f [dict get $st channel value max]] @ [dict get $st channel value max@]"
	    log "A min  = [format %.11f [dict get $st channel value min]] @ [dict get $st channel value min@]"

	    set st [crimp statistics basic $cphase]
	    log "P max  = [format %.11f [dict get $st channel value max]] @ [dict get $st channel value max@] ****"
	    log "P min  = [format %.11f [dict get $st channel value min]] @ [dict get $st channel value min@]"

	    # Compute location for MIN, and show. Not part of the proc
	    # result however.
	    lassign [dict get $st channel value min@] dx dy
	    log "P min dx/dy = $dx $dy"

	    # Locate the peak, the maximum correlation telling us the translation.
	    lassign [dict get $st channel value max@] dx dy
	    log "P max dx/dy = $dx $dy"

	    set st [crimp statistics basic [crimp::FITFLOAT $cphase]]
	    log "Q max  = [format %.11f [dict get $st channel luma max]] @ [dict get $st channel luma max@]"
	    log "Q min  = [format %.11f [dict get $st channel luma min]] @ [dict get $st channel luma min@] ****"

	    # Convert the translation parameters operating on the
	    # log-polar intermediates into angle and scale for the
	    # inputs.

	    if {$dx < (360-$dx)} {
		set angle [expr {- $dx}]
	    } else {
		set angle [expr {360 - $dx}]
	    }

	    if {$dy < (400 - $dy)} {
		set scale [expr {exp (($dy * 2 * $pi) / 360.) }]
	    } else {
		set scale [expr {1. / (exp (((400 - $dy) * 2 * $pi) / 360.))}]
	    }

	    log "P max angle $angle, scale $scale"

	    return [list $angle $scale]
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

	    log register/rot-scale

	    lassign [register $a $b] ax sx

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
