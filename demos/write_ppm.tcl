def write_ppm {
    label {Write (PPM/plain)}
    setup_image {
	log "Destination [appdir]/written.ppm"
	crimp write 2file ppm-plain [appdir]/written.ppm [base]
    }
}
