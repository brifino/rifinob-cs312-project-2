# <center> Course Project Part 2 </center>
### <center> CS312 System Administration - Oregon State University - Spring 2024 </center>
<center> Brahm Rifino </center>
---
## Table of Contents
  - [Introduction](#introduction)
  - [Requirements](#requirements)
  - [Setting Up AWS Credentials](#setting-up-aws-credentials)
  - [Creating a Key Pair](#creating-a-key-pair)
  - [Infrastructure Setup](#infrastructure-setup)
  - [Ansible Setup](#ansible-setup)
  - [Create a script to run the Terraform and Ansible commands](#create-a-script-to-run-the-terraform-and-ansible-commands)
  - [Now we are ready to deploy the Minecraft server!](#now-we-are-ready-to-deploy-the-minecraft-server)
  - [Conclusion](#conclusion)
  - [Cleaning up](#cleaning-up)
  - [References](#references)
## Introduction
This document will serve as a tutorial to set up and deploy a Minecraft Server on a Amazon Web Services Elastic Compute Cloud instance.<br> 
The entire process of creating and configuring a virtual machine on AWS, installing a Minecraft server 
and other necessary packages, and finally <br> 
connecting to the server.

> [!NOTE]
> This tutorial is intended for Linux/macOS users as some of the tools used are not available on Windows

## Requirements
* Personal Computer or laptop with internet access
* Active AWS account
* SSH Client
* Terraform installed
* Ansible installed
* Git installed

## Setting Up AWS Credentials
For educational purposes we will store our credentials and other important information in a directory named **aws-minecraft**.
You can choose the location of this directory but for the purpose of this tutorial we will store it in the home directory.
> [!NOTE]
> Remember that this is an educational project <br>
> In practice you should always keep your credentials secure and never share them with anyone.
1. Open a terminal and navigate to the root directory
   * `cd ~`
2. Create a directory that will hold the AWS account credentials
   * `mkdir aws-minecraft`
3. Navigate to this directory and create the credentials file
   * `cd aws-minecraft`
   * `touch credentials`
4. Open the AWS console in a web browser
5. From the AWS module. Click the icon **AWS Details** located in the upper right corner.
   * ![AWS Details](/images/aws-details.png) 
6. Click the **Show** button that is next to the label **AWS CLI**
   * ![AWS CLI](/images/aws-credentials.png)
7. Follow the instructions by copying the text into the **credentials** file
8. Save the **credentials** file and close the text editor

## Creating a Key Pair
We will create a Key Pair that will be used to connect to the EC2 instance.
1. Open a terminal and navigate to the **aws-minecraft** directory
   * `cd ~/aws-minecraft`
2. Enter `ssh-keygen -t rsa -b 4096 -a 100 -f minecraftKeyFile` and press enter
3. Press enter to save the key in the current directory
4. Press enter to not use a passphrase
5. Change the permissions of the key
   * `chmod 400 minecraftKeyFile`
   
## Infrastructure Setup
Terraform will be used to create the EC2 AWS instance. For information on how to install Terraform use the following link - <https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli>
1. In the directory that we've created (aws-minecraft) create a file named **main.tf**
   2. `touch main.tf`
3. Open main.tf in a text editor or similar tool
   1. Copy and paste the following
    
    ```
    terraform {
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 4.16"
        }
      }
    
      required_version = ">= 1.2.0"
    }
    
    # Configure the AWS Provider
    provider "aws" {
      region                   = "us-west-2"
      shared_credentials_files = ["./credentials"]
    }
    
    # Key pair for SSH access
    resource "aws_key_pair" "minecraft_key" {
      key_name   = "minecraft_key"
      public_key = file("${path.module}/minecraftKeyFile.pub")
    }
    
    
    # Security group for Minecraft server
    resource "aws_security_group" "minecraft_security_group" {
      name        = "minecraft-security-group"
      description = "Allow inbound traffic on port 25565"
    
      # Ingress rule for SSH access
      ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    
      # Allow inbound traffic on port 25565 - Minecraft server port
      ingress {
        from_port   = 25565
        to_port     = 25565
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    
      # Allow all outbound traffic
      egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
    
    # EC2 instance for Minecraft server
    resource "aws_instance" "minecraft_server" {
      ami                    = "ami-00a0b62a1660255c0"
      instance_type          = "t4g.small"
      key_name               = aws_key_pair.minecraft_key.key_name
      vpc_security_group_ids = [aws_security_group.minecraft_security_group.id]
    
      tags = {
        Name = "minecraft-server"
      }
    }
    
    # Output the public DNS of the Minecraft server
    output "minecraft_server_public_dns" {
      description = "The public DNS for SSH access to the Minecraft server"
      value       = aws_instance.minecraft_server.public_dns
    }
    # Output the public IP address of the Minecraft server
    output "minecraft_server_public_ip" {
      description = "The public IP address to ping the Minecraft server"
      value       = aws_instance.minecraft_server.public_ip
    }
    
    ```

4. Save the file and close the text editor

## Ansible Setup
Ansible will be used to install the Minecraft server on the EC2 instance. <br>
For information on how to install Ansible use the following link - <https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html>

**We will be running the Minecraft server in a Docker container**

1. In the directory that we've created (aws-minecraft) create a file named **playbook.yml**
   1. `touch playbook.yml`
2. Open playbook.yml in a text editor or similar tool
    1. Copy and paste the following
    ```     
    - name: Configure Minecraft Server
      hosts: all
      become: true
      vars:
        ansible_ssh_user: ec2-user
        ansible_ssh_private_key_file: ./minecraftKeyFile
    
      tasks:
        - name: Update all packages
          yum:
            name: "*"
            state: latest
    
        - name: Install Docker
          yum:
            name: docker
            state: present
    
        - name: Install Git
          yum:
            name: git
            state: present
    
        - name: Start and enable Docker
          systemd:
            name: docker
            state: started
            enabled: true
    
        - name: Add ec2-user to the docker group
          user:
            name: ec2-user
            groups: docker
            append: yes
    
        - name: Check that Docker is running
          systemd:
            name: docker
            state: started
            enabled: true
    
        - name: Create a Docker container for the Minecraft server
          docker_container:
            name: minecraft
            image: itzg/minecraft-server
            state: started
            restart_policy: always
            ports:
              - "25565:25565"
            env:
              EULA: "TRUE"
              VERSION: "LATEST"
    
        - name: Reboot the machine
          reboot:
            msg: "Rebooting the machine for changes to take effect"
            connect_timeout: 30
            reboot_timeout: 30
            pre_reboot_delay: 0
            post_reboot_delay: 30
            test_command: uptime
    ```
4. Save the file and close the text editor

## Create a script to run the Terraform and Ansible commands
1. In the directory that we've created (aws-minecraft) create a file named **deploy.sh**
   1. `touch deploy.sh`
2. Open deploy.sh in a text editor or similar tool
    1. Copy and paste the following
    ```
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
    
    ```
4. Save the file and close the text editor


## Now we are ready to deploy the Minecraft server!
1. Open a terminal and navigate to the **aws-minecraft** directory
   * `cd ~/aws-minecraft`
   * `chmod +x deploy.sh`
2. Run the script by entering `./deploy.sh` and press enter
3. You will be propmted to type `yes` to confirm the deployment
   1. Type `yes` and press enter
4. The script will take a few minutes to complete. Once it is done you will see a message that the deployment was successful
5. The script will output the public IP address of the EC2 instance. This is the address that you will use to connect to the Minecraft server
6. You can now connect to the Minecraft server using the public IP address and port 25565
7. You can ping the server to check if it is up by running the following command
   * `nmap -sV -Pn -p T:25565 <public-ip-address>`
   * Example `nmap -sV -Pn -p T:25565 44.241.253.2`
8. If you see an output like below then your server is running
    ```
        Nmap scap report for ec2-user@ec2-44.241.253.2.us-west-2.compute.amazonaws.com (44.241.253.2)
        Host is up

        PORT        STATE     SERVICE    VERSION
        25565/tcp   filtered  minecraft  Minecraft 1.20.6 (Protocol: 127, Message: A Minecrafter Server, Users: 0/20)
    ```
## Conclusion
You should now have a better understanding of how virtual machines operate on Amazon Web Services.<br>
AWS is a powerful cloud computing tool that offers much more than what was convered in this turtorial.<br>
Not only did you learn how to create a virtual machine on AWS, but you also learned how use Terraform and Ansible to automate the process!.<br>
Now go and show off your new skill to your friends, and most importantly keep learning!.

## Cleaning up
1. To stop the server and destroy the EC2 instance, run the following command
   * `terraform destroy -auto-approve`
   * This will stop the server and destroy the EC2 instance

## References
* [Terraform](https://www.terraform.io/)
  * [Tutorials](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build)
* [Ansible](https://www.ansible.com/)
  * [Tutorials](https://docs.ansible.com/ansible/latest/getting_started/index.html)
* [AWS](https://aws.amazon.com/)
* [Minecraft](https://www.minecraft.net/)
  * [Minecraft Docker Image](https://hub.docker.com/r/itzg/minecraft-server)
* [Docker](https://www.docker.com/)