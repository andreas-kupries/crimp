def write_pgmraw {
    label {Write (PGM/raw)}
    setup_image {
	crimp write 2pgmraw $dir/written.pgm \
	    [crimp convert 2grey8 [base]]
    }
}
