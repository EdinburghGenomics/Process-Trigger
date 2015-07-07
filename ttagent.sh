#!/bin/bash
# 
# ttagent.sh (transfer and trigger agent) continuously monitors a partial
# dataset directory and stages that to the compute platform by looping
# rsync with a small delay. It will stop looping when the "trigger file" is
# received, indicating the completion of the dataset directory.
# 
# usage: ttagent.sh <source dir> <dest root dir> <trigger file> 
#

source config.sh

dataset=$1
procroot=$2
trigger=$3

function rstrip {
  echo `sed 's/\/$//' $1`
}

function do_rsync {
  rsync -avu --size-only --partial $(echo $1|rstrip)/ $(echo $2|rstrip)/$(basename $(echo $1|rstrip))
}

# Lock file configuration. Lock files are kept in the source root directory
TTLOCKFILE=$(dirname $(echo $dataset|rstrip))/.$(basename $(echo $dataset|rstrip)).ttactive
WFLOCKFILE=$(dirname $(echo $dataset|rstrip))/.$(basename $(echo $dataset|rstrip)).ttcomplete

# Check the main processing workflow lock on this to prevent future execution upon rescan.
echo "[ttagent] Checking for workflow-complete lock files"
if [ -e $WFLOCKFILE ]
then
    echo Workflow lock file present: $WFLOCKFILE
    echo Do you want to run the analysis again? If so, remove the lock file and try again.
    exit
else 

    echo "[ttagent] Checking for workflow-active lock files"
    # First set a transfer lock to prevent simultaneous execution of ttagent.
    if [ -e $TTLOCKFILE ]
    then
        echo Lock file present - is another $(basename $0) running? If not, remove the lock file and try again.
        exit
    else 
        echo Setting lock file: $TTLOCKFILE
        touch $TTLOCKFILE
    fi


    # Announce trigger
    echo "[ttagent] trigger $WORKFLOWEXE on receipt of $(echo $procroot|rstrip)/$(basename $(echo $dataset|rstrip))/$(basename $trigger)"
    
    # Loop until transfer is complete (trigger file is received safely)
    until [ -e $(echo $procroot|rstrip)/$(basename $(echo $dataset|rstrip))/$(basename $trigger) ]
    do
	    echo "[ttagent] Sleeping $TTDELAY\s ($(date))"
	    sleep $TTDELAY
	    do_rsync $dataset $procroot
    done

    # Final rsync just in case trigger file partially copied. 
    do_rsync $dataset $procroot

    # Trigger the main processing workflow and exit. Set a lock on this to prevent future execution upon rescan/transfer.
    echo "[ttagent] Processing workflow started at $(date --rfc-3339='seconds')"
    echo Processing workflow started at $(date --rfc-3339='seconds') > $WFLOCKFILE
    # Can remove transfer and trigger lockfile if we get here
    rm -f $TTLOCKFILE

    # Call the Workflow execution script
    $WORKFLOWEXE $(echo $procroot|rstrip)/$(basename $(echo $dataset|rstrip))
fi

echo "[ttagent] Done"

