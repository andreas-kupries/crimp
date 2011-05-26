def op_gauss_laplacian_luma3 {
    label {IIR LoG Luma (Tcl)}
    setup {
	variable sigma 1.5

	proc show {thesigma} {
	    variable L
	    if {![info exists L]} return
	    set xderiv2 [crimp::gaussian_01_float \
			    [crimp::gaussian_10_float $L 2 $thesigma] \
			    0 $thesigma]
	    set yderiv2 [crimp::gaussian_10_float \
			    [crimp::gaussian_01_float $L 2 $thesigma] \
			    0 $thesigma]
	    show_image \
		[crimp::FITFLOAT \
		     [crimp::add $xderiv2 $yderiv2]]
	    return
	}

	proc showit {} {
	    variable sigma
	    show $sigma
	    return
	}

	scale .left.s -variable ::DEMO::sigma \
	    -from 0.1 -to 60 -resolution 0.1 -length 450 \
	    -orient vertical \
	    -command ::DEMO::show

	grid .left.s -row 0 -column 0 -sticky swen
    }
    setup_image {
	variable L [crimp convert 2float [crimp convert 2grey8 [base]]]
	showit
    }
}
