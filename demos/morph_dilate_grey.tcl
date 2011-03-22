def op_morph_dilate_grey {
    label {Morphology: Dilate /Grey}
    setup_image {
	show_image [crimp morph dilate [crimp convert 2grey8 [base]]]
    }
}
