def write_ppmraw {
    label {Write (PPM/raw)}
    setup_image {
	log "Destination [appdir]/written.ppm"
	crimp write 2file ppm-raw [appdir]/written.ppm [base]
    }
}
