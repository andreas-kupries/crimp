def op_resize {
    label Resize/Thumbnail
    setup {
    }
    setup_image {
	log [crimp type [base]]
	show_image [crimp alpha opaque [crimp resize [base] 160 120]]
    }
}
