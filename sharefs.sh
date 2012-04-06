set -e

fail()
{
    echo "$1" >&2
    echo "Aborting" >&2
    exit 1
}

ensureExisting(){
    if [ ! -e "$1" ]
    then
	fail "$1 is missing"
    fi
}

ensureNotExisting()
{
    if [ -e "$1" ]
    then
	fail "$1 already existing"
    fi
}

calcLocationVariables()
{
    if [ -e "$targetDir" ]
    then
	targetDir=`cd "$targetDir" ; pwd`
    fi

    targetName=`basename "$targetDir"`
    shadowDir=$targetDir/../.$targetName.sharefs
    configFile=$shadowDir/config
    pidFile=$shadowDir/lock.pid

    dataDir=$shadowDir/data
    if [ -e "$dataDir" ]
    then
	dataDir=`cd "$dataDir" ; pwd`
    fi
}

calcRemoteVariables()
{
    remoteAccount=`echo $remoteDst | sed 's/\([^:]*\):\(.*\)/\1/'`
    remoteDir=`echo $remoteDst | sed 's/\([^:]*\):\(.*\)/\2/'`

    if [ -z "$remoteAccount" -o -z "$remoteDir" ]
    then
	fail "Invalid remote destination format: $remoteDst"
    fi
}

loadConfig()
{
    calcLocationVariables

    ensureExisting "$configFile"

    . "$configFile"

    calcRemoteVariables
}

case "$1" in
    create)
	# create a shared directory
	# $ sharefs create targetDir [user@]host[:dir]

	targetDir=$2
	remoteDst=$3

	# TODO validate arguments

	calcLocationVariables
	calcRemoteVariables

	ensureNotExisting "$targetDir"
	ensureNotExisting "$shadowDir"

	ssh "$remoteAccount" "mkdir $remoteDir" || fail "Failed to create remote directory: $remoteDst"

	mkdir "$targetDir"
	mkdir "$shadowDir"
	mkdir "$dataDir"

	echo "remoteDst=$remoteDst" > $configFile
	;;
    mount)
	# mount a shared directory
	# $ sharefs mount targetDir

	targetDir=$2

	# TODO validate arguments

	loadConfig

	encfs --standard "$dataDir" "$targetDir"
	;;
    umount)
	# $ sharefs umount targetDir

	targetDir=$2

	# TODO validate arguments

	loadConfig

	fusermount -u "$targetDir"
	;;
    sync)
	# synchronize changes between local host and server
	# $ sharefs sync targetDir

	targetDir=$2

	# TODO validate arguments

	loadConfig

	if [ -e "$pidFile" ]
	then
	    lockPid=`cat $pidFile`
	    fail "Process with ID $lockPid is already synchronizing"
	fi

	function cleanup()
	{
	    rm -f -- "$pidFile"
	}
	trap cleanup 0

	echo "$BASHPID" > "$pidFile"

	sleep 10

	rsync -az -e ssh "$dataDir" "$remoteDst"

	cleanup
	;;
    *)
	fail "Unknwon command \"$1\""
	;;
esac
