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

# 1.2 Install Chinese Language Support
if ! locale -a | grep -q "zh_CN.utf8"; then
    echo "Installing Chinese Language Support..."
    apt-get install -y language-pack-zh-hans
    locale-gen zh_CN.UTF-8
    update-locale LANG=zh_CN.UTF-8
else
    echo "Chinese Language Support is already installed."
fi

# 2. Configure Firewall
echo "Configuring Firewall..."
ufw allow 'Nginx Full'
ufw allow 7890/tcp # GoAccess WebSocket

# 3. Setup Site Directory
echo "Setting up Site Directory..."
# SAFETY CHECK: Ensure we have new files to deploy before wiping
if [ ! -f "/tmp/index.html" ]; then
    echo "ERROR: Critical deployment files (index.html) missing in /tmp. Aborting deployment."
    exit 1
fi

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
    # Merge assets
    echo "Moving assets folder..."
    # Ensure destination parent exists (it should)
    # Move the entire assets folder to /var/www/deskcare/
    mv /tmp/assets /var/www/deskcare/
fi

# 5. Handle Updates (Zip & Version.json)
echo "Setting up Updates directory..."
mkdir -p /var/www/deskcare/updates
if [ -f "/tmp/version.json" ]; then
    # Move to updates folder
    cp /tmp/version.json /var/www/deskcare/updates/
    # Also move to root for website frontend to fetch
    mv /tmp/version.json /var/www/deskcare/
fi

ZIP_FILE=$1
if [ ! -z "$ZIP_FILE" ] && [ -f "/tmp/$ZIP_FILE" ]; then
    echo "Deploying update package: $ZIP_FILE"
    mv "/tmp/$ZIP_FILE" /var/www/deskcare/updates/
    
    # Also update the 'latest' download link in downloads folder if needed
    # But for now, we just keep it in updates
    
    # Ensure downloads folder has the latest zip too for the website button
    mkdir -p /var/www/deskcare/downloads
    cp "/var/www/deskcare/updates/$ZIP_FILE" /var/www/deskcare/downloads/
fi

# 6. Configure Nginx
echo "Configuring Nginx..."
mv /tmp/exercise_site.conf /etc/nginx/sites-available/deskcare
ln -sf /etc/nginx/sites-available/deskcare /etc/nginx/sites-enabled/
# Remove default site if it exists
rm -f /etc/nginx/sites-enabled/default

# 6. Restart Nginx
echo "Restarting Nginx..."
# Fix permissions
echo "Setting permissions..."
chown -R www-data:www-data /var/www/deskcare
chmod -R 755 /var/www/deskcare

nginx -t
systemctl restart nginx

# 7. Generate Initial Analytics Report
echo "Generating Analytics Report..."
mkdir -p /var/www/deskcare/stats

# Kill existing goaccess processes
pkill goaccess || true

# Parse Nginx access log and output to stats/report.html
# Use --daemonize to run in background reliably
# Use LC_ALL=zh_CN.UTF-8 for Chinese report
LC_ALL=zh_CN.UTF-8 LANG=zh_CN.UTF-8 goaccess /var/log/nginx/access.log --log-format=COMBINED -o /var/www/deskcare/stats/report.html --real-time-html --daemonize

echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo -e "Visit: http://47.101.52.0"
echo -e "Stats: http://47.101.52.0/stats/report.html"
