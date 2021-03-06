def op_alpha_over {
    label Over
    active { expr { [bases] == 2 } }
    setup_image {
	# We use the foreground image's luma as opacity (bright =
	# opaque, dark = transparent) to merge it with the background
	# image. At last we force fully opaque to avoid mix effects
	# against the canvas background color.

	show_image [crimp convert 2rgb \
			[crimp alpha over \
			     [crimp alpha set \
				  [base] \
				  [crimp convert 2grey8 [base]]] \
			     [base 1]]]
    }
}
