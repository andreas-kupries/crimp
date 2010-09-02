def op_convolve_crisp_ulis {
    label {Crisp (ulis)}
    setup {
	variable coeff 1
	variable K [crimp kernel make {
	    {0 0 0}
	    {0 8 0}
	    {0 0 0}}]

	proc show {thecoeff} {
	    set c [expr {1-$thecoeff}]
	    set m [expr {8*$thecoeff}]

	    variable K [crimp kernel make \
			    [list \
				 [list $c $c $c] \
				 [list $c $m $c] \
				 [list $c $c $c]]]

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
