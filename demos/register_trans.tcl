def op_register_translation {
    label {Register Images: Translation (only), +intermediates}
    active {
	expr {[bases] == 1};	# What's this?
    }
    setup_image {
	show
    }
    setup {
	variable xshift 90
	variable yshift 30
	variable xsol {}
	variable ysol {}

	proc translate {image dx dy} {
	    # Generate two images from the input, which are translated
	    # relative to each other, by the specified deltas. They
	    # also get a bit of noise mixed into them, to make the
	    # task of registering them more difficult.

	    set image [crimp convert 2grey8 $image]

	    if {$dx > 0} {
		set x1 $dx
		set x2 0
	    } else {
		set x2 [expr {-$dx}]
		set x1 0
	    }
	    if {$dy > 0} {
		set y1 $dy
		set y2 0
	    } else {
		set y2 [expr {-$dy}]
		set y1 0
	    }

	    # A and B are the first and second images, with the second
	    # displaced with respect to the first.

	    set a [crimp::expand replicate $image $x1 $y1 $x2 $y2]
	    set b [crimp::expand replicate $image $x2 $y2 $x1 $y1]

	    # Put in some noise
	    set a [crimp::noise::gaussian $a 0 0.1]
	    set b [crimp::noise::gaussian $b 0 0.1]

	    return [list $a $b]
	}

	# This code is a replica of crimp::register::translation,
	# modified to keep and then display all (important)
	# intermediate images.

	proc register {a b} {
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

	    # FA and FB are the Fourier transforms of the windowed inputs.
	    # TODO - We need 2-d real-to-complex FFT!

	    set fa [crimp::fft::forward [crimp::convert::2complex $wa]]
	    set fb [crimp::fft::forward [crimp::convert::2complex $wb]]

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
	    #		FFT A		FFT B	(log domain!)
	    #		C AMP		C PHASE

	    show_image [crimp::montage::vertical \
			    [crimp::montage::horizontal $a $b] \
			    [crimp::FITFLOAT [crimp::montage::horizontal $wa $wb]] \
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

	    # Compute location for MAX, and show. Not part of the proc
	    # result however.
	    lassign [dict get $st channel value min@] dx dy
	    set dx [fixdelta $dx $w]
	    set dy [fixdelta $dy $h]
	    log "P min dx/dy = $dx $dy"

	    # Locate the peak, the maximum correlation telling us the translation.
	    lassign [dict get $st channel value max@] dx dy
	    set dx [fixdelta $dx $w]
	    set dy [fixdelta $dy $h]

	    log "P max dx/dy = $dx $dy"

	    set st [crimp statistics basic [crimp::FITFLOAT $cphase]]
	    log "Q max  = [format %.11f [dict get $st channel luma max]] @ [dict get $st channel luma max@]"
	    log "Q min  = [format %.11f [dict get $st channel luma min]] @ [dict get $st channel luma min@] ****"

	    # We may have to flip the sign of dx/dy, depending on
	    # which of the images A and B we see as the dixed
	    # base/reference and which as translated.

	    return [list $dx $dy]
	}

	proc fixdelta {dx w} {
	    # **** Values are _unsigned_ in the range 0 to image width/height. ****
	    # **** Convert to signed. ****

	    if {$dx > $w/2} { set dx [expr {$dx - $w}] }
	    return $dx
	}

	proc show {args} {
	    # args = scale slider info, ignored.

	    # slider locations
	    variable xshift
	    variable yshift

	    # result output, gui
	    variable xsol
	    variable ysol

	    lassign [translate [base] $xshift $yshift] a b
	    lassign [register $a $b] xsol ysol
	    return
	}

	label .left.xlabel -text X
	label .left.ylabel -text Y

	scale .left.xshift -variable ::DEMO::xshift \
	    -from -150 -to 150 -resolution 1 \
	    -length 300 -orient vertical \
	    -command ::DEMO::show

	scale .left.yshift -variable ::DEMO::yshift \
	    -from -150 -to 150 -resolution 1 \
	    -length 300 -orient vertical \
	    -command ::DEMO::show

	label .left.xsol -textvariable ::DEMO::xsol
	label .left.ysol -textvariable ::DEMO::ysol

	grid .left.xlabel .left.ylabel 
	grid .left.xshift .left.yshift -sticky ns
	grid .left.xsol .left.ysol
    }
}
