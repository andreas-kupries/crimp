def op_metadata {
    label {Meta data}
    active {
	expr {[bases] == 0}
    }
    setup {
	variable x [crimp blank grey8 5 5 0]

	log d|[crimp meta get $x]|

	set x [crimp meta lappend $x ppm something]

	log d|[crimp meta get $x]|
	log k|[crimp meta keys $x p*]|
    }
}
