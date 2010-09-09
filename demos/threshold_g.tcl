def op_threshold_mg {
    label {Threshold Morph Gradient}
    setup_image {
	show_image [crimp alpha opaque \
			     [crimp threshold local [base] \
				  [crimp morph gradient \
				       [crimp convert 2grey8 [base]]]]]
    }
}
