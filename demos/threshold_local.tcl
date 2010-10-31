def op_threshold_local {
    label "Threshold Local"
    setup {
	variable threshold [crimp blank grey8 {*}[crimp dimensions [base]] 0]

	proc show {thethreshold} {
	    # NOTE: thethreshold is an image.
	    #
	    # base[] >= threshold[] => BLACK
	    # base[] <  threshold[] => WHITE

	    show_image [crimp invert \
			    [crimp alpha opaque \
				 [crimp threshold local [base] \
				      $thethreshold]]]
	    return
	}

	proc showbase {} {
	    show_image [base]
	    return
	}

	proc otsu {} {
	    show_image [crimp threshold global otsu [base]]
	    return
	}

	proc showit {} {
	    variable threshold
	    show $threshold
	    return
	}

	# Demo various ways of for the automatic calculation of a
	# local threshold.

	# Compute a median filtered version of the input, use this as
	# threshold. I.e. if a pixel is greater than the median at its
	# location we go black, else white. This has an obvious
	# parameter, the filter radius, i.e. the size of the
	# environment aroiund the a pixel the median is taken from. If
	# this approaches the image size the thresholding will
	# asymptotically converge on a single global threshold. Making
	# the radius smaller on the other hand wil more and more fail
	# to smooth out small-scale fluctuations.
	#
	# Note our use of a mirror border, this avoids problems with a
	# constant border warping the local histograms towards black,
	# white, etc.

	proc median {n} {
	    variable threshold
	    set threshold [crimp filter rank \
			       [crimp convert 2grey8 [base]] \
			       -border mirror $n]
	    showit
	    return
	}

	# Use the local mean as threshold.

	proc mean {n} {
	    variable threshold
	    set threshold [crimp filter mean [crimp convert 2grey8 [base]]]
	    showit
	    return
	}

	# niblack's method: T = M + k*S, k a parameter, M = locval
	# mean, S = local standard deviation. Here k = 0.2. 2nd param
	# is the usual radius.

	proc niblack {n} {
	    variable threshold
	    set k 0.2

	    set i   [crimp convert 2grey8 [base]]
	    lassign [crimp::BORDER grey8 mirror] fe values
	    lassign [crimp::filter::MEAN_STDDEV $i $n $fe $values] m s

	    set threshold [crimp convert 2grey8 [crimp add $m [crimp::scale_float $s $k]]]
	    showit
	    return
	}

	proc niblack2 {n} {
	    variable threshold
	    set k -0.2

	    set i   [crimp convert 2grey8 [base]]
	    lassign [crimp::BORDER grey8 mirror] fe values
	    lassign [crimp::filter::MEAN_STDDEV $i $n $fe $values] m s

	    set threshold [crimp convert 2grey8 [crimp add $m [crimp::scale_float $s $k]]]
	    showit
	    return
	}

	# sauvola's method: T = M * (1 + k*(S/R - 1)).
	#                     = M + M*k*(S/R - 1)
	#                     = M + M*k*S/R - M*k
	#
	# M = local mean, S = local standard deviation.
	# R = dynamic range for S, here 128
	# k = 2nd parameter, here = 0.34

	proc sauvola {n} {
	    variable threshold
	    set k 0.2

	    set i   [crimp convert 2grey8 [base]]
	    lassign [crimp::BORDER grey8 mirror] fe values
	    lassign [crimp::filter::MEAN_STDDEV $i $n $fe $values] m s

	    set sr [crimp::scale_float $s [expr {1./128}]] ;# S/R
	    set mk [crimp::scale_float $m $k]              ;# M*k

	    set threshold [crimp convert 2grey8 [crimp subtract [crimp add $m [crimp multiply $mk $sr]] $mk]]
	    showit
	    return
	}

	proc sauvola2 {n} {
	    variable threshold
	    set k 0.5

	    set i   [crimp convert 2grey8 [base]]
	    lassign [crimp::BORDER grey8 mirror] fe values
	    lassign [crimp::filter::MEAN_STDDEV $i $n $fe $values] m s

	    set sr [crimp::scale_float $s [expr {1./128}]] ;# S/R
	    set mk [crimp::scale_float $m $k]              ;# M*k

	    set threshold [crimp convert 2grey8 [crimp subtract [crimp add $m [crimp multiply $mk $sr]] $mk]]
	    showit
	    return
	}

	# GUI. Grid of buttons.

	button .left.base -text Base -command ::DEMO::showbase -bg lightgreen
	grid   .left.base -row 0 -column 0 -sticky swen

	button .left.otsu -text Otsu -command ::DEMO::otsu -bg lightblue
	grid   .left.otsu -row 0 -column 1 -sticky swen

	foreach {b label cmd col startrow} {
	    med  Median   median   0 1
	    mean Mean     mean     1 1
	    nib  Niblack  niblack  0 10
	    sau  Sauvola  sauvola  1 10
	    nbx  Niblack* niblack2 0 20
	    sax  Sauvola* sauvola2 1 20
	} {
	    set r $startrow
	    foreach n {10 20 50 100 200 300 400 500 1000} {
		button .left.${b}$r -text "$label $n" -command [list ::DEMO::$cmd $n]
		grid .left.${b}$r -row $r -column $col -sticky swen
		incr r
	    }
	}
    }
    setup_image {
	showbase
    }
}
