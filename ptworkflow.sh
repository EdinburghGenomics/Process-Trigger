#!/bin/bash
source config.sh

echo "[ptworkflow] Processing workflow for: $1"

# Run the driver that kicks off all the processing jobs
cd $ANALYSISDRIVER
$PYTHON driver.py $1

