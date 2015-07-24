# ProcTrigger
Status: Beta - development/testing
==================================

## Description
--------------
Run proctrigger.sh to pickup new inbound datasets and trigger processing. proctrigger.sh will spawn
a ttagent.sh process for each new dataset it encounters. ttagent.sh is responsible for
synchronising the dataset using rsync, and upon encountering a trigger lock file, launches the
processing workflow script.

## proctrigger.sh
-----------------
Run `proctrigger.sh` without arguments in production, to stage datasets and trigger processing.
Run `proctrigger.sh rescan` in production to rescan the data root for older/unprocessed datasets.


Arguments to proctrigger.sh can perform two other actions:
- report - reports on current status of datasets, but does not trigger anything. Informs of any
  missed/aged directories.
- rescan - scan the entire top level of DATAROOT for directories - useful if cron is halted or the
  RDF is offline for a period.

## ttagent.sh
-------------
ttagent.sh can be run by itself, and takes three arguments:

    ttagent.sh <source_dir> <dest_root_dir> <trigger_file> 

ttagent.sh (transfer and trigger agent) continuously monitors a partial dataset directory and
transfers it to the compute platform by looping rsync with a small delay. It will stop looping
when the trigger lock file is received, indicating the completion of the dataset directory.

ttagent.sh launches a configurable workflow.sh script, passing the
staged dataset's location as a single argument.

## ptworkflow.sh
----------------
This script wraps the Analysis Driver, calling it with the Python interpreter specified in the
yaml config file.

## config.sh
------------
The ProcTrigger and Analysis Driver are configured by a yaml file in the user's home. This config
script uses the yaml_parser script below to read configurations from this file and save them to
variables.

## yaml_parser.sh
-----------------
This contains two functions:
- parse_yaml() - Loads a yaml-formatted file and returns a parsable string. This was developed by
Piotr Kuczynski at gist.github.com
- parse_yaml() - Calls parse_yaml() to retrieve yaml elements

Sourcing yaml_parse.sh and running, for example:

    retrieve_element config.yaml testing proctrigger location

... will look in config.yaml for the value of a 'location' element, under a 'proctrigger' element,
under a 'testing' element.

