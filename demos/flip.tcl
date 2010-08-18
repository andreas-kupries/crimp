def op_flip_vertical {
    label {Flip Chaining}
    setup {
	proc show {} {
	    variable image
	    show_image $image
	}
	proc do {args} {
	    variable image
	    set image [crimp {*}$args $image]
	    show
	    return
	}

	button .left.h  -text \u2191\u2193 -command [list [namespace current]::do flip vertical]
	button .left.v  -text \u2194       -command [list [namespace current]::do flip horizontal]
	button .left.tp -text \\           -command [list [namespace current]::do flip transpose]
	button .left.tv -text /            -command [list [namespace current]::do flip transverse]

	grid .left.h  -row 0 -column 0
	grid .left.v  -row 1 -column 0
	grid .left.tp -row 2 -column 0
	grid .left.tv -row 3 -column 0
    }
    setup_image {
	variable image [base]
	show
    }
}
