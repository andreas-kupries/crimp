def read_strimj {
    label {Read (strimj)}
    active {
	expr {[bases] == 0}
    }
    setup {
	show_image [crimp read strimj [fileutil::cat $dir/images/hello.strimj]]
    }
}
