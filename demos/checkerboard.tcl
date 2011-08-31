def op_checkerboard {
    label {Checker board}
    active {
	expr {[bases] == 0}
    }
    setup {
	show_image [crimp::black_white_vertical]
    }
}
