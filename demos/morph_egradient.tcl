def op_morph_egradient {
    label {Morphology: External gradient}
    setup_image {
	show_image [crimp alpha opaque [crimp morph egradient [base]]]
    }
}
