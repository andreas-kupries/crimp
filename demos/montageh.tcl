def op_montageh {
    label {Montage Left/Right}
    active {
	expr { [bases] > 1 }
    }
    setup_image {
	show_image [crimp montage horizontal {*}[thebases]]
    }
}
