FROM alpine:latest

# Install dependencies required for SSH, python3 (Ansible), and service management
RUN apk add --no-cache openrc openssh python3 sudo

# Create the alpine user and configure passwordless sudo
RUN adduser -D alpine && \
    echo 'alpine ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/alpine && \
    chmod 0440 /etc/sudoers.d/alpine

# Initialize OpenRC inside the container
RUN mkdir -p /run/openrc && touch /run/openrc/softlevel

# Copy entrypoint script to handle startup configurations (like writing public keys)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port 443 (default port for the VPN node)
EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]
