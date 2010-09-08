def op_morph_tophatb_grey {
    label {Morphology: Tophat:Black /Grey}
    setup_image {
	show_image [crimp morph tophatb [crimp convert 2grey8 [base]]]
    }
}
