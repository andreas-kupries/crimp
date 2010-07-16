def op_convolve {
    label Convolve
    setup_image {
	show_image [crimp convolve \
			[base] \
			{   {2  4  5  4 2}
			    {4  9 12  9 4}
			    {5 12 15 12 5}
			    {4  9 12  9 4}
			    {2  4  5  4 2}}]
    }
}
