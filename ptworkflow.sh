#!/bin/bash
echo processing workflow for: $1

# Run the driver that kicks off all the processing jobs
cd /home/U008/edingen/AnalysisDriver
python driver.py $1
