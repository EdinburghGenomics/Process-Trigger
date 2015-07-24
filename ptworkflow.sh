#!/bin/bash
scriptpath=$(dirname $(readlink -f $0))
source $scriptpath/config.sh

echo "[ptworkflow] Processing workflow for: $1"
echo "[ptworkflow] Using Python interpreter at $(which $PYTHON)"

$PYTHON $ANALYSISDRIVER/bin/edingen_analysis_driver.py $1

