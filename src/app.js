/**
 * AWS Auto Scaling Demo - Instance Metadata Fetcher
 * 
 * This script fetches EC2 instance metadata from the AWS metadata service
 * and updates the page with instance information.
 */

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
        
        // Set timestamp
        const now = new Date();
        document.getElementById('timestamp').textContent = now.toLocaleString();
        
        console.log('Instance Metadata:', { instanceId, az });
    } catch (error) {
        console.error('Error fetching metadata:', error);
        
        // Show fallback values when not running on EC2
        document.getElementById('instance-id').textContent = 'local-dev';
        document.getElementById('meta-instance-id').textContent = 'i-xxxxxxxx';
        document.getElementById('meta-az').textContent = 'us-east-1a';
        
        const now = new Date();
        document.getElementById('timestamp').textContent = now.toLocaleString();
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', fetchMetadata);