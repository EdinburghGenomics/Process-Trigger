#!/bin/bash
scriptpath=$(dirname $(readlink -f $0))
source $scriptpath/config.sh

echo "[ptworkflow] Processing workflow for: $1"
echo "[ptworkflow] Using Python interpreter at $(which $PYTHON)"

$PYTHON $ANALYSISDRIVER/driver.py $1  # Run the AnalysisDriver

