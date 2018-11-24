# the following script is for init of redis in a docker container

sysctl vm.overcommit_memory=1
# max socket backlog (def 128)
sysctl -w net.core.somaxconn=1024

echo never > /sys/kernel/mm/transparent_hugepage/enabled
