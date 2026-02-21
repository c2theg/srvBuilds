#!/bin/bash
#---------------------------------------------------------------------------------------------------------
# Copyright © 2012-2026 Christopher Gray.  All Rights Reserved.  Proprietary and Confidential.  -  The reproduction, adaptation, distribution, display, or transmission of the content is strictly prohibited, unless authorized by Christopher Gray. All other company & product names may be trademarks of the respective companies with which they are associated.
# Version: 0.1.26
# Updated: 2/21/2026
#---------------------------------------------------------------------------------------------------------

# How to use:
#   ./rebuild.sh
#   ./rebuild.sh -d
#   ./rebuild.sh --daemon
#   ./rebuild.sh daemon
#   ./rebuild.sh --no-cache
#   ./rebuild.sh --cache

#   ./rebuild.sh -d --no-cache



# Install / Update here:
#     wget -O "rebuild.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/docker/rebuild.sh && chmod +x rebuild.sh

echo "


======================================================================
                   Stopping and Removing Containers
======================================================================

"
#-- Stop and Remove --
docker compose down --remove-orphans


#--- Build and Start ---
DAEMON_MODE=false
if [[ "$1" == "-d" || "$1" == "--daemon" || "$1" == "daemon" ]]; then
  DAEMON_MODE=true
fi


Cache_MODE=true
if [[ "$1" == "--no-cache" || "$1" == "no-cache" ]]; then
  Cache_MODE=false
elif [[ "$1" == "--cache" || "$1" == "cache" ]]; then
  Cache_MODE=true
fi


echo "

======================================================================
                      Rebuilding Application
"
echo DAEMON_MODE: $DAEMON_MODE
echo Cache_MODE: $Cache_MODE
echo "
      (can be modified by: ./rebuild.sh -d --no-cache)
======================================================================


"


if [[ "$DAEMON_MODE" == true ]]; then
  if [[ "$Cache_MODE" == true ]]; then
    # Cache the build
    docker compose up -d --build
  else
    # No cache build
    docker compose build --no-cache
    docker compose up -d
  fi

else
  if [[ "$Cache_MODE" == true ]]; then
    # Cache the build
    docker compose up --build
  else
    # No cache build
    docker compose build --no-cache
    docker compose up
  fi
fi


#--- Alternative: Build and Start (separate commands) and make as a daemon ---
#docker compose build --no-cache
#docker compose up -d


echo "


======================================================================
                        Rebuild Complete
======================================================================

To View logs:
  docker compose logs -f <container>
  docker compose logs --tail=200 -f <container>




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
