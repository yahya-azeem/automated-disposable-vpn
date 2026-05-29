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

# Fetch configurations from GCP metadata server if running on Google Compute Engine
METADATA_HEADER="Metadata-Flavor: Google"
METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance/attributes"

if curl -s -H "$METADATA_HEADER" --connect-timeout 2 http://metadata.google.internal >/dev/null; then
    echo "Google Cloud Platform metadata server detected. Querying custom attributes..."
    
    fetch_meta() {
        curl -s -f -H "$METADATA_HEADER" "$METADATA_URL/$1" 2>/dev/null || true
    }
    
    META_VAL=$(fetch_meta "ddns_hostname")
    [ -n "$META_VAL" ] && DDNS_HOSTNAME="$META_VAL"

    META_VAL=$(fetch_meta "ddns_username")
    [ -n "$META_VAL" ] && DDNS_USERNAME="$META_VAL"

    META_VAL=$(fetch_meta "ddns_password")
    [ -n "$META_VAL" ] && DDNS_PASSWORD="$META_VAL"

    META_VAL=$(fetch_meta "vpn_password")
    [ -n "$META_VAL" ] && VPN_PASSWORD="$META_VAL"

    META_VAL=$(fetch_meta "vpn_cert")
    [ -n "$META_VAL" ] && VPN_CERT="$META_VAL"

    META_VAL=$(fetch_meta "vpn_key")
    [ -n "$META_VAL" ] && VPN_KEY="$META_VAL"
fi

