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

	button .left.med1 -text {Median 20}  -command {::DEMO::median 20}
	button .left.med2 -text {Median 50}  -command {::DEMO::median 50}
	button .left.med3 -text {Median 100} -command {::DEMO::median 100}
	button .left.med4 -text {Median 200} -command {::DEMO::median 200}
	button .left.med5 -text {Median 300} -command {::DEMO::median 300}
	button .left.med6 -text {Median 400} -command {::DEMO::median 400}
	button .left.med7 -text {Median 500} -command {::DEMO::median 500}
	button .left.med8 -text {Median 1K}  -command {::DEMO::median 1000}

	grid .left.med1 -row 0 -column 0 -sticky swen
	grid .left.med2 -row 1 -column 0 -sticky swen
	grid .left.med3 -row 2 -column 0 -sticky swen
	grid .left.med4 -row 4 -column 0 -sticky swen
	grid .left.med5 -row 5 -column 0 -sticky swen
	grid .left.med6 -row 6 -column 0 -sticky swen
	grid .left.med7 -row 7 -column 0 -sticky swen
	grid .left.med8 -row 8 -column 0 -sticky swen
    }
    setup_image {
	showit
    }
}
