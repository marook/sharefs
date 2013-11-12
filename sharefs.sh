#!/bin/bash

set -e

#==========================================================================
# the following constants can be overwritten in configuration files

ENCFS_OPTS="--standard"

RSYNC_OPTS="-az --bwlimit 100"

# flags whether synchronization should be executed while on battery power
# 0: only sync while on AC
# 1: always sync
SYNC_ON_BATTERY=0

# end of constants
#==========================================================================

fail()
{
    echo "$1" >&2
    echo "Aborting" >&2
    exit 1
}

print_usage()
{
    echo "usage: $0 <command>"
    echo ''
    echo "The supported commands are"
    echo "  $0 create target/dir [user@]host[:dir]"
    echo "  $0 mount target/dir"
    echo "  $0 umount target/dir"
    echo "  $0 sync target/dir"
    echo "  $0 help"
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

loadSystemConfig()
{
    for configFile in /etc/defaults/sharefs.conf ~/.sharefs/config
    do
	if [ -e "$configFile" ]
	then
	    . "$configFile"
	fi
    done
}

loadShareConfig()
{
    calcLocationVariables

    ensureExisting "$configFile"

    . "$configFile"

    calcRemoteVariables
}

loadSystemConfig

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

	loadShareConfig

	encfs $ENCFS_OPTS "$dataDir" "$targetDir"
	;;
    umount)
	# $ sharefs umount targetDir

	targetDir=$2

	# TODO validate arguments

	loadShareConfig

	fusermount -u "$targetDir"
	;;
    sync)
	# synchronize changes between local host and server
	# $ sharefs sync targetDir

	targetDir=$2

	# TODO validate arguments

	loadShareConfig

	if [ -e "$pidFile" ]
	then
	    lockPid=`cat $pidFile`

            if ps -p "$lockPid" > /dev/null
            then
	        fail "Process with ID $lockPid is already synchronizing"
            fi
	fi

	function cleanup()
	{
	    rm -f -- "$pidFile"
	}
	trap cleanup 0

	echo "$BASHPID" > "$pidFile"

	if [ "$SYNC_ON_BATTERY" == '1' -o `cat "/sys/class/power_supply/AC/online"` == "1" ]
	then
	    rsync $RSYNC_OPTS -e ssh "$dataDir" "$remoteDst"
	else
	    echo "Not synchronizing while on battery."
	fi

	cleanup
	;;
    help)
        print_usage
        ;;
    *)
	fail "Unknwon command \"$1\""
        print_usage
	;;
esac
