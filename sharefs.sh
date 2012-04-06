fail()
{
    echo "$1" >&2
    exit 1
}

case "$1" in
mount)

;;
unmount)

;;
*)
	fail "Unknwon command \"$1\""
;;
esac