# Update No-IP Dynamic DNS if configured (Sync Initial Update + Background Daemon)
if [ -n "$DDNS_HOSTNAME" ] && [ -n "$DDNS_USERNAME" ] && [ -n "$DDNS_PASSWORD" ]; then
    echo "Performing initial No-IP DDNS update for ${DDNS_HOSTNAME} to ${PUBLIC_IP}..."
    curl -s -u "${DDNS_USERNAME}:${DDNS_PASSWORD}" "https://dynupdate.no-ip.com/nic/update?hostname=${DDNS_HOSTNAME}&myip=${PUBLIC_IP}" || true

    # Start a background loop to act as a lightweight DDNS update daemon
    echo "Starting background Dynamic DNS update daemon..."
    (
        while true; do
            sleep 600
            CURRENT_IP=$(curl -s --max-time 5 http://ifconfig.me/ip || true)
            if [ -n "$CURRENT_IP" ]; then
                echo "Periodic DDNS Daemon: Updating ${DDNS_HOSTNAME} to ${CURRENT_IP}..."
                curl -s -u "${DDNS_USERNAME}:${DDNS_PASSWORD}" "https://dynupdate.no-ip.com/nic/update?hostname=${DDNS_HOSTNAME}&myip=${CURRENT_IP}" || true
            fi
        done
    ) &
fi


# Detect default outbound interface IP dynamically
DEFAULT_OUT_IF=$(ip route show default | awk '{print $5}' | head -n 1)
if [ -z "$DEFAULT_OUT_IF" ]; then
    DEFAULT_OUT_IF="eth0"
fi
DEFAULT_IP=$(ip -o -4 addr show dev "$DEFAULT_OUT_IF" | awk '{print $4}' | cut -d/ -f1 | head -n 1)
if [ -z "$DEFAULT_IP" ]; then
    DEFAULT_IP="0.0.0.0"
fi
echo "Detected default outbound interface IP: $DEFAULT_IP"

# Determine certificate and client connection hostname/IP
CERT_HOSTNAME="trusttunnel.local"
CLIENT_ADDRESS="${PUBLIC_IP}"
if [ -n "$DDNS_HOSTNAME" ]; then
    CERT_HOSTNAME="${DDNS_HOSTNAME}"
    CLIENT_ADDRESS="${DDNS_HOSTNAME}"
fi

# 3. Generate configurations dynamically using setup_wizard
echo "Generating TrustTunnel server configurations..."
mkdir -p /etc/trusttunnel
cd /etc/trusttunnel

VPN_PASS="${VPN_PASSWORD:-auto-generated-secret-${PUBLIC_IP}}"

/opt/trusttunnel/setup_wizard -m non-interactive \
    -a ${DEFAULT_IP}:443 \
    -c client1:${VPN_PASS} \
    -n ${CERT_HOSTNAME} \
    --cert-type self-signed \
    --lib-settings vpn.toml \
    --hosts-settings hosts.toml

# Enable routing/connections to private IPs (e.g. AdGuard DNS on 10.8.0.1)
sed -i 's/allow_private_network_connections = false/allow_private_network_connections = true/g' vpn.toml

# Parse configured certificate and key paths from hosts.toml
CERT_PATH=$(grep -E 'cert_chain_path\s*=\s*' hosts.toml | head -n 1 | cut -d'"' -f2 || true)
KEY_PATH=$(grep -E 'private_key_path\s*=\s*' hosts.toml | head -n 1 | cut -d'"' -f2 || true)

if [ -z "$CERT_PATH" ]; then
    CERT_PATH="certs/cert.pem"
fi
if [ -z "$KEY_PATH" ]; then
    KEY_PATH="certs/key.pem"
fi

# Convert relative paths to absolute paths
case "$CERT_PATH" in
    /*) ;;
    *) CERT_PATH="/etc/trusttunnel/$CERT_PATH" ;;
esac

case "$KEY_PATH" in
    /*) ;;
    *) KEY_PATH="/etc/trusttunnel/$KEY_PATH" ;;
esac

echo "Resolved certificate path: $CERT_PATH"
echo "Resolved private key path: $KEY_PATH"

# Overwrite with persistent certificate if provided, else generate custom cert with Google SANs
if [ -n "$VPN_CERT" ] && [ -n "$VPN_KEY" ]; then
    echo "Using persistent TLS certificate and key..."
    mkdir -p "$(dirname "$CERT_PATH")"
    mkdir -p "$(dirname "$KEY_PATH")"
    echo "$VPN_CERT" > "$CERT_PATH"
    echo "$VPN_KEY" > "$KEY_PATH"
else
    echo "No persistent certificate provided. Generating custom self-signed certificate with Google SANs..."
    mkdir -p "$(dirname "$CERT_PATH")"
    mkdir -p "$(dirname "$KEY_PATH")"
    
    cat <<EOF > /tmp/openssl.cnf
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = ${CERT_HOSTNAME}

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${CERT_HOSTNAME}
DNS.2 = google.com
DNS.3 = *.google.com
DNS.4 = www.google.com
DNS.5 = bing.com
DNS.6 = *.bing.com
DNS.7 = www.bing.com
DNS.8 = duckduckgo.com
DNS.9 = *.duckduckgo.com
DNS.10 = www.duckduckgo.com
DNS.11 = startpage.com
DNS.12 = *.startpage.com
DNS.13 = www.startpage.com
DNS.14 = yahoo.com
DNS.15 = *.yahoo.com
DNS.16 = www.yahoo.com
DNS.17 = brave.com
DNS.18 = *.brave.com
DNS.19 = search.brave.com
DNS.20 = yandex.com
DNS.21 = *.yandex.com
DNS.22 = yandex.ru
DNS.23 = *.yandex.ru
DNS.24 = i2p
DNS.25 = *.i2p
EOF

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout "$KEY_PATH" \
      -out "$CERT_PATH" \
      -config /tmp/openssl.cnf
fi

# 4. Generate client configuration
echo "Exporting client configuration profile..."
/usr/local/bin/trusttunnel vpn.toml hosts.toml \
    -c client1 \
    -a ${CLIENT_ADDRESS}:443 \
    -f toml \
    -d 10.8.0.1 > /root/client.yaml

# Append the server certificate to client.yaml so it is packaged and easily extractable
echo "" >> /root/client.yaml
echo "certificate = \"\"\"" >> /root/client.yaml
cat "$CERT_PATH" >> /root/client.yaml
echo "\"\"\"" >> /root/client.yaml

# Copy cert and key to /root (mapped to host mount /var/lib/trusttunnel) for GHA retrieval
cp "$CERT_PATH" /root/server.crt
cp "$KEY_PATH" /root/server.key

# Ensure backups
cp /root/client.yaml /root/client.toml
mkdir -p /root/conf
cp /root/client.yaml /root/conf/client.yaml
cp /root/client.toml /root/conf/client.toml

echo "Client configuration written to /root/client.yaml:"
cat /root/client.yaml

# Create AdGuardHome configuration directory and write it (with custom DNS rewrite for google.com)
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
user_rules:
  - "||google.com^\$dnsrewrite=10.8.0.1"
  - "||bing.com^\$dnsrewrite=10.8.0.1"
  - "||duckduckgo.com^\$dnsrewrite=10.8.0.1"
  - "||startpage.com^\$dnsrewrite=10.8.0.1"
  - "||yahoo.com^\$dnsrewrite=10.8.0.1"
  - "||brave.com^\$dnsrewrite=10.8.0.1"
  - "||yandex.com^\$dnsrewrite=10.8.0.1"
  - "||yandex.ru^\$dnsrewrite=10.8.0.1"
  - "||i2p^\$dnsrewrite=10.8.0.1"
EOF

# 5. Start i2pd
echo "Starting i2pd daemon..."
mkdir -p /var/log/i2pd
i2pd --daemon --log=file --logfile=/var/log/i2pd/i2pd.log

# 6. Start TrustTunnel Server (bound only to default interface IP)
echo "Starting TrustTunnel Server on $DEFAULT_IP:443..."
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
echo "Configuring local IP for DNS..."
ip addr add 10.8.0.1/32 dev lo || true

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

# 11. Configure & Start SearXNG
echo "Configuring SearXNG..."
mkdir -p /etc/searxng
SEARXNG_SECRET=$(openssl rand -hex 32)
cat <<EOF > /etc/searxng/settings.yml
use_default_settings: true

server:
  secret_key: "${SEARXNG_SECRET}"
  bind_address: "127.0.0.1"
  port: 8888
  limiter: false

ui:
  default_theme: simple
  theme_args:
    simple_style: dark
  search_on_category_select: true
  hotkeys: vim
  cache_url: "https://web.archive.org/web/"

outgoing:
  request_timeout: 30.0
  max_connection_timeout: 60.0

search:
  safe_search: 0
  autocomplete: ""

engines:
  - name: google
    disabled: false
  - name: bing
    disabled: false
  - name: brave
    disabled: false
  - name: duckduckgo
    disabled: false
  - name: startpage
    disabled: false
  - name: mojeek
    disabled: false
EOF

echo "Starting SearXNG..."
export SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml
/opt/searxng/venv/bin/python /opt/searxng/searx/webapp.py > /var/log/searxng.log 2>&1 &

# 12. Configure & Start Nginx Reverse Proxy (Google.com SSL termination to SearXNG)
echo "Configuring Nginx reverse proxy..."
mkdir -p /run/nginx /var/log/nginx
cat <<EOF > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
pcre_jit on;
error_log /var/log/nginx/error.log warn;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;
    client_max_body_size 1m;

    # Redirect HTTP search engines to HTTPS SearXNG
    server {
        listen 10.8.0.1:80;
        server_name google.com *.google.com www.google.com bing.com *.bing.com www.bing.com duckduckgo.com *.duckduckgo.com www.duckduckgo.com startpage.com *.startpage.com www.startpage.com yahoo.com *.yahoo.com www.yahoo.com brave.com *.brave.com search.brave.com yandex.com *.yandex.com yandex.ru *.yandex.ru;
        return 301 https://\$host\$request_uri;
    }

    # Terminate SSL for all search engines and proxy to SearXNG
    server {
        listen 10.8.0.1:443 ssl;
        server_name google.com *.google.com www.google.com bing.com *.bing.com www.bing.com duckduckgo.com *.duckduckgo.com www.duckduckgo.com startpage.com *.startpage.com www.startpage.com yahoo.com *.yahoo.com www.yahoo.com brave.com *.brave.com search.brave.com yandex.com *.yandex.com yandex.ru *.yandex.ru;

        ssl_certificate     ${CERT_PATH};
        ssl_certificate_key ${KEY_PATH};

        ssl_protocols       TLSv1.2 TLSv1.3;
        ssl_ciphers         HIGH:!aNULL:!MD5;

        location / {
            proxy_pass http://127.0.0.1:8888;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }

    # Support HTTP browsing of I2P (EEP) sites
    server {
        listen 10.8.0.1:80;
        server_name *.i2p i2p;

        location / {
            proxy_pass http://127.0.0.1:4444;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }

    # Support HTTPS browsing of I2P (EEP) sites (using same cert)
    server {
        listen 10.8.0.1:443 ssl;
        server_name *.i2p i2p;

        ssl_certificate     ${CERT_PATH};
        ssl_certificate_key ${KEY_PATH};

        ssl_protocols       TLSv1.2 TLSv1.3;
        ssl_ciphers         HIGH:!aNULL:!MD5;

        location / {
            proxy_pass http://127.0.0.1:4444;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

echo "Starting Nginx..."
nginx -g "daemon off;" &

echo "=== All services successfully initiated ==="

# Keep container running and stream logs to stdout
tail -f /var/log/suricata/eve.json /var/log/i2pd/i2pd.log /var/log/searxng.log
