### Configuration ###

# User-configurable file paths, exectuables, etc.
EXECROOT=$HOME/Process-Trigger  # Path to executables. Set up symbolic links to the Process Trigger bash scripts
WORKFLOWEXE=$EXECROOT/ptworkflow.sh
TTAGENTEXE=$EXECROOT/ttagent.sh
TTDELAY=120

DATAROOT=$HOME/raw  #/sequencer/RAW  # Path to rdf mount 
PTLOCKFILE=$DATAROOT/.proctrigger.lock
PROCROOT=$HOME/input_data  # /scratch/U008/edingen/INPUT_DATA  # /scratch/U008/kdmellow/procroot
DATESTAMP=$(date --rfc-3339='seconds'|sed 's/ /_/g;s/+.*//;s/:/-/g')
# DATAREGEXP='^.*/*_data_[0-9]{5}$'
DATAREGEXP='^.*/[0-9]{6}_E[0-9]{5}_.*_.*$'
TRIGGER=RTAComplete.txt
AGEINMINS=5

# PYTHON=$HOME/python/envs/23_06_15/bin/python
PYTHON=`which python`

ANALYSISDRIVER=$HOME/Analysis-Driver

