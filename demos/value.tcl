def hsv_value {
    label Value
    setup {
	show_image [lindex [crimp split [crimp convert 2hsv [base]]] 2]
    }
}
