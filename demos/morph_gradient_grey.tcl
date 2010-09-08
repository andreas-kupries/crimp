def op_morph_gradient_grey {
    label {Morphology: Gradient /Grey}
    setup_image {
	show_image [crimp morph gradient [crimp convert 2grey8 [base]]]
    }
}
