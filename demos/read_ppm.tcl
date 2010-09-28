def read_ppm1 {
    label {Read (PPM 1)}
    active {
	expr {[bases] == 0}
    }
    setup {
	set K [crimp kernel make {{0 1 1}} 1]
	proc 8x {image} {
	    variable K
	    return [crimp interpolate [crimp interpolate [crimp interpolate $image 2 $K] 2 $K] 2 $K]
	}
	show_image [8x [8x [crimp read ppm [fileutil::cat $dir/images/blink.ppm]]]]
    }
}
