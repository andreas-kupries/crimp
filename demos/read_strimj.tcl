def read_strimj {
    label {Read (strimj)}
    active {
	expr {[bases] == 0}
    }
    setup {
	set K [crimp kernel make {{0 1 1}} 1]
	proc 8x {image} {
	    variable K
	    return [crimp interpolate xy [crimp interpolate xy [crimp interpolate xy $image 2 $K] 2 $K] 2 $K]
	}
	show_image [8x [8x [crimp read strimj [fileutil::cat [appdir]/images/hello.strimj]]]]
    }
}
