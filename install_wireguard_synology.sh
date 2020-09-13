# --- Sources ---
# APK - https://github.com/runfalk/synology-wireguard
# https://wiki.archlinux.org/index.php/WireGuard



mkdir /etc/wireguard/
cd /etc/wireguard/

#--- Generate Public and Private keys ---
wg genkey | tee privatekey | wg pubkey > publickey

cat privatekey
cat pubblickey

#--- Generate Preshared Key ---
umask 077
wg genpsk > preshared_key.psk


#--- Figure out eth0 conn name ---
ip a
#Copy the name (in my case it was: "ovs_eth0" but it could be "eth0" )


#--- Create Config file ---
touch wg0.conf

# --- Create Sample Server Config ---
# Modify name of eth0 to match yours (in my case it was "ovs_eth0"
vi wg0.conf 


[Interface]
Address = 10.6.0.1/24
PrivateKey = <Private Key from file>
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ovs_eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ovs_eth0 -j MASQUERADE

[Peer]
PublicKey = <Public Key from file>
AllowedIPs = 10.6.0.2/32





#------ CLIENT SIDE CONFIG -----------
cat preshared_key.psk


#--- Config ---
[Interface]
PrivateKey = <Private Key from file>
Address = 10.6.0.3/24
DNS = 10.6.0.1

[Peer]
PublicKey = <Public Key from file>
PresharedKey = < PRE SHARED KEY from file (preshared_key) >
Endpoint = 10.11.1.50:61820
AllowedIPs = 0.0.0.0/0, ::0/0
