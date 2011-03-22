def op_morph_tophatw_grey {
    label {Morphology: Tophat:White /Grey}
    setup_image {
	show_image [crimp morph tophatw [crimp convert 2grey8 [base]]]
    }
}
