#!/bin/bash
#---------------------------------------------------------------------------------------------------------
# Copyright © 2012-2026 Christopher Gray.  All Rights Reserved.  Proprietary and Confidential.  -  The reproduction, adaptation, distribution, display, or transmission of the content is strictly prohibited, unless authorized by Christopher Gray. All other company & product names may be trademarks of the respective companies with which they are associated.
# Version: 0.0.5
# Updated: 2/21/2026
#---------------------------------------------------------------------------------------------------------
# Install / Update here:
#     wget -O "cleanup_containers.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/docker/cleanup_containers.sh && chmod +x cleanup_containers.sh



docker ps -a
docker compose ps


echo "


======================================================================
    Removing all dangling Containers / Images / Volumes / Networks
                (DANGEROUS - USE WITH CAUTION)
                .. this will take a minute or two
======================================================================


"

purge() {
    docker system prune -f
    docker volume prune -f
    docker network prune -f
}

purge

echo "


======================================================================
                            Done!
======================================================================


"
docker ps -a
docker compose ps
