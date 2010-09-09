def op_morph_erode {
    label {Morphology: Erode}
    setup_image {
	show_image [crimp alpha opaque [crimp morph erode [base]]]
    }
}
