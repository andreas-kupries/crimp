def read_pgm {
    label {Read (PGM)}
    setup {
	show_image [crimp read pgm [fileutil::cat $dir/images/feep.pgm]]
    }
}
