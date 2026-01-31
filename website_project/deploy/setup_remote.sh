#!/bin/bash
set -e

# Color codes
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}=== Starting DeskCare Site Deployment ===${NC}"

# 1. Install Nginx if not present
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    apt-get update
    apt-get install -y nginx
else
    echo "Nginx is already installed."
fi

# 1.1 Install GoAccess for Analytics
if ! command -v goaccess &> /dev/null; then
    echo "Installing GoAccess..."
    apt-get update
    apt-get install -y goaccess
else
    echo "GoAccess is already installed."
fi

# 2. Configure Firewall
echo "Configuring Firewall..."
ufw allow 'Nginx Full'

# 3. Setup Site Directory
echo "Setting up Site Directory..."
mkdir -p /var/www/deskcare
# Clean old files but keep the directory
rm -rf /var/www/deskcare/*

# 4. Move uploaded files
# Files are expected to be in /tmp/ from scp
echo "Moving files from /tmp/..."
mv /tmp/index.html /var/www/deskcare/
if [ -f "/tmp/vite.svg" ]; then
    mv /tmp/vite.svg /var/www/deskcare/
fi
if [ -d "/tmp/assets" ]; then
    mv /tmp/assets /var/www/deskcare/
fi
if [ -d "/tmp/downloads" ]; then
    mv /tmp/downloads /var/www/deskcare/
fi

# 5. Configure Nginx
echo "Configuring Nginx..."
mv /tmp/exercise_site.conf /etc/nginx/sites-available/deskcare
ln -sf /etc/nginx/sites-available/deskcare /etc/nginx/sites-enabled/
# Remove default site if it exists
rm -f /etc/nginx/sites-enabled/default

# 6. Restart Nginx
echo "Restarting Nginx..."
nginx -t
systemctl restart nginx

# 7. Generate Initial Analytics Report
echo "Generating Analytics Report..."
mkdir -p /var/www/deskcare/stats
# Parse Nginx access log and output to stats/report.html
# Use --log-format=COMBINED for standard Nginx logs
goaccess /var/log/nginx/access.log --log-format=COMBINED -o /var/www/deskcare/stats/report.html --real-time-html &

echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo -e "Visit: http://47.101.52.0"
echo -e "Stats: http://47.101.52.0/stats/report.html"
