def effect_rgb2hsv2rgb {
    label "RGB \u2192 HSV \u2192 RGB"
    setup {
	show_image [crimp convert 2rgba [crimp convert 2hsv [base]]]
    }
}
