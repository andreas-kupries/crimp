def read_ppm {
    label {Read (PPM)}
    setup {
	show_image [crimp read ppm [fileutil::cat $dir/images/blink.ppm]]
    }
}
