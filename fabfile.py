from fabric.api import *

env.hosts = [
	'ubuntu@192.168.1.1',
	'ubuntu@192.168.1.2'
]

env.password = 'Secr3t!'

@parallel
def cmd(command):
	sudo(command)


'''   How to use
Enter the commands as follows:

ubuntu@host:$  fab cmd:"echo pi:Secret! | chpasswd"

fab cmd:"apt update"

fab cmd:"apt-get upgrade -y"
fab cmd:"apt dist-upgrade -y"


-- for Raspberry Pi--

fab cmd:"raspi-config --expand-rootfs"
fab cmd:"reboot now"

'''
