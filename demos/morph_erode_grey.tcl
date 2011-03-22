def op_morph_erode_grey {
    label {Morphology: Erode /Grey}
    setup_image {
	show_image [crimp morph erode [crimp convert 2grey8 [base]]]
    }
}
