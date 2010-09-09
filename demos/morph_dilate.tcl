def op_morph_dilate {
    label {Morphology: Dilate}
    setup_image {
	show_image [crimp alpha opaque [crimp morph dilate [base]]]
    }
}
