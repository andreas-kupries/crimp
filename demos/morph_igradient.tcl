def op_morph_igradient {
    label {Morphology: Internal gradient}
    setup_image {
	show_image [crimp alpha opaque [crimp morph igradient [base]]]
    }
}
