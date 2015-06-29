#!/bin/bash
source config.sh

echo "[ptworkflow] Processing workflow for: $1"

cd $ANALYSISDRIVER
# $PYTHON 
python driver.py $1  # Run the driver that kicks off all the processing jobs

