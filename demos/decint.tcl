def op_decint2 {
    label "Decimate\u21932, Interpolate\u21912"
    setup {
	set KD [crimp kernel make {{1 2 1}}]
	set KI [crimp kernel make {{1 2 1}} 2]
    }
    setup_image {
	set n [crimp interpolate \
		   [crimp decimate [base] 2 $KD] \
		   2 $KI]
	set m [crimp blank grey8 {*}[crimp dimensions $n] 255]
	show_image [crimp setalpha $n $m]
    }
}
