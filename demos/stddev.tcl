def op_stddev {
    label {Stddev Filter}
    setup_image {
	# Create a series of stddev-filtered images from the base,
	# with different kernel radii.

	set g [crimp convert 2grey8 [base]]

	proc P {g r} {
	    # NOTE: The std deviation is usually small, and plain
	    # conversion to grey will most likely yield a uniform
	    # black display. So, for the purposes of actually seeing
	    # something we stretch the result to 0..255 (assuming that
	    # the regular result is 0..1. Think about calculating the
	    # basic statistics for float images too, so that we can
	    # use the proper max to compute the stretch factor.
	    crimp convert 2grey8 \
		[crimp::scale_float \
		     [crimp filter stddev $g $r] \
		     255]
	}

	# radius => window
	#  1 - 3x3
	#  2 - 5x5
	#  3 - 7x7
	# 10 - 21x21
	# 20 - 41x41

	show_slides [list \
			 $g \
			 [P $g 1] \
			 [P $g 2] \
			 [P $g 3] \
			 [P $g 10] \
			 [P $g 20]]
    }
}
