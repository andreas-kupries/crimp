def op_blank {
    label Blank
    active {
	expr {[bases] == 0}
    }
    setup {
	show_image [crimp blank rgba 800 600 0 0 0 255]
    }
}
