def op_FFT_check {
    label {FFT check }
    active {
	expr {[bases] == 0}
    }
    setup {
	variable original 0

	proc UNMODIFIED {} {
	    variable temp
	    variable original 1

	    set temp [crimp::black_white_vertical ]
	    show_image $temp
	    return
	}

	proc FFTFORWARD { } {
	    variable temp
	    variable original

	    if {$original} {
		set temp [::crimp::convert::2complex $temp]
	    }

	    set temp [::crimp::fft::forward $temp]
	    set original 0

	    show_image [::crimp::convert::2grey8 \
			    [crimp::complex::magnitude $temp]]
	    return
	}

	proc FFTBACKWARD { } {
	    variable temp
	    variable original

	    if {$original} {
		set temp [::crimp::convert::2complex $temp]
	    }

	    set temp [::crimp::fft::backward $temp]
	    set original 0

	    show_image [::crimp::convert::2grey8 \
			    [crimp::complex::magnitude $temp]]
	    return
	}

	ttk::button .top.unmo        -text Reset     -command ::DEMO::UNMODIFIED
	ttk::button .top.fftforward  -text FFT       -command ::DEMO::FFTFORWARD
	ttk::button .top.fftbackward -text {inv FFT} -command ::DEMO::FFTBACKWARD

	grid .top.unmo        -row 0 -column 0 -sticky swen
	grid .top.fftforward  -row 0 -column 1 -sticky swen
	grid .top.fftbackward -row 0 -column 2 -sticky swen

	# Initialize.
	UNMODIFIED
    }
}
