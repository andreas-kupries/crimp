def op_add {
    label Add
    active {
	expr {
	      ([bases] == 2) &&
	      ([crimp dimensions [base 0]] eq [crimp dimensions [base 1]])
	  }
    }
    setup_image {
	show
    }
    setup {
	variable scale  1
	variable offset 0

	proc show {args} {
	    variable scale
	    variable offset

	    show_image [crimp alpha opaque [crimp add [base 0] [base 1] $scale $offset]]
	    return
	}

	scale .left.s -variable ::DEMO::scale  -from 1 -to 255 -orient vertical -command ::DEMO::show
	scale .left.o -variable ::DEMO::offset -from 0 -to 255 -orient vertical -command ::DEMO::show

	pack .left.s -side left -expand 1 -fill both
	pack .left.o -side left -expand 1 -fill both
    }
}
