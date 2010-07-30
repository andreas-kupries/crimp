def op_pyramid_laplace {
    label {Laplace pyramid}
    setup_image {
	# Create a laplacian image pyramid, aka difference of
	# gaussians and cycle through the results,

	show_slides [apply {{images} {
	    set res {}
	    foreach i $images {
		lappend res [crimp setalpha $i [crimp blank grey8 {*}[crimp dimensions $i] 255]]
	    }
	    return $res
	}} [crimp pyramid laplace [base] 3]]
    }
}
