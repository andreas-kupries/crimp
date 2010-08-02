def op_decint2 {
    label "Decimate\u21932, Interpolate\u21912"
    setup {
	set KD [crimp kernel make {{1 2 1}}]
	set KI [crimp kernel make {{1 2 1}} 2]
    }
    setup_image {
	show_image [crimp alpha opaque \
			[crimp interpolate [crimp decimate [base] 2 $KD] 2 $KI]]
    }
}
