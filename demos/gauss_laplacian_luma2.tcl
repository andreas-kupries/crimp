def op_gauss_laplacian_luma {
    label {IIR Laplacian of Gaussian Luma}
    setup {
	variable sigma 1.5

	proc show {thesigma} {
	    variable L
	    if {![info exists L]} return
	    show_image \
		[crimp::FITFLOAT \
		     [crimp::gaussian_laplacian_float $L $thesigma]]
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
