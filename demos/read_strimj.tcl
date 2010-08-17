def read_strimj {
    label {Read (strimj)}
    setup {
	show_image [crimp read strimj [fileutil::cat $dir/images/hello.strimj]]
    }
}
