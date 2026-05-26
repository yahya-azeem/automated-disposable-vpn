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

# 3. Generate configurations dynamically using setup_wizard
echo "Generating TrustTunnel server configurations and self-signed certificates..."
mkdir -p /etc/trusttunnel
cd /etc/trusttunnel

/opt/trusttunnel/setup_wizard -m non-interactive \
    -a 0.0.0.0:443 \
    -c client1:auto-generated-secret-${PUBLIC_IP} \
    -n trusttunnel.local \
    --cert-type self-signed \
    --lib-settings vpn.toml \
    --hosts-settings hosts.toml

# 4. Generate client configuration
echo "Exporting client configuration profile..."
/usr/local/bin/trusttunnel vpn.toml hosts.toml \
    -c client1 \
    -a ${PUBLIC_IP}:443 \
    -f toml \
    -d 10.8.0.1 > /root/client.yaml

# Ensure backups
cp /root/client.yaml /root/client.toml
mkdir -p /root/conf
cp /root/client.yaml /root/conf/client.yaml
cp /root/client.toml /root/conf/client.toml

echo "Client configuration written to /root/client.yaml:"
cat /root/client.yaml

# Create AdGuardHome configuration directory and write it
mkdir -p /opt/adguardhome/AdGuardHome
cat <<EOF > /opt/adguardhome/AdGuardHome/AdGuardHome.yaml
schema_version: 34
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
filtering:
  filtering_enabled: true
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

# 6. Start TrustTunnel Server
echo "Starting TrustTunnel Server..."
/usr/local/bin/trusttunnel /etc/trusttunnel/vpn.toml /etc/trusttunnel/hosts.toml &
TRUSTTUNNEL_PID=$!
sleep 2

# 7. Configure System-Wide IP Masquerading
echo "Configuring firewall and IP forwarding..."
# Detect default outbound interface dynamically
DEFAULT_OUT_IF=$(ip route show default | awk '{print $5}' | head -n 1)
if [ -z "$DEFAULT_OUT_IF" ]; then
    DEFAULT_OUT_IF="eth0"
fi
echo "Detected default outbound interface: $DEFAULT_OUT_IF"
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o "$DEFAULT_OUT_IF" -j MASQUERADE || true

# 8. Start AdGuard Home
echo "Starting AdGuard Home..."
/opt/adguardhome/AdGuardHome/AdGuardHome -c /opt/adguardhome/AdGuardHome/AdGuardHome.yaml -w /opt/adguardhome/AdGuardHome &

# 9. Start Suricata IDS on default interface
echo "Starting Suricata IDS on $DEFAULT_OUT_IF..."
# Update interface in suricata.yaml if it exists
if [ -f /etc/suricata/suricata.yaml ]; then
    sed -i "s/interface: eth0/interface: $DEFAULT_OUT_IF/g" /etc/suricata/suricata.yaml
fi
mkdir -p /var/log/suricata
touch /var/log/suricata/eve.json
suricata -c /etc/suricata/suricata.yaml -i "$DEFAULT_OUT_IF" &

# 10. Start Log API HTTP Server
echo "Starting log API HTTP server..."
sed -i "s/'10.8.0.1'/'0.0.0.0'/g" /usr/local/bin/log_api.py
python3 /usr/local/bin/log_api.py &

echo "=== All services successfully initiated ==="

# Keep container running and stream logs to stdout
tail -f /var/log/suricata/eve.json /var/log/i2pd/i2pd.log
