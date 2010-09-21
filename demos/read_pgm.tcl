def read_pgm {
    label {Read (PGM)}
    active {
	expr {[bases] == 0}
    }
    setup {
	show_image [crimp read pgm [fileutil::cat $dir/images/feep.pgm]]
    }
}
