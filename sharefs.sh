fail()
{
    echo "$1" >&2
    exit 1
}

case "$1" in
    create)
	# create a shared directory
	# $ sharefs create targetDir [user@]host[:dir]

	# TODO
	;;
    mount)
	# mount a shared directory
	# $ sharefs mount targetDir

	# TODO
	;;
    umount)
	# $ sharefs umount targetDir

	# TODO
	;;
    sync)
	# synchronize changes between local host and server
	# $ sharefs sync targetDir

	# TODO
	;;
    *)
	fail "Unknwon command \"$1\""
	;;
esac
