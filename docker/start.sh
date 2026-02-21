#!/bin/bash
#---------------------------------------------------------------------------------------------------------
# Copyright © 2012-2026 Christopher Gray.  All Rights Reserved.  Proprietary and Confidential.  -  The reproduction, adaptation, distribution, display, or transmission of the content is strictly prohibited, unless authorized by Christopher Gray. All other company & product names may be trademarks of the respective companies with which they are associated.
# Version: 0.0.5
# Updated: 2/21/2026
#---------------------------------------------------------------------------------------------------------


# Install / Update here:
#     wget -O "start.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/docker/start.sh && chmod +x start.sh


echo "


======================================================================
                        Starting Containers
======================================================================

To View logs:
  docker compose logs -f <container>
  docker compose logs --tail=200 -f <container>

"

docker-compose up -d


echo "


======================================================================
                        Composer Containers
======================================================================

"


docker compose ps

echo "


======================================================================
                           All Containers
======================================================================

"

docker ps -a


echo "


"
