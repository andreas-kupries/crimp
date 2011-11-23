def op_alpha_over_revers_translated {
    label {Over Revers/Translated}
    active { expr { [bases] == 2 } }
    setup_image {
	# We use the foreground image's luma as opacity (bright =
	# opaque, dark = transparent) to merge it with the background
	# image. At last we force fully opaque to avoid mix effects
	# against the canvas background color.

	show_image [crimp convert 2rgb \
			[crimp alpha over \
			     [crimp place \
				  [crimp alpha set \
				       [base 1] \
				       [crimp convert 2grey8 [base 1]]] \
				  60 70] \
			     [crimp place [base 0] -50 -50]]]
    }
}
