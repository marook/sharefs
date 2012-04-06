fail()
{
    echo "$1" >&2
    echo "Aborting" >&2
    exit 1
}

ensureNotExisting()
{
    if [ -e "$1" ]
    then
	fail "$1 already existing"
    fi
}

case "$1" in
    create)
	# create a shared directory
	# $ sharefs create targetDir [user@]host[:dir]

	targetDir=$2
	remoteDst=$3

	# TODO validate arguments

	targetName=`basename "$targetDir"`
	shadowDir=$targetDir/../.$targetName.sharefs
	configFile=$shadowDir/config
	dataDir=$shadowDir/data
	remoteAccount=`echo $remoteDst | sed 's/\([^:]*\):\(.*\)/\1/'`
	remoteDir=`echo $remoteDst | sed 's/\([^:]*\):\(.*\)/\2/'`

	if [ -z "$remoteAccount" -o -z "$remoteDir" ]
	then
	    fail "Invalid remote destination format: $remoteDst"
	fi

	ensureNotExisting "$targetDir"
	ensureNotExisting "$shadowDir"

	ssh "$remoteAccount" "test -e $remoteDir" && fail "Remote directory already exists: $remoteDst"

	# TODO validate remote dst not yet exists

	mkdir "$targetDir"
	mkdir "$shadowDir"
	mkdir "$dataDir"

	echo "remoteDst=$remoteDst" > $configFile

	# TODO create remote dst

	echo "shadow: $shadowDir"

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
