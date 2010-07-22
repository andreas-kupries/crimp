def op_convolve_box {
    label {Blur Box}
    setup {
	variable K [crimp kernel make {
	    {1 1 1 1 1}
	    {1 1 1 1 1}
	    {1 1 1 1 1}
	    {1 1 1 1 1}
	    {1 1 1 1 1}}]

	# Separable kernel, compute the horizontal and vertical kernels.
	variable Kx [crimp kernel make {{1 1 1 1 1}}]
	variable Ky [crimp kernel transpose $Kx]
    }
    setup_image {
	# show_image [crimp convolve [base] $K]
	# Separable kernel, convolve x and y separately. Same result
	# as for the combined kernel, but faster.
	show_image [crimp convolve [base] $Kx $Ky]

	# Convolution times (butterfly 800x600), regular and separated by x/y.
	#             seconds  u-seconds/pixel
	# -----       -------- ---------------------
	# Setup       0.000337 0.0007020833333333333  Kx/Ky
	# Setup Image 0.773904 1.6123
	# -----       -------- ---------------------
	# Setup       0.000333 0.00069375             K
	# Setup Image 1.640612 3.4179416666666667
	# -----       -------- ---------------------

	# Show that the two applications generate the same result.
	#show_image [crimp difference [crimp convolve [base] $K] [crimp convolve [base] $Kx $Ky]]
    }
}
