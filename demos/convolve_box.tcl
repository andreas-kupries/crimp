def op_convolve_box {
    label {Box Blur}
    setup {
	variable K [crimp kernel {
	    {1 1 1 1 1}
	    {1 1 1 1 1}
	    {1 1 1 1 1}
	    {1 1 1 1 1}
	    {1 1 1 1 1}}]

	# Separable kernel, compute the horizontal and vertical kernels.
	variable Kx [crimp kernel {{1 1 1 1 1}}]
	variable Ky [crimp tkernel $Kx]
    }
    setup_image {
	#show_image [crimp convolve [base] $K]
	# Separable kernel, convolve x and y separately. Same result
	# as above, faster.
	show_image [crimp convolve [crimp convolve [base] $Kx] $Ky]

	# Convolution times (butterfly 800x600), regular and separated by x/y.
	#             seconds  u-seconds/pixel
	# -----       -------- ---------------------
	# Setup       0.000337 0.0007020833333333333  Kx/Ky
	# Setup Image 0.773904 1.6123
	# -----       -------- ---------------------
	# Setup       0.000333 0.00069375             K
	# Setup Image 1.640612 3.4179416666666667
	# -----       -------- ---------------------

	#show_image [crimp difference \
			[crimp convolve [base] $K] \
			[crimp convolve [crimp convolve [base] $Kx] $Ky] \
		       ]
    }
}
