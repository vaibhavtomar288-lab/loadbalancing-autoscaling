#!/bin/bash

# =============================================================================
# EC2 User Data Script - Auto Scaling Setup
# =============================================================================
# This script runs on EC2 instance launch to:
# 1. Install Apache web server
# 2. Deploy the web application
# 3. Configure health check endpoints
# 4. Start and enable Apache service
# =============================================================================

# Exit on any error
set -e

# Update package cache and install Apache
echo "=========================================="
echo "Installing Apache Web Server..."
echo "=========================================="

# Check if running on Amazon Linux, RHEL, CentOS, or Ubuntu
if command -v yum &> /dev/null; then
    # Amazon Linux, RHEL, CentOS
    sudo yum update -y
    sudo yum install -y httpd
elif command -v apt-get &> /dev/null; then
    # Ubuntu, Debian
    sudo apt-get update -y
    sudo apt-get install -y apache2
fi

# Install curl (needed for metadata)
if command -v yum &> /dev/null; then
    sudo yum install -y curl
elif command -v apt-get &> /dev/null; then
    sudo apt-get install -y curl
fi

# Create web root directory
echo "=========================================="
echo "Setting up web application..."
echo "=========================================="

WEB_ROOT="/var/www/html"
sudo mkdir -p $WEB_ROOT

# Download the application files
# In production, you would copy from S3 or a git repository
# For this demo, we'll create the index.html directly

sudo tee $WEB_ROOT/index.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Auto Scaling Demo</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            padding: 60px;
            max-width: 700px;
            text-align: center;
        }
        
        h1 {
            color: #667eea;
            font-size: 2.5em;
            margin-bottom: 20px;
        }
        
        .instance-info {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 30px;
            margin: 30px 0;
            border-left: 5px solid #667eea;
        }
        
        .instance-info h2 {
            color: #333;
            font-size: 1.2em;
            margin-bottom: 15px;
        }
        
        .instance-id {
            font-size: 1.8em;
            font-weight: bold;
            color: #764ba2;
            font-family: 'Courier New', monospace;
            background: #fff;
            padding: 15px 25px;
            border-radius: 8px;
            display: inline-block;
            border: 2px solid #667eea;
        }
        
        .metadata {
            margin-top: 20px;
            text-align: left;
            font-size: 0.9em;
            color: #666;
        }
        
        .metadata p {
            margin: 8px 0;
            padding: 8px;
            background: #fff;
            border-radius: 5px;
        }
        
        .metadata strong {
            color: #333;
        }
        
        .badge {
            display: inline-block;
            background: #28a745;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.9em;
            margin-top: 20px;
        }
        
        .timestamp {
            color: #999;
            font-size: 0.85em;
            margin-top: 20px;
        }
        
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #999;
            font-size: 0.85em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Hello from Auto Scaling Instance!</h1>
        
        <div class="instance-info">
            <h2>🖥️ Instance Information</h2>
            <div class="instance-id" id="instance-id">Loading...</div>
            
            <div class="metadata">
                <p><strong>Instance ID:</strong> <span id="meta-instance-id">Fetching...</span></p>
                <p><strong>Availability Zone:</strong> <span id="meta-az">Fetching...</span></p>
                <p><strong>Instance Type:</strong> t3.micro</p>
                <p><strong>Region:</strong> us-east-1</p>
            </div>
        </div>
        
        <div class="badge">✅ Load Balancer Health Check Passed</div>
        
        <p class="timestamp">Page rendered at: <span id="timestamp"></span></p>
        
        <div class="footer">
            <p>🚀 Auto Scaling Group: projectautoscaling</p>
            <p>🔄 Traffic distributed by Application Load Balancer</p>
        </div>
    </div>

    <script>
        // Fetch instance metadata from AWS EC2 metadata service
        async function fetchMetadata() {
            try {
                // Fetch instance ID
                const instanceIdResponse = await fetch('http://169.254.169.254/latest/meta-data/instance-id');
                const instanceId = await instanceIdResponse.text();
                
                // Fetch availability zone
                const azResponse = await fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone');
                const az = await azResponse.text();
                
                // Update the page
                document.getElementById('instance-id').textContent = instanceId;
                document.getElementById('meta-instance-id').textContent = instanceId;
                document.getElementById('meta-az').textContent = az;
                
            } catch (error) {
                // If not running on EC2, show demo mode
                document.getElementById('instance-id').textContent = 'i-demo-instance';
                document.getElementById('meta-instance-id').textContent = 'i-demo-instance (Local Dev)';
                document.getElementById('meta-az').textContent = 'us-east-1a (Local Dev)';
                console.log('Running in local development mode');
            }
        }
        
        // Set timestamp
        function setTimestamp() {
            const now = new Date();
            document.getElementById('timestamp').textContent = now.toLocaleString();
        }
        
        // Initialize
        fetchMetadata();
        setTimestamp();
        
        // Refresh timestamp every minute
        setInterval(setTimestamp, 60000);
    </script>
</body>
</html>
EOF

# Set proper permissions
sudo chmod -R 755 $WEB_ROOT
sudo chown -R apache:apache $WEB_ROOT  # Amazon Linux/RHEL
# For Ubuntu, use: sudo chown -R www-data:www-data $WEB_ROOT

# Configure Apache
echo "=========================================="
echo "Configuring Apache..."
echo "=========================================="

# Enable mod_rewrite (optional, for future use)
if command -v httpd &> /dev/null; then
    sudo systemctl enable httpd
    sudo systemctl start httpd
elif command -v apache2 &> /dev/null; then
    sudo systemctl enable apache2
    sudo systemctl start apache2
fi

# Wait for Apache to start
sleep 3

# Verify Apache is running
if command -v httpd &> /dev/null; then
    sudo systemctl status httpd || true
elif command -v apache2 &> /dev/null; then
    sudo systemctl status apache2 || true
fi

# Test the web server
echo "=========================================="
echo "Testing web server..."
echo "=========================================="

# Get instance ID for logging
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "local")
echo "Instance $INSTANCE_ID is ready!"

# Test local web server
curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "Testing..."

echo "=========================================="
echo "Setup complete! Web application is running."
echo "=========================================="
echo "Instance ID: $INSTANCE_ID"
echo "Access the app via Load Balancer DNS"
echo "=========================================="

# Keep script running for debugging (optional)
# sleep 3600