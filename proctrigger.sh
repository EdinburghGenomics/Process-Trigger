#!/bin/bash
# Status: Beta - development/testing. Handed over to Edinburgh Genomics.
#
# Description: Run proctrigger.sh to pickup new inbound datasets and trigger processing.
# Usage: proctrigger.sh [ createnewtest | filltest| completetest | report | rescan ]
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

source config.sh

# Some temporaries
ALLTTACTIVE=$DATAROOT/.transfer_active.list #.$DATESTAMP
ALLTTCOMPLETE=$DATAROOT/.transfer_complete.list #.$DATESTAMP

### Test options ###
# Test - create test data
if [ x$1 == "xcreatenewtest" ] 
then
    # Create a new dataset.
    TESTDIR=$DATESTAMP\_data_$(printf %.5d $RANDOM)
    echo mkdir $DATAROOT/$TESTDIR:
    mkdir $DATAROOT/$TESTDIR
    # Give it something to start off with...
    $EXECROOT/$(basename $0) filltest $DATAROOT/$TESTDIR
    exit
fi

# Test - fill existing dataset
if [ x$1 == "xfilltest" ] 
then
    # stick some random stuff in a dataset.
    TESTDIR=$2
    for i in $(seq 20) ; do dd if=/dev/urandom of=$TESTDIR/$RANDOM bs=1k count=128 ; done 
    exit
fi

# Test - complete existing dataset
if [ x$1 == "xcompletetest" ] 
then
    # complete a test by inserting the trigger file
    TESTDIR=$(echo $2|sed 's/\/$//')
    touch $TESTDIR/$TRIGGER
    exit
fi

if [ x$1 == "xreport" ] 
then
    echo ========= PROCTRIGGER REPORT =========
    # List all Datasets and Statuses:
    #     NEW,       New/pending (monitoring, waiting on trigger).
    #     ACTIVE,    Active/Transferring (ttagent has been launched).
    #     COMPLETE,  Transfer complete (ttagent has finished and triggered the Workflow processing script).
    ALLDATASETS=$(find $DATAROOT -mindepth 1 -maxdepth 1 -type d | grep -E "$DATAREGEXP")
    OLDDATASETS=$(find $DATAROOT -mindepth 1 -maxdepth 1 -type d -cmin +5|grep -E "$DATAREGEXP")
    find $DATAROOT -mindepth 1 -maxdepth 1 -type f -name *.ttactive|sed 's/.*\/\./\^/;s/.ttactive/\$/' > $ALLTTACTIVE
    find $DATAROOT -mindepth 1 -maxdepth 1 -type f -name *.ttcomplete|sed 's/.*\/\./\^/;s/.ttcomplete/\$/' > $ALLTTCOMPLETE

#    echo === All Datasets ===
#    for i in $ALLDATASETS ; do echo $(basename $i) ; done
    echo === New Datasets ===
    for i in $ALLDATASETS ; do echo $(basename $i) |grep -v -f $ALLTTACTIVE |grep -v -f $ALLTTCOMPLETE ; done
    echo === Missed Datasets \(rescan to catch\) ===
    for i in $OLDDATASETS ; do echo $(basename $i) |grep -v -f $ALLTTACTIVE |grep -v -f $ALLTTCOMPLETE ; done
    echo === Active Datasets ===
    for i in $ALLDATASETS ; do echo $(basename $i) |grep -f $ALLTTACTIVE ; done
    echo === Complete Datasets ===
    for i in $ALLDATASETS ; do echo $(basename $i) |grep -f $ALLTTCOMPLETE ; done
    exit
fi
### End test options ###


### ProcTrigger ###

# Scan datasets and start staging data processes. Check for lock if running this stage.
if [ -e $PTLOCKFILE ]
then
    echo Lock file present - is another $(basename $0) running? If not, remove the lock file and try again...
    exit
else 
    touch $PTLOCKFILE
fi

# Scan for new datasets (usually the most recent entries, but can rescan all)
if [ x$1 == "xrescan" ] # rescan will look at all datasets resident - not just the most recent ones.
then
#    find $DATAROOT -mindepth 1 -maxdepth 1 -type d | grep -E "$DATAREGEXP"
    ALLDATASETS=$(find $DATAROOT -mindepth 1 -maxdepth 1 -type d | grep -E "$DATAREGEXP")
else
#    find $DATAROOT -mindepth 1 -maxdepth 1 -type d -cmin -5|grep -E "$DATAREGEXP"
    ALLDATASETS=$(find $DATAROOT -mindepth 1 -maxdepth 1 -type d -cmin -$AGEINMINS|grep -E "$DATAREGEXP")
fi

find $DATAROOT -mindepth 1 -maxdepth 1 -type f -name *.ttactive|sed 's/.*\/\./\^/;s/.ttactive/\$/' > $ALLTTACTIVE
find $DATAROOT -mindepth 1 -maxdepth 1 -type f -name *.ttcomplete|sed 's/.*\/\./\^/;s/.ttcomplete/\$/' > $ALLTTCOMPLETE


# Process each new dataset
NEWDATASETS=$(for i in $ALLDATASETS ; do echo $(basename $i) |grep -v -f $ALLTTACTIVE |grep -v -f $ALLTTCOMPLETE ; done)
for dataset in $NEWDATASETS
do
    echo $DATESTAMP: Triggering for dataset: $dataset > $PROCROOT/.ttagent.$(basename $dataset).log
    echo $DATESTAMP: Triggering for dataset: $dataset
    # Trigger a ttagent for this dataset
    nohup $TTAGENTEXE $DATAROOT/$dataset $PROCROOT $TRIGGER > $PROCROOT/.ttagent.$(basename $dataset).log 2>&1 &
done


# Clear the lock file when finished    
rm -f $PTLOCKFILE

