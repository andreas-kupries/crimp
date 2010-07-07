def effect_matrix {
    label RotMatrix
    setup {
	scale .s -from -180 -to 180 -resolution 0.01 \
	    -orient vertical -command [list ::apply {{angle} {
		set s [expr {sin($angle * 0.017453292519943295769236907684886)}]
		set c [expr {cos($angle * 0.017453292519943295769236907684886)}]
		set matrix [list \
				[list $c           $s 0] \
				[list [expr {-$s}] $c 0] \
				[list $s           $s 1]]
		#puts matrix...
		show_image [crimp matrix [base] $matrix]
	    }}]

	extendgui .s
    }
    shutdown {
	destroy .s
    }
}
