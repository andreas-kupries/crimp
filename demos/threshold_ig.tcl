def op_threshold_img {
    label {Threshold Invers Morph Gradient}
    setup_image {
	show_image [crimp alpha opaque \
			     [crimp threshold local [base] \
				  [crimp invert \
				       [crimp morph gradient \
					    [crimp convert 2grey8 [base]]]]]]
    }
}
