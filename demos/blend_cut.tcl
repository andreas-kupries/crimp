def op_blend_cut {
    label {Blend Cut}
    active {
	expr {
	      ([bases] == 2) &&
	      ([crimp dimensions [base 0]] eq [crimp dimensions [base 1]])
	  }
    }
    setup_image {
	# Get the images to blend.
	variable left  [base 0]
	variable right [base 1]

	variable w
	variable h
	lassign [crimp dimensions [base 0]] w h
	set w [expr {$w/2}]

	# Should be easier via cut/crop+montage...

	variable result [crimp montage horizontal \
			     [crimp cut $left   0 0 $w $h] \
			     [crimp cut $right $w 0 $w $h]]

	show_image $result
	return
    }
}
