def op_decimate2 {
    label Decimate\u21932
    setup {
	set K [crimp kernel make {{1 2 1}}]
    }
    setup_image {
	set n [crimp decimate [base] 2 $K]
	set m [crimp blank grey8 {*}[crimp dimensions $n] 255]
	show_image [crimp setalpha $n $m]
    }
}
