def op_convolve_blur_ulis {
    label {Blur (ulis)}
    setup {
	variable coeff 0
	variable K [crimp kernel make {
	    {0  0   0 0 0}
	    {0  0   0 0 0}
	    {0  0 800 0 0}
	    {0  0   0 0 0}
	    {0  0   0 0 0}}]

	proc show {thecoeff} {
	    set m [expr {800*(1-$thecoeff)}]
	    set c $thecoeff

	    variable K [crimp kernel make \
			    [list \
				 [list $c  0  0  0 $c] \
				 [list  0  0 $c  0  0] \
				 [list  0 $c $m $c  0] \
				 [list  0  0 $c  0  0] \
				 [list $c  0  0  0 $c]]]

	    show_image [crimp filter convolve [base] $K]
	    return
	}

	proc showit {} {
	    variable coeff
	    show $coeff
	    return
	}

	scale .left.s -variable ::DEMO::coeff \
	    -from 0 -to 100 -resolution 1 \
	    -orient vertical \
	    -command ::DEMO::show

	grid .left.s -row 0 -column 0 -sticky swen
    }
    setup_image {
	showit
    }
}
