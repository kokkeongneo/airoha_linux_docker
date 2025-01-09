#!/bin/bash
echo "Running startup script..."

# start airoha dsp license server
sudo -E ${HOME}/airoha_sdk_toolchain/start_lic_server.sh

# Start a bash shell to keep the container alive
exec /bin/bash