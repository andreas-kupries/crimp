def write_pgm {
    label {Write (PGM/plain)}
    setup_image {
	log "Destination [appdir]/written.pgm"
	crimp write 2file pgm-plain [appdir]/written.pgm [base]
    }
}
