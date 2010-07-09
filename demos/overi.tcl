def op_alpha_over_revers {
    label {Over Revers}
    setup {
	# We use the foreground image's luma as opacity (bright =
	# opaque, dark = transparent) to merge it with the background
	# image. At last we force fully opaque to avoid mix effects
	# against the canvas background color.

	show_image [crimp convert 2rgb \
			[crimp over \
			     [crimp setalpha [base 1] [crimp convert 2grey8 [base 1]]] \
			     [base 0]]]
    }
}
