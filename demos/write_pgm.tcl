def write_pgm {
    label {Write (PGM/plain)}
    setup_image {
	crimp write 2pgmplain $dir/written.pgm \
	    [crimp convert 2grey8 [base]]
    }
}
