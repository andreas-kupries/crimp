def op_connected_components {
    label {Connected Components}
    setup {
	proc showit {} {
	    variable L
	    if {![info exists L]} return
	    set comps [crimp::connected_components $L 0]
	    show_image [crimp::FITFLOAT [crimp convert 2float $comps]]
	    return
	}
    }
    setup_image {
	variable L [crimp convert 2rgb [base]]
	showit
    }
}
