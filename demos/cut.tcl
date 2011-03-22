def cut {
    label {Cut}
    setup_image {
	show_image [crimp cut [base] 50 50 50 50]

	puts [crimp dimensions [crimp cut [base] 50 50 50 50]]
    }
}
