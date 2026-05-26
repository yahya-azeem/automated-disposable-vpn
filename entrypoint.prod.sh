#!/bin/sh
set -e

echo "=== Starting TrustTunnel VPN Container Initialization ==="

# 1. Ensure /dev/net/tun exists inside the container
if [ ! -c /dev/net/tun ]; then
    echo "Creating /dev/net/tun..."
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

# 2. Retrieve Public IP (retrying if necessary)
echo "Fetching public IP..."
PUBLIC_IP=""
for i in 1 2 3 4 5; do
    PUBLIC_IP=$(curl -s --max-time 5 http://ifconfig.me/ip || true)
    if [ -n "$PUBLIC_IP" ]; then
        break
    fi
    echo "Retrying public IP fetch in 2 seconds..."
    sleep 2
done

if [ -z "$PUBLIC_IP" ]; then
    echo "WARNING: Could not fetch public IP. Defaulting to 127.0.0.1"
    PUBLIC_IP="127.0.0.1"
fi
echo "Public IP detected: $PUBLIC_IP"

# 3. Generate TrustTunnel Server Certificates if not present
mkdir -p /etc/trusttunnel
if [ ! -f /etc/trusttunnel/server.crt ]; then
    echo "Generating self-signed TLS certificates for TrustTunnel..."
    openssl req -x509 -newkey rsa:4096 -keyout /etc/trusttunnel/server.key \
        -out /etc/trusttunnel/server.crt -days 365 -nodes \
        -subj "/CN=trusttunnel.local"
fi

# Extract Certificate Fingerprint
TLS_FINGERPRINT=$(openssl x509 -noout -fingerprint -sha256 -in /etc/trusttunnel/server.crt | tr -d ':' | cut -d= -f2)
echo "TLS Certificate Fingerprint: $TLS_FINGERPRINT"

# 4. Generate configurations dynamically
echo "Writing configuration files..."
cat <<EOF > /etc/trusttunnel/config.yaml
bind: "0.0.0.0:443"
tls:
  cert: "/etc/trusttunnel/server.crt"
  key: "/etc/trusttunnel/server.key"
network:
  ipv4_range: "10.8.0.0/24"
  dns: "10.8.0.1"
users:
  - id: "client1"
    secret: "auto-generated-secret-${PUBLIC_IP}"
EOF

cat <<EOF > /root/client.yaml
endpoints:
  - "${PUBLIC_IP}:443"
tls:
  server_name: "trusttunnel.local"
  fingerprint: "${TLS_FINGERPRINT}"
auth:
  id: "client1"
  secret: "auto-generated-secret-${PUBLIC_IP}"
dns: "10.8.0.1"
EOF

# Ensure backup in a shared volume location if mounted to /root/conf
mkdir -p /root/conf
cp /root/client.yaml /root/conf/client.yaml
echo "Client configuration written to /root/client.yaml and /root/conf/client.yaml:"
cat /root/client.yaml

# Create AdGuardHome configuration directory and write it
mkdir -p /opt/adguardhome/AdGuardHome
cat <<EOF > /opt/adguardhome/AdGuardHome/AdGuardHome.yaml
bind_host: 127.0.0.1
bind_port: 3000
dns:
  bind_hosts:
    - 127.0.0.1
    - 10.8.0.1
  port: 53
  upstream_dns:
    - 1.1.1.1
    - 1.0.0.1
  bootstrap_dns:
    - 1.1.1.1
filters:
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
    name: AdGuard DNS filter
    id: 1
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_27.txt
    name: OISD Blocklist Small
    id: 2
EOF

# 5. Start i2pd
echo "Starting i2pd daemon..."
mkdir -p /var/log/i2pd
i2pd --daemon --log=file --logfile=/var/log/i2pd/i2pd.log

# 6. Start TrustTunnel (creates tun0)
echo "Starting TrustTunnel..."
/usr/local/bin/trusttunnel -c /etc/trusttunnel/config.yaml &
TRUSTTUNNEL_PID=$!

# Wait for tun0 interface to appear
echo "Waiting for tun0 interface to be initialized..."
TUN_READY=false
for i in $(seq 1 15); do
    if ip link show tun0 >/dev/null 2>&1; then
        TUN_READY=true
        break
    fi
    sleep 1
done

if [ "$TUN_READY" = "false" ]; then
    echo "ERROR: tun0 interface was not created. Exiting."
    kill $TRUSTTUNNEL_PID || true
    exit 1
fi
echo "tun0 interface is up!"

# 7. Configure System-Wide IP Masquerading
echo "Configuring firewall and IP forwarding..."
# Detect default outbound interface dynamically
DEFAULT_OUT_IF=$(ip route show default | awk '{print $5}' | head -n 1)
if [ -z "$DEFAULT_OUT_IF" ]; then
    DEFAULT_OUT_IF="eth0"
fi
echo "Detected default outbound interface: $DEFAULT_OUT_IF"
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o "$DEFAULT_OUT_IF" -j MASQUERADE

# 8. Start AdGuard Home
echo "Starting AdGuard Home..."
/opt/adguardhome/AdGuardHome/AdGuardHome -c /opt/adguardhome/AdGuardHome/AdGuardHome.yaml -w /opt/adguardhome/AdGuardHome &

# 9. Start Suricata IDS
echo "Starting Suricata IDS on tun0..."
# Update interface in suricata.yaml if it exists
if [ -f /etc/suricata/suricata.yaml ]; then
    sed -i 's/interface: eth0/interface: tun0/g' /etc/suricata/suricata.yaml
fi
mkdir -p /var/log/suricata
touch /var/log/suricata/eve.json
suricata -c /etc/suricata/suricata.yaml -i tun0 &

# 10. Start Log API HTTP Server
echo "Starting log API HTTP server..."
python3 /usr/local/bin/log_api.py &

echo "=== All services successfully initiated ==="

# Keep container running and stream logs to stdout
tail -f /var/log/suricata/eve.json /var/log/i2pd/i2pd.log
