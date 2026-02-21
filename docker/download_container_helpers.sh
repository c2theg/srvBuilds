#!/bin/bash
#---------------------------------------------------------------------------------------------------------
# Copyright © 2012-2026 Christopher Gray.  All Rights Reserved.  Proprietary and Confidential.  -  The reproduction, adaptation, distribution, display, or transmission of the content is strictly prohibited, unless authorized by Christopher Gray. All other company & product names may be trademarks of the respective companies with which they are associated.
# Version: 0.0.5
# Updated: 2/21/2026
#---------------------------------------------------------------------------------------------------------
# Install / Update here:
#       wget -O "download_container_helpers.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/docker/download_container_helpers.sh && chmod +x download_container_helpers.sh && ./download_container_helpers.sh


wget -O "start.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/docker/start.sh && chmod +x start.sh
wget -O "stop.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/docker/stop.sh && chmod +x stop.sh
wget -O "rebuild.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/docker/rebuild.sh && chmod +x rebuild.sh
wget -O "cleanup_containers.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/docker/cleanup_containers.sh && chmod +x cleanup_containers.sh
