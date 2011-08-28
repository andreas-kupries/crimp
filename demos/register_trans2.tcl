def op_register_translation_2 {
    label {Register Images: Translation (only), plain}
    active {
	expr {[bases] == 1};	# What's this?
    }
    setup_image {
	show
    }
    setup {
	variable xshift 90
	variable yshift 30
	variable xsol {}
	variable ysol {}

	proc translate {image dx dy} {
	    # Generate two images from the input, which are translated
	    # relative to each other, by the specified deltas. They
	    # also get a bit of noise mixed into them, to make the
	    # task of registering them more difficult.

	    set image [crimp convert 2grey8 $image]

	    if {$dx > 0} {
		set x1 $dx
		set x2 0
	    } else {
		set x2 [expr {-$dx}]
		set x1 0
	    }
	    if {$dy > 0} {
		set y1 $dy
		set y2 0
	    } else {
		set y2 [expr {-$dy}]
		set y1 0
	    }

	    # A and B are the first and second images, with the second
	    # displaced with respect to the first.

	    set a [crimp::expand replicate $image $x1 $y1 $x2 $y2]
	    set b [crimp::expand replicate $image $x2 $y2 $x1 $y1]

	    # Put in some noise
	    set a [crimp::noise::gaussian $a 0 0.1]
	    set b [crimp::noise::gaussian $b 0 0.1]

	    return [list $a $b]
	}

	proc show {args} {
	    # args = scale slider info, ignored.

	    # slider locations
	    variable xshift
	    variable yshift

	    # result output, gui
	    variable xsol
	    variable ysol

	    lassign [translate [base] $xshift $yshift] a b

	    show_image [crimp::montage::horizontal $a $b]

	    lassign [crimp register translation $a $b] _ xsol _ ysol
	    return
	}

	label .left.xlabel -text X
	label .left.ylabel -text Y

	scale .left.xshift -variable ::DEMO::xshift \
	    -from -150 -to 150 -resolution 1 \
	    -length 300 -orient vertical \
	    -command ::DEMO::show

	scale .left.yshift -variable ::DEMO::yshift \
	    -from -150 -to 150 -resolution 1 \
	    -length 300 -orient vertical \
	    -command ::DEMO::show

	label .left.xsol -textvariable ::DEMO::xsol
	label .left.ysol -textvariable ::DEMO::ysol

	grid .left.xlabel .left.ylabel 
	grid .left.xshift .left.yshift -sticky ns
	grid .left.xsol .left.ysol
    }
}
