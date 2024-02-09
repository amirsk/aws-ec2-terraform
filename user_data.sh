#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo bash -c 'echo "<h1>Hello World</h1>" > /var/www/html/index.html'