def op_convolve_gaussian {
    label {Gaussian Blur}
    setup {
	variable K [crimp kernel {
	    {2  4  5  4 2}
	    {4  9 12  9 4}
	    {5 12 15 12 5}
	    {4  9 12  9 4}
	    {2  4  5  4 2}}]
    }
    setup_image {
	show_image [crimp convolve [base] $K]
    }
}
