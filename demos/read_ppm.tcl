def read_ppm {
    label {Read (PPM)}
    active {
	expr {[bases] == 0}
    }
    setup {
	show_image [crimp read ppm [fileutil::cat $dir/images/blink.ppm]]
    }
}
