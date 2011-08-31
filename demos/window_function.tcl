def op_window_function {
    label {Window Function}
    setup_image {
	show
    }
    setup {
	proc show {args} {
	    show_image [::crimp::window [base]]
	    return
	}
    }
}
