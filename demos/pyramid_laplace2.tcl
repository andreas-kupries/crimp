def op_pyramid_laplace2 {
    label {Laplace pyramid (normalized)}
    setup_image {
	# Create a laplacian image pyramid, aka difference of
	# gaussians. The results are scaled back to the original
	# before cycling.

	show_slides [apply {{images} {
	    set res {}
	    foreach \
		i $images \
		s {1 1 2 4 8 16 32 64} {
		    set i [norm $i $s]
		    lappend res [crimp alpha opaque $i]
		}
	    return $res
	} ::DEMO} [crimp pyramid laplace [base] 6]]
    }
    setup {
	proc norm {image fac} {
	    if {$fac == 1} { return $image }
	    set kernel [crimp kernel make {{1 4 6 4 1}} 8]
	    while {$fac > 1} {
		set image [crimp interpolate xy $image 2 $kernel]
		set fac [expr {$fac/2}]
	    }
	    return $image
	}
    }
}
