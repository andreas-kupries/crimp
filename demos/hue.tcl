def hsv_hue {
    label Hue
    setup {
	show_image [lindex [crimp split [crimp convert 2hsv [base]]] 0]
    }
}
