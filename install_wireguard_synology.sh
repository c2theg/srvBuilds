# --- Sources ---
# APK - https://github.com/runfalk/synology-wireguard
# https://wiki.archlinux.org/index.php/WireGuard
# # https://emanuelduss.ch/2018/09/wireguard-vpn-road-warrior-setup/

#----- SSH into the NAS -----
# ssh admin@10.1.1.5
# if using a different port:  ssh admin@10.1.1.5 -p 10022

mkdir /etc/wireguard/
cd /etc/wireguard/

#--- Generate Public and Private keys ---
umask 077
wg genkey | tee privatekey | wg pubkey > publickey

#--- Generate Preshared Key ---
wg genpsk > preshared_key.psk


# Show all keys. need them for config later
cat preshared_key.psk
cat privatekey
cat pubblickey

#--- Figure out eth0 conn name ---
ip a
#Copy the name (in my case it was: "ovs_eth0" but it could be "eth0" )

ip link add dev wg0 type wireguard

#--- Create Config file ---
touch wg0.conf

# --- Create Sample Server Config ---
# Modify name of eth0 to match yours (in my case it was "ovs_eth0"
vi wg0.conf 

#--- put the following in your server side config ---
[Interface]
Address = 10.6.0.1/24
PrivateKey = <Private Key from file>
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ovs_eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ovs_eth0 -j MASQUERADE


### begin Peer1 ###
[Peer]
PresharedKey = <PreShared Key>
PublicKey = <Public Key from file>
AllowedIPs = 10.6.0.2/32

### begin Peer2 ###
[Peer]
PresharedKey = <PreShared Key>
PublicKey = <Public Key from file>
AllowedIPs = 10.6.0.3/32


#------ CLIENT SIDE CONFIG -----------
# Create a file on the client side, with the following content. 
# Then import it into the wireguard client. 

#--- Config ---
[Interface]
PrivateKey = <Private Key from file>
Address = 10.6.0.2/24
DNS =  10.6.0.1, 1.1.1.2, 9.9.9.9, 208.67.222.222, 8.8.8.8

[Peer]
PersistentKeepalive = 25
PublicKey = <Public Key from file>
PresharedKey = < PRE SHARED KEY from file (preshared_key) >
Endpoint = example.com:51820
AllowedIPs = 0.0.0.0/0, ::0/0
# for SplitTunnel use the following:
#AllowedIPs = 1.1.1.2/32, 9.9.9.9/32, 208.67.222.222/32, 8.8.8.8/32,  0.0.0.0/0, ::0/0
