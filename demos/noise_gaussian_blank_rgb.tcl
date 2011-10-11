def op_Noise_Gaussian_BlankRGB {
    label {Noise - Gaussian / Blank, RGB}
    active {
	expr {[bases] == 0}
    }
    setup_image {
	show
    }
    setup {
	variable mean      0
	variable variance  0.005
	variable base      [crimp blank rgb 5 5 128 128 128]

	set K [crimp kernel make {{0 1 1}} 1]
	proc 8x {image} {
	    variable K
	    return [crimp interpolate xy [crimp interpolate xy [crimp interpolate xy $image 2 $K] 2 $K] 2 $K]
	}

	proc show {args} {
	    variable mean
	    variable variance
	    variable base

	    show_image [8x [8x [crimp noise gaussian $base $mean $variance]]]
	    return
	}

	scale .left.mean -variable ::DEMO::mean \
	    -from 0 -to 1 -resolution .005 -length 400\
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.variance -variable ::DEMO::variance \
	    -from 0 -to 1 -resolution .005 -length 400\
	    -orient vertical \
	    -command ::DEMO::show

	grid .left.mean     -row 0 -column 0 -sticky swen
	grid .left.variance -row 0 -column 1 -sticky swen
    }
}
