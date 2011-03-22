def op_blank {
    label Blank
    active {
	expr {[bases] == 0}
    }
    setup {
	variable r 0
	variable g 0
	variable b 0

	proc show {args} {
	    variable r
	    variable g
	    variable b

	    show_image [crimp blank rgba 800 600 $r $g $b 255]
	    return
	}

	scale .left.r -variable ::DEMO::r \
	    -from 0 -to 255 \
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.g -variable ::DEMO::g \
	    -from 0 -to 255 \
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.b -variable ::DEMO::b \
	    -from 0 -to 255 \
	    -orient vertical \
	    -command ::DEMO::show

	grid .left.r -row 0 -column 0 -sticky swen
	grid .left.g -row 0 -column 1 -sticky swen
	grid .left.b -row 0 -column 2 -sticky swen
    }
}
