def op_morph_close_grey {
    label {Morphology: Close /Grey}
    setup_image {
	show_image [crimp morph close [crimp convert 2grey8 [base]]]
    }
}
