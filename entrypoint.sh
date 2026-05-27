#!/bin/sh

# Generate host keys if not present
ssh-keygen -A

# If SSH_PUBLIC_KEY environment variable is provided, set it up for the alpine user
if [ -n "$SSH_PUBLIC_KEY" ]; then
    mkdir -p /home/alpine/.ssh
    echo "$SSH_PUBLIC_KEY" > /home/alpine/.ssh/authorized_keys
    chown -R alpine:alpine /home/alpine/.ssh
    chmod 700 /home/alpine/.ssh
    chmod 600 /home/alpine/.ssh/authorized_keys
fi

# Determine the listening port (default to 443 if not specified)
SSH_PORT=${PORT:-443}

# Start the SSH daemon in the foreground
echo "Starting sshd on port $SSH_PORT..."
exec /usr/sbin/sshd -D -p $SSH_PORT
