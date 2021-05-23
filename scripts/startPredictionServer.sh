#!/bin/bash
# To run this script as a service, do the following:
# Copy prediction-server.service to /etc/systemd/system
# Then run the following commands:
# sudo systemctl daemon-reload
# sudo systemctl start my_service.service
# If you want to automatically start the service when the system loads:
# sudo systemctl enable my_service.service
# 
# Tested in Ubuntu 16.04.

export LD_PRELOAD=$LD_PRELOAD:/usr/lib/x86_64-linux-gnu/libstdc++.so.6:/usr/lib/x86_64-linux-gnu/libprotobuf.so.9
PATH="$PATH:/usr/local/cuda/bin";export PATH
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64
export LD_LIBRARY_PATH
matlab -nodisplay -nodesktop -r "startup; startPredictionServer;"
