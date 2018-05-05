from fabric.api import *

env.hosts = [
	'ubuntu@192.168.1.1',
	'ubuntu@192.168.1.2'
]

env.password = 'Secr3t!'

@parallel
def cmd(command):
	sudo(command)
