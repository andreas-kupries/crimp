def op_morph_egradient_grey {
    label {Morphology: External gradient /Grey}
    setup_image {
	show_image [crimp morph egradient [crimp convert 2grey8 [base]]]
    }
}
