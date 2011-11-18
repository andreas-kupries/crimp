def write_pgmraw {
    label {Write (PGM/raw)}
    setup_image {
	log "Destination [appdir]/written.pgm"
	crimp write 2file pgm-raw [appdir]/written.pgm [base]
    }
}
