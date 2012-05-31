def geometry {
    label {Geometry}
    setup_image {
	set image [base]
	log "[join [crimp dimensions $image] x] @ [join [crimp at $image] ,]"
	set image [crimp place [crimp cut $image 50 50 50 40] 5 -1]
	log "[join [crimp dimensions $image] x] @ [join [crimp at $image] ,]"
    }
}
