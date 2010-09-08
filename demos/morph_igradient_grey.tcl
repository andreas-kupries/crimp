def op_morph_igradient_grey {
    label {Morphology: Internal gradient /Grey}
    setup_image {
	show_image [crimp morph igradient [crimp convert 2grey8 [base]]]
    }
}
