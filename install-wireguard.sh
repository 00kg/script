apt update && apt install iptables ufw wireguard -y
modprobe wireguard

port=$(( RANDOM % (65535 - 20000 + 1) + 20000 ))
interface=$(ip route list default | awk '{print $5}')

wg genkey | tee /etc/wireguard/private.key
chmod go= /etc/wireguard/private.key
cat /etc/wireguard/private.key | wg pubkey | tee /etc/wireguard/public.key
privateKey=$(<"/etc/wireguard/private.key")
publicKey=$(<"/etc/wireguard/public.key")

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && sysctl -p

echo "[Interface]
PrivateKey = $privateKey
Address = 10.8.0.1/24
ListenPort = $port
SaveConfig = true
PostUp = ufw route allow in on wg0 out on $interface
PostUp = iptables -t nat -I POSTROUTING -o $interface -j MASQUERADE
PreDown = ufw route delete allow in on wg0 out on $interface
PreDown = iptables -t nat -D POSTROUTING -o $interface -j MASQUERADE" > /etc/wireguard/wg0.conf

ufw allow $port/udp
ufw allow OpenSSH
ufw disable && echo "y" | ufw enable && ufw status

systemctl start wg-quick@wg0.service
systemctl enable wg-quick@wg0.service


wg genkey | tee /etc/wireguard/client_private.key
cat /etc/wireguard/client_private.key | wg pubkey | tee /etc/wireguard/client_public.key
client_privateKey=$(<"/etc/wireguard/client_private.key")
client_publicKey=$(<"/etc/wireguard/client_public.key")
server_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)

wg set wg0 peer $client_publicKey allowed-ips 10.8.0.10

echo "===================================="
echo "================conf================"
echo "===================================="
echo "[Interface]
PrivateKey = $client_privateKey
Address = 10.8.0.10/32
DNS = 8.8.8.8

[Peer]
PublicKey = $publicKey
AllowedIPs = 0.0.0.0/0
Endpoint = $server_ip:$port
PersistentKeepalive = 25
"
echo "===================================="
