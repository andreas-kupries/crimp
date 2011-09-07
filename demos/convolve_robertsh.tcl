def op_convolve_robertsh {
    label {Roberts Horizontical}
    
    setup_image {
	show_image [crimp alpha opaque [crimp filter roberts y [base] ]]
    }
}
