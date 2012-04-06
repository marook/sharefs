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
    targetDir=`cd "$targetDir" ; pwd`
    targetName=`basename "$targetDir"`
    shadowDir=$targetDir/../.$targetName.sharefs
    configFile=$shadowDir/config
    dataDir=`cd "$shadowDir/data" ; pwd`
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

	# TODO
	;;
    *)
	fail "Unknwon command \"$1\""
	;;
esac
