def expand_extend {
    label {Expand Extend}
    setup_image {
	set extended [crimp expand extend [base] 50 50 50 50]
	set opaque   [crimp blank grey8 {*}[crimp dimensions $extended] 255]

	show_image [crimp setalpha $extended $opaque]
    }
}
