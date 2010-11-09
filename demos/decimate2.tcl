def op_decimate2 {
    label Decimate\u21932
    setup {
	set K [crimp kernel make {{1 2 1}}]
    }
    setup_image {
	show_image [crimp alpha opaque [crimp decimate xy [base] 2 $K]]
    }
}
