def op_decimate4 {
    label Decimate\u21934
    setup {
	set K [crimp kernel make {{1 2 1}}]
    }
    setup_image {
	show_image [crimp alpha opaque \
			[crimp decimate xy \
			     [crimp decimate xy [base] 2 $K] \
			     2 $K]]
    }
}
