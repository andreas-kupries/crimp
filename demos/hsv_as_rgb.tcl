def effect_hsv_as_rgb {
    label {HSV as RGB}
    setup_image {
	show_image [crimp join 2rgb {*}[crimp split [crimp convert 2hsv [base]]]]
    }
}
