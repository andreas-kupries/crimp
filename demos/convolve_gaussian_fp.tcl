def op_convolve_gaussian_fp {
    label {Blur Gaussian FP}
    setup {
	package require math::special
	package require math::constants
	math::constants::constants pi

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
	    variable pi

	    # Reference: http://en.wikipedia.org/wiki/Scale_space_implementation#The_sampled_Gaussian_kernel
	    # G(x,sigma) =  1/sqrt(2*t*pi)*e^(-x^2/(2*t))
	    # where t = sigma^2

	    # Compute upper half of the kernel (0...3*sigma).
	    set tables {}

	    set scale  [expr {1.0 / ($sigma * sqrt(2 * $pi))}]
	    set escale [expr {2 * $sigma ** 2}]
	    for {set x 0} {$x <= (3*$sigma)} {incr x} {
		lappend tables [expr {$scale * exp(-($x**2/$escale))}]
	    }

	    # And reflect to get the lower half, join the two.
	    # This also ensures that the kernel is odd-sized.
	    if {[llength $tables] > 1} {
		set tables [linsert $tables 0 {*}[lreverse [lrange $tables 1 end]]]
	    }

	    set Kxs [crimp kernel fpmake $tables]
	    set Kys [crimp kernel transpose $Kxs]

	    # Show the kernel...
	    #log [lreplace $Kx 2 2 $table]
	    return
	}

	proc TABLEd {sigma} {
	    variable tabled
	    variable Kxd
	    variable Kyd

	    # Reference: http://en.wikipedia.org/wiki/Scale_space_implementation#The_discrete_Gaussian_kernel
	    # G(x,sigma) = e^(-t)*I_x(t), where t = sigma^2
	    # and I_x = Modified Bessel function of Order x

	    # Compute upper half of the kernel (0...3*sigma).
	    set tabled {}
	    set t [expr {$sigma ** 2}]
	    for {set x 0} {$x <= (3*$sigma)} {incr x} {
		lappend tabled [expr {exp(-$t)*[math::special::I_n $x $t]}]
	    }

	    # And reflect to get the lower half, join the two.
	    # This also ensures that the kernel is odd-sized.
	    if {[llength $tabled] > 1} {
		set tabled [linsert $tabled 0 {*}[lreverse [lrange $tabled 1 end]]]
	    }

	    set Kxd [crimp kernel fpmake $tabled]
	    set Kyd [crimp kernel transpose $Kxd]

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
	    -from 0 -to 10 -resolution 0.1 \
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
