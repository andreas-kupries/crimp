def op_add {
    label Add
    active {
	expr {
	      ([bases] == 2) &&
	      ([crimp dimensions [base 0]] eq [crimp dimensions [base 1]])
	  }
    }
    setup_image {
	variable mask [crimp blank grey8 {*}[crimp dimensions [base]] 255]
	show
    }
    setup {
	variable scale  1
	variable offset 0
	variable mask   {}

	proc show {args} {
	    variable scale
	    variable offset
	    variable mask

	    show_image [crimp setalpha \
			    [crimp add [base 0] [base 1] $scale $offset] \
			    $mask]
	    return
	}

	scale .left.s -variable ::DEMO::scale  -from 1 -to 255 -orient vertical -command ::DEMO::show
	scale .left.o -variable ::DEMO::offset -from 0 -to 255 -orient vertical -command ::DEMO::show

	pack .left.s -side left -expand 1 -fill both
	pack .left.o -side left -expand 1 -fill both
    }
}
