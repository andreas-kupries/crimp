def op_connected_components_grey8 {
    label {Connected Components grey8}
    setup {
	proc showit {} {
	    variable L
	    set comps [crimp::connected_components_grey8 $L 0 0]
	    show_image [crimp::FITFLOAT [crimp convert 2float $comps]]
	    return
	}
    }
    setup_image {
	variable L [crimp convert 2grey8 [base]]
	showit
    }
}
