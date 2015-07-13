#!/bin/bash
# Status: Beta - development/testing. Handed over to Edinburgh Genomics.
#
# Description: Run proctrigger.sh to pickup new inbound datasets and trigger processing.
# Usage: proctrigger.sh [ createnewtest | filltest | completetest | report | rescan ]
# Run without arguments to stage data and trigger processing.
#
# Optional arguments:
#    createnewtest - create some new test data (testing only)
#    filltest <testdir> - add further input files to a currently active test directory.
#    completetest <testdir> - write the trigger file and complete the test directory.
#    report - report on current status of datasets, but does not trigger anything. Informs of any missed/aged directories.
#    rescan - scan the entire top level of DATAROOT for directories - useful if cron halted or RDF is offline for a period.
#
# Note: a key assumption made is that no data directory name will be an exact substring of any other.
#

scriptpath=$(dirname $(readlink -f $0))
source $scriptpath/config.sh

function print {
    echo "[proctrigger] $@"
}

PTLOCKFILE=$DATAROOT/.proctrigger.lock
DATESTAMP=$(date --rfc-3339='seconds' | sed 's/ /_/g;s/+.*//;s/:/-/g')
# DATAREGEXP='^.*/*_data_[0-9]{5}$'
DATAREGEXP='^.*/[0-9]{6}_E[0-9]{5}_.*_.*$'

# Some temporaries
ALLTTACTIVE=$DATAROOT/.transfer_active.list #.$DATESTAMP
ALLTTCOMPLETE=$DATAROOT/.transfer_complete.list #.$DATESTAMP

### Test options ###
# Test - create test data
if [ x$1 == "xcreatenewtest" ] 
then
    print "Creating new test dataset"
    TESTDIR=$DATESTAMP\_data_$(printf %.5d $RANDOM)
    mkdir -v $DATAROOT/$TESTDIR
    # Give it something to start off with...
    print "Running filltest"
    $EXECROOT/$(basename $0) filltest $DATAROOT/$TESTDIR
    exit
fi

# Test - fill existing dataset
if [ x$1 == "xfilltest" ] 
then
    print "Randomly populating dataset"
    TESTDIR=$2
    for i in $(seq 20); do dd if=/dev/urandom of=$TESTDIR/$RANDOM bs=1k count=128; done
    echo "$TESTDIR now contains randomly generated files:"
    ls
    exit
fi

# Test - complete existing dataset
if [ x$1 == "xcompletetest" ] 
then
    print "Inserting RTAComplete.txt file to complete the test dataset"
    TESTDIR=$(echo $2 | sed 's/\/$//')
    touch $TESTDIR/$TRIGGER
    exit
fi

if [ x$1 == "xreport" ] 
then
    echo "========= PROCTRIGGER REPORT ========="
    # List all Datasets and Statuses:
    #     NEW,       New/pending (monitoring, waiting on trigger).
    #     ACTIVE,    Active/Transferring (ttagent has been launched).
    #     COMPLETE,  Transfer complete (ttagent has finished and triggered the Workflow processing script).
    ALLDATASETS=$(find $DATAROOT -mindepth 1 -maxdepth 1 -type d | grep -E "$DATAREGEXP")
    OLDDATASETS=$(find $DATAROOT -mindepth 1 -maxdepth 1 -type d -cmin +5 | grep -E "$DATAREGEXP")
    find $DATAROOT -mindepth 1 -maxdepth 1 -type f -name *.ttactive | sed 's/.*\/\./\^/;s/.ttactive/\$/' > $ALLTTACTIVE
    find $DATAROOT -mindepth 1 -maxdepth 1 -type f -name *.ttcomplete | sed 's/.*\/\./\^/;s/.ttcomplete/\$/' > $ALLTTCOMPLETE

#    echo === All Datasets ===
#    for i in $ALLDATASETS ; do echo $(basename $i) ; done
    echo "=== New Datasets ==="  # All, not active, not complete
    for i in $ALLDATASETS; do echo $(basename $i) | grep -v -f $ALLTTACTIVE | grep -v -f $ALLTTCOMPLETE; done
    echo "=== Missed Datasets \(rescan to catch\) ==="  # Old, not active, not complete
    for i in $OLDDATASETS; do echo $(basename $i) | grep -v -f $ALLTTACTIVE | grep -v -f $ALLTTCOMPLETE; done
    echo "=== Active Datasets ==="  # All, active
    for i in $ALLDATASETS; do echo $(basename $i) | grep -f $ALLTTACTIVE; done
    echo "=== Complete Datasets ==="  # All, complete
    for i in $ALLDATASETS; do echo $(basename $i) | grep -f $ALLTTCOMPLETE; done
    exit
fi
### End test options ###


### ProcTrigger ###

# Scan datasets and start staging data processes. Check for lock if running this stage.
if [ -e $PTLOCKFILE ]
then
    echo "Lock file present - is another $(basename $0) running? If not, remove the lock file ($PTLOCKFILE) and try again."
    exit
else 
    touch $PTLOCKFILE
fi

# Scan for new datasets (usually the most recent entries, but can rescan all)
if [ x$1 == "xrescan" ] # rescan will look at all datasets resident - not just the most recent ones.
then
    print "Searching for all datasets"
    # find $DATAROOT -mindepth 1 -maxdepth 1 -type d | grep -E "$DATAREGEXP"
    ALLDATASETS=$(find $DATAROOT -mindepth 1 -maxdepth 1 -type d |grep -E "$DATAREGEXP")
else
    print "Searching for new datasets within the last 5 minutes"
    # find $DATAROOT -mindepth 1 -maxdepth 1 -type d -cmin -5|grep -E "$DATAREGEXP"
    ALLDATASETS=$(find $DATAROOT -mindepth 1 -maxdepth 1 -type d -cmin -$AGEINMINS|grep -E "$DATAREGEXP")
fi


print "Searching for active/completed runs"
find $DATAROOT -mindepth 1 -maxdepth 1 -type f -name *.ttactive|sed 's/.*\/\./\^/;s/.ttactive/\$/' > $ALLTTACTIVE
find $DATAROOT -mindepth 1 -maxdepth 1 -type f -name *.ttcomplete|sed 's/.*\/\./\^/;s/.ttcomplete/\$/' > $ALLTTCOMPLETE


# Process each new dataset
print "Processing new datasets:"
NEWDATASETS=$(for i in $ALLDATASETS; do echo $(basename $i) |grep -v -f $ALLTTACTIVE | grep -v -f $ALLTTCOMPLETE; done)
for dataset in $NEWDATASETS
do
    TTAGENTLOG=$PROCROOT/.ttagent.$(basename $dataset).log
    print "Log file: $TTAGENTLOG"
    echo $DATESTAMP: Triggering for dataset: $dataset > $TTAGENTLOG
    print "Triggering ttagent for dataset: $dataset"
    # Trigger a ttagent for this dataset
    nohup $TTAGENTEXE $DATAROOT/$dataset $PROCROOT $TRIGGER > $TTAGENTLOG 2>&1 &
done


# Clear the lock file when finished    
rm -f $PTLOCKFILE
print "Done"


