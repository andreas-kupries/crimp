def op_Window_function {
    label {Window Function }
    active {
	expr {[bases] == 1}
    }
    setup_image {
	variable L  [base]
	show
    }
    setup {
		
	proc show {args} {
	    variable L
        	

	   show_image    [::crimp::window $L ]  
	        return
	}

	}
}
