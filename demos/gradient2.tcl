def op_gradient2 {
    label {Gradient De-Grey}
    active {
	expr {[bases] == 1}
    }
    setup_image {
	variable grey [crimp convert 2grey8 [base]]
	show
    }
    setup {
	variable sr 0
	variable sg 0
	variable sb 0

	variable er 255
	variable eg 255
	variable eb 255

	proc show {args} {
	    variable grey

	    variable sr
	    variable sg
	    variable sb

	    variable er
	    variable eg
	    variable eb

	    set g [crimp gradient rgb \
		       [list $sr $sg $sb] \
		       [list $er $eg $eb] \
		       256]

	    set gi [crimp flip transpose $g]
	    set gi [crimp montage horizontal $gi $gi] ;# 2
	    set gi [crimp montage horizontal $gi $gi] ;# 4
	    set gi [crimp montage horizontal $gi $gi] ;# 8
	    set gi [crimp montage horizontal $gi $gi] ;# 16
	    set gi [crimp montage horizontal $gi $gi] ;# 32
	    set gi [crimp montage horizontal $gi $gi] ;# 64
	    set gi [crimp expand const $gi 5 5 5 5]

	    show_image [crimp montage horizontal -align top \
			    $gi \
			    [crimp convert 2rgb $grey $g]]
	    return
	}

	scale .left.sr -variable ::DEMO::sr \
	    -from 0 -to 255 \
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.sg -variable ::DEMO::sg \
	    -from 0 -to 255 \
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.sb -variable ::DEMO::sb \
	    -from 0 -to 255 \
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.er -variable ::DEMO::er \
	    -from 0 -to 255 \
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.eg -variable ::DEMO::eg \
	    -from 0 -to 255 \
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.eb -variable ::DEMO::eb \
	    -from 0 -to 255 \
	    -orient vertical \
	    -command ::DEMO::show

	grid .left.sr -row 0 -column 0 -sticky swen
	grid .left.sg -row 0 -column 1 -sticky swen
	grid .left.sb -row 0 -column 2 -sticky swen

	grid .left.er -row 1 -column 0 -sticky swen
	grid .left.eg -row 1 -column 1 -sticky swen
	grid .left.eb -row 1 -column 2 -sticky swen
    }
}
