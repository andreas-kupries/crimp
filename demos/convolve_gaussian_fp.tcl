def op_convolve_gaussian_fp {
    label {Blur Gaussian FP}
    setup {
	variable sigma 1

	variable tables
	variable Kxs
	variable Kys

	variable tabled
	variable Kxd
	variable Kyd

	proc TABLE {sigma} {
	    TABLEs $sigma
	    TABLEd $sigma
	    return
	}

	# Reference: http://en.wikipedia.org/wiki/Scale_space_implementation

	proc TABLEs {sigma} {
	    variable tables
	    variable Kxs
	    variable Kys

	    set tables [crimp table fgauss sampled $sigma]
	    set Kxs    [crimp kernel fpmake $tables]
	    set Kys    [crimp kernel transpose $Kxs]

	    # Show the kernel...
	    #log [lreplace $Kx 2 2 $table]
	    return
	}

	proc TABLEd {sigma} {
	    variable tabled
	    variable Kxd
	    variable Kyd

	    set tabled [crimp table fgauss discrete $sigma]
	    set Kxd    [crimp kernel fpmake $tabled]
	    set Kyd    [crimp kernel transpose $Kxd]

	    # Show the kernel...
	    #log [lreplace $Kx 2 2 $table]
	    return
	}

	proc showp {} {
	    demo_time_hook g/plain {
		show_image [base]
	    }
	    return
	}

	proc shows {} {
	    demo_time_hook g/sample {
		variable Kxs
		variable Kys

		show_image [crimp filter convolve [base] $Kxs $Kys]
	    }
	    return
	}

	proc showd {} {
	    demo_time_hook g/discrete {
		variable Kxd
		variable Kyd

		show_image [crimp filter convolve [base] $Kxd $Kyd]
	    }
	    return
	}

	TABLE $sigma

	ttk::button .left.pl -text Plain -command ::DEMO::showp

	scale       .left.s -variable ::DEMO::sigma \
	    -from 0.1 -to 10 -resolution 0.1 \
	    -orient horizontal \
	    -command ::DEMO::TABLE

	plot        .left.ps -variable ::DEMO::tables -title {Kernel Sampled} -locked 0 -xlocked 0
	ttk::button .left.as -text Apply -command ::DEMO::shows

	plot        .left.pd -variable ::DEMO::tabled -title {Kernel Discrete} -locked 0 -xlocked 0
	ttk::button .left.ad -text Apply -command ::DEMO::showd

	grid .left.pl -row 0 -column 0 -sticky swen
	grid .left.s  -row 1 -column 0 -sticky swen
	grid .left.ps -row 2 -column 0 -sticky swen
	grid .left.as -row 3 -column 0 -sticky nw
	grid .left.pd -row 4 -column 0 -sticky swen
	grid .left.ad -row 5 -column 0 -sticky nw
    }
    setup_image {
	shows
    }
}
