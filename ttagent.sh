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

# Lock file configuration. Lock files are kept in the source root directory
TTLOCKFILE=$(dirname $(echo $1|sed 's/\/$//'))/.$(basename $(echo $1|sed 's/\/$//')).ttactive
WFLOCKFILE=$(dirname $(echo $1|sed 's/\/$//'))/.$(basename $(echo $1|sed 's/\/$//')).ttcomplete

# Check the main processing workflow lock on this to prevent future execution upon rescan.
if [ -e $WFLOCKFILE ]
then
    echo Workflow lock file present: $WFLOCKFILE
    echo Do you want to run the analysis again? If so, remove the lock file and try again.
    exit
else 

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
    echo ttagent: trigger $WORKFLOWEXE on receipt of $(echo $2|sed 's/\/$//')/$(basename $(echo $1|sed 's/\/$//'))/$(basename $3)
    
    # Loop until transfer is complete (trigger file is received safely)
    until [ -e $(echo $2|sed 's/\/$//')/$(basename $(echo $1|sed 's/\/$//'))/$(basename $3) ]
    do
	    echo sleeping $TTDELAY\s at $(date)
	    sleep $TTDELAY
	    rsync -avu --size-only --partial --progress $(echo $1|sed 's/\/$//')/ $(echo $2|sed 's/\/$//')/$(basename $(echo $1|sed 's/\/$//'))
    done


    # Final rsync just in case trigger file partially copied. 
    rsync -avu --size-only --partial --progress $(echo $1|sed 's/\/$//')/ $(echo $2|sed 's/\/$//')/$(basename $(echo $1|sed 's/\/$//'))

    # Trigger the main processing workflow and exit. Set a lock on this to prevent future execution upon rescan/transfer.
    echo Processing workflow started at $(date --rfc-3339='seconds') > $WFLOCKFILE
    # Can remove transfer and trigger lockfile if we get here
    rm -f $TTLOCKFILE

    # Call the Workflow execution script
    $WORKFLOWEXE $(echo $2|sed 's/\/$//')/$(basename $(echo $1|sed 's/\/$//'))
fi


