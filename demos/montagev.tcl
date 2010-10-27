def op_montagev {
    label {Montage Top/Bottom}
    active {
	expr { [bases] > 1 }
    }
    setup_image {
	show_image [crimp montage vertical {*}[thebases]]
    }
}
