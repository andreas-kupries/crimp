def op_pyramid_gauss2 {
    label {Gauss pyramid (normalized)}
    setup_image {
	# Create an image pyramid, and then scale the result back up
	# to match the original one before cycling.

	show_slides [apply {{images} {
	    set res {}
	    foreach \
		i $images \
		s {1 2 4 8 16 32 64} {
		    lappend res [norm $i $s]
		}
	    return $res
	} ::DEMO} [crimp pyramid gauss [base] 6]]
    }
    setup {
	proc norm {image fac} {
	    if {$fac == 1} { return $image }
	    set kernel [crimp kernel make {{1 4 6 4 1}} 8]
	    while {$fac > 1} {
		set image [crimp interpolate $image 2 $kernel]
		set fac [expr {$fac/2}]
	    }
	    return $image
	}
    }
}
