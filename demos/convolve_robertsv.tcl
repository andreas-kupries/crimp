def op_convolve_robertsv {
    label {Roberts Vertical}
    setup_image {
	show_image [crimp alpha opaque [crimp filter roberts x [base] ]]
    }
}
