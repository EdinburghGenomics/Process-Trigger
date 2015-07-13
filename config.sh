#!/bin/bash

# Configuration script for ProcTrigger. Sets variables that are then sourced by other bash scripts here.
#
# The ProcTrigger is configured both by this config.sh and a yaml config that this script reads. The yaml
# config supplies parameters that are user-configurable (file paths, time delays, etc.). This script reads
# those parameters and sets them to variables, along with more fundamental parameters (script names, lock
# file names, etc.) that are explicitly defined below. The user should be able to fully configure the
# ProcTrigger (and indeed the Analysis Driver) entirely through the yaml config in $HOME/.analysisdriver.yaml


### Setup. Point to config files, what environment is to be run, import yaml parsing functions

function print {
    echo "[config] $@"
}

scriptpath=$(dirname $(readlink -f $0))
source $scriptpath/yaml_parser.sh

print "Directory: $scriptpath"
user_config_file=$HOME/.analysisdriver.yaml
local_config_file=$scriptpath/example_analysisdriver.yaml

# Set up config file
if [ -f $user_config_file ]
    then config_file=$user_config_file
    else config_file=$local_config_file
fi

# Set up running environment
if [ -z $ANALYSISDRIVERENV ]
    then env="testing"
    else env=$ANALYSISDRIVERENV
fi

print "Using \"$env\" environment in $config_file"

function configure {
    echo $(retrieve_element $config_file $env $1 $2)
}


### Configuration. Use yaml parsing to set config variables

# Paths to ProcTrigger executables and a time delay variable
EXECROOT=$(configure proctrigger location)
WORKFLOWEXE=$EXECROOT/ptworkflow.sh
TTAGENTEXE=$EXECROOT/ttagent.sh
TTDELAY=$(configure proctrigger tt_agent_delay)

# Paths to working directories, trigger file name and another time variable
# Path to rdf mount, e.g. /sequencer/RAW
DATAROOT=$(configure shared raw_dir) 
# The path to the working input data, e.g. /scratch/U008/edingen/INPUT_DATA or /scratch/U008/kdmellow/procroot
PROCROOT=$(configure shared input_data_dir)

TRIGGER=RTAComplete.txt
AGEINMINS=$(configure proctrigger age_cutoff)

# Paths to the AnalysisDriver and the relevant Python interpreter
PYTHON=$(configure shared python)
ANALYSISDRIVER=$(configure analysisdriver location)

# print EXECROOT: $EXECROOT
# print WORKFLOWEXE: $WORKFLOWEXE
# print TTAGENTEXE: $TTAGENTEXE
# print TTDELAY: $TTDELAY
# print DATAROOT: $DATAROOT
# print PROCROOT: $PROCROOT
# print TRIGGER: $TRIGGER
# print AGEINMINS: $AGEINMINS
# print PYTHON: $PYTHON
# print ANALYSISDRIVER: $ANALYSISDRIVER

