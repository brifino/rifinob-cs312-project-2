#!/bin/bash

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Format Terraform files
echo "Formatting Terraform files..."
terraform fmt

# Validate Terraform files
echo "Validating Terraform files..."
terraform validate

# Create Infrastructure
echo "Creating Infrastructure..."
terraform apply -auto-approve

# Extract the public IP address of the EC2 instance
echo "Extracting the public DNS and IP addresses of the EC2 instance..."
PUBLIC_DNS=$(terraform output -raw minecraft_server_public_dns)
PUBLIC_IP=$(terraform output -raw minecraft_server_public_ip)

# Create a temporary inventory file for Ansible
echo "Creating a temporary inventory file for Ansible..."
echo "[minecraft_server]" > inventory
echo "$PUBLIC_DNS ansible_ssh_user=ec2-user ansible_ssh_private_key_file=./minecraftKeyFile" >> inventory

# sleep for 45 seconds to allow the EC2 instance to boot up
echo "Sleeping for 45 seconds to allow the EC2 instance to boot up..."
sleep 45

# Run Ansible playbook
echo "Running Ansible playbook..."
ansible-playbook -i inventory playbook.yml

# Remove the temporary inventory file
echo "Removing the temporary inventory file..."
rm inventory

# Sleep for 60 seconds to allow the Minecraft server to start
echo "Sleeping for 60 seconds to allow the Minecraft server to start..."
sleep 60

# Ping the server to check if it is up
echo "Pinging the Minecraft server on IP address: $PUBLIC_IP and port 25565..."
nmap -sV -Pn -p T:25565 $PUBLIC_IP

# Closing message
echo "Deployment completed successfully!"
