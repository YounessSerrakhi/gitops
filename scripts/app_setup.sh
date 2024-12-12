#!/bin/bash
# Update and install dependencies
sudo yum update -y
sudo yum install -y httpd

# Start and enable Apache
sudo systemctl start httpd
sudo systemctl enable httpd

# Create a simple index.html for testing
echo "<h1>Welcome to SerrakhiApp</h1>" | sudo tee /var/www/html/index.html
