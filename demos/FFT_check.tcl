def op_FFT_check {
    label {FFT check }
    active {
	expr {[bases] == 0}
    }
    setup {
	
	
	proc UNMODIFIED {} {
	    
		variable temp
		variable i 
		set    i   0
		
		set temp  [crimp::black_white_vertical ]
	    show_image  $temp  
		return
	}

	proc FFTFORWARD { } {
	    
		variable temp
	    variable i 
		
		if { $i eq 0 } {
		set   temp [::crimp::fft::forward \
                      [::crimp::fpcomop::2fpcomplex \
                         [::crimp::convert::2float $temp ] ] ]
		} else {
		set   temp [::crimp::fft::forward $temp ] 
		}
		
		set i 1
		
		show_image [::crimp::convert::2grey8 \
		           [crimp::fpcomop::magnitude  $temp ]]
		return
	}
   proc FFTBACKWARD { } {
	    
		variable temp
	       
		variable i 
		
		if { $i eq 0 } {
		set   temp [::crimp::fft::backward \
                      [::crimp::fpcomop::2fpcomplex \
                         [::crimp::convert::2float $temp ] ] ]
		} else {
		set   temp [::crimp::fft::backward $temp ] 
		}
		
		set i 1
		
        
	    show_image [::crimp::convert::2grey8 \
		           [crimp::fpcomop::magnitude  $temp ]]
		return
	}

	
	

	ttk::button .top.unmo        -text CLICK_ME     -command ::DEMO::UNMODIFIED
	ttk::button .top.fftforward  -text FFTFORWARD   -command ::DEMO::FFTFORWARD
	ttk::button .top.fftbackward -text FFTBACKWARD  -command ::DEMO::FFTBACKWARD
	
	
	grid .top.unmo        -row 0 -column 0 -sticky swen
	grid .top.fftforward  -row 0 -column 1 -sticky swen
	grid .top.fftbackward -row 0 -column 2 -sticky swen
	
	
	
	
	
    }
}
