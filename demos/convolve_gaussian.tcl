def op_convolve_gaussian {
    label {Blur Gaussian}
    setup {
	variable K [crimp kernel make {
	    {1  2  4  2 1}
	    {2  4  8  4 2}
	    {4  8 16  8 4}
	    {2  4  8  4 2}
	    {1  2  4  2 1}}]

	# Separable kernel, compute the horizontal and vertical kernels.
	variable Kx [crimp kernel make {{1 2 4 2 1}}]
	variable Ky [crimp kernel transpose $Kx]
    }
    setup_image {
	# show_image [crimp filter convolve [base] $K]
	# Separable kernel, convolve x and y separately. Same result
	# as for the combined kernel, but faster.
	show_image [crimp filter convolve [base] $Kx $Ky]
    }
}
