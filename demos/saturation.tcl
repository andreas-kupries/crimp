def hsv_saturation {
    label Saturation
    setup_image {
	show_image [lindex [crimp split [crimp convert 2hsv [base]]] 1]
    }
}
