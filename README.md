# <center> Course Project Part 2 </center>
### <center> CS312 System Administration - Oregon State University - Spring 2024 </center>
### <center> Brahm Rifino </center>
---
## Table of Contents
  - [Introduction](#introduction)
  - [Requirements](#requirements)
  - [Setting Up AWS Credentials](#setting-up-aws-credentials)
  - [Infrastructure Setup](#infrastructure-setup)
  - [Setting up a AWS EC2 Instance](#setting-up-a-aws-ec2-instance)
    - [Name and tags](#name-and-tags)
    - [Application and OS images](#application-and-os-images-amazon-machine-image)
    - [Instance type](#instance-type)
    - [Key pair](#key-pair-login)
    - [Network settings](#network-settings)
    - [Create and link elastic IP address](#create-and-link-elastic-ip-address)
  - [Connecting to our instance](#connecting-to-our-instance)
  - [Installing the Minecraft server](#installing-the-minecraft-server)
    - [Docker and Docker Compose](#docker-and-docker-compose)
    - [Minecraft server](#minecraft-server)
    - [Starting the Minecraft server](#starting-the-minecraft-server)
  - [Connecting to the Minecraft Server](#connecting-to-the-minecraft-server)
    - [Don't own Minecraft ?](#dont-own-minecraft)
  - [Conclusion](#conclusion)
## Introduction
This document will serve as a tutorial to set up and deploy a Minecraft Server on a Amazon Web Services Elastic Compute Cloud instance.<br>The entire process of creating and configuring a virtual machine on AWS, installing a Minecraft server and other necessary packages, and finally<br>connecting to the server.

## Requirements
* Personal Computer or labtop with internet access
* Active AWS account
* SSH Client
* Terraform installed
* Ansible installed
* Git installed

## Setting Up AWS Credentials
We will use the AWS Cli to complete this task. For information on how to install the AWS Cli use the following link - <https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>
1. Open a terminal and navigate to the root directory
   * `cd ~`
2. Create a directory that will hold the AWS account credentials
   * `mkdir .aws`
3. Navigate to this directory and create the credentials file
   * `cd .aws`
   * `touch credentials`
4. From the AWS module. Click the icon **AWS Details** located in the upper right corner.
   * ![AWS Details](/images/aws-details.png) 
5. Click the **Show** button that is next to the label **AWS CLI**
   * ![AWS CLI](/images/aws-credentials.png)
6. Follow the instructions by copying the text into the **credentials** file
7. Save the file and close the text editor


## Infrastructure Setup
Terraform will be used to create the EC2 AWS instance. For information on how to install Terraform use the following link - <https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli>
1. First we will create a directory
   1. Name this directory **aws-instance**
2. Open **aws-instance** and create a file named **main.tf**
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

      provider "aws" {
        region  = "us-west-2"
        shared_credentials_file = ["~/.aws/credentials"]
      }

      resource "aws_instance" "minecraft-server" {
        ami           = "ami-00a0b62a1660255c0"
        instance_type = "t4g.small"

        tags = {
          Name = "minecraft-server"
        }
      }
    ```


## Setting up a AWS EC2 Instance
1. Log in to your AWS account.
2. At the top right of the page (second from the right) there will be a button likely titled **N. Virginia** <br>
   This is the region in which our EC2 instance will "live".
   * For the purpose of this lab we will use the Oregon region. From the drop down menu select **US West (Oregon)**
3. Open the AWS Management Console. Once the screen loads, enter **EC2** in the search bar and click **EC2**.
4. Choose **Launch instance** button to open the instance creation wizard.
5. Next we will configure our EC2 minecraft server instance.
   
    #### Name and tags
    1. Lets name our server **minecraft-server** or something that's easy to remember.
   
    #### Application and OS images (Amazon Machine Image).
    2. Select **Amazon Linux 2023 AMI**
    3. Architecture **64-bit ARM**
    
    #### Instance type
    4. Select **t4g.small**
   
    #### Key pair (login)
    5. Click the **Create key pair** button
    6. Enter **minecraft-key** as the name
    7. Keep everything else as-is
    8. Click the **Create key pair** button
    9. The private key should automatically download
    10. Remember where the private key is saved! (We will use it later)
   
    #### Network settings
    11. Click the **Edit** button.
    12. Under **Firewall (security groups)**, Select **Create security group**
    13. Lets name our group **minecraft**
    14. Change **Description** to **minecraft security group**
    15. Now click the **Add security group rule** button
    16. Select **Custom TCP** from the **Type** menu.
    17. Enter **25565** in the **Port range** field
    18. Select **Anywhere** from the **Source type** menu
    19. Keep everything else as-is

6. Click the **Launch instance** button
7. Our EC2 instance is now configured!
8. One more step. Each time an instance is rebooted the public IP address will be changed. <br>The solution is creating a permanent IP address!

    #### Create and link elastic IP address
    1. From the EC2 dashboard navigate to **Network & Security** which will be on the left of your screen
    2. Select **Elastic IPs**
    3. Click the **Allocate Elastic IP address** button located in the upper right
    4. Don't change anything and select **Allocate**
    5. There will now be a IP address
    6. Check the small box on the left that corresponds to the new IP address
    7. Click the **Actions** button near the top right of screen
    8. Select **Associate Elastic IP address** from the drop down menu
    9. Choose **Instance** as the **Resource type**
    10. Click the search bar under **Instance**
    11. Find and select **minecraft-server**
    12. Click the **Associate** button
    13. The EC2 instance should now have a permanent IPv4 address

## Connecting to our instance
1. Go back to the EC2 page and click on our instance
2. Click the **Connect** button in the upper right corner
3. Under the **SSH** option we will copy the address (similar to below)
   * Linux users `ec2-user@ec2-44.241.253.2.us-west-2.compute.amazonaws.com`
   * Windows users `ec2-44.241.253.2.us-west-2.compute.amazonaws.com`
  
1. Using the SSH client of your choice we will log into our EC2 instance
   * Locate the key that we generated from earlier
   * LINUX
     * Open a terminal and type
       * `chmod 400 minecraft-key.pem`
       * `ssh -i "minecraft-key.pem" ec2-user@ec2-44.241.253.2.us-west-2.compute.amazonaws.com`
   * Windows
     * Using PuTTY enter the address portion into the host
       * `ec2-44.241.253.2.us-west-2.compute.amazonaws.com`
       * PuTTY uses a different key file format
       * You will have to download PuTTYgen and covert the .pem to a .ppk
         * [Detailed instuctions for using PuTTYgen](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html)
       * Once connected you will be prompted for a username
       * Type `ec2-user` and hit enter
2. You should now be logged into our EC2 instance

## Installing the Minecraft server
### Docker and Docker Compose
1. We are going to use **Docker** to run our server
2. Run the following commands
   * `sudo yum update -y`
   * `sudo yum install -y docker`
   * `sudo service docker start`
   * `sudo usermod -a -G docker ec2-user`
   * `sudo yum install -y git`
   * `sudo systemctl enable docker`
   * `sudo reboot`
3. Running the last command will end your SSH connection
4. Wait a few minutes while the system reboots
5. Log back into the instace like we did in [Connecting to our instance](#Connecting-to-our-instance)
6. Check that docker is running - Run the followin command
   * `docker ps`
7. Now we will download and install **Docker Compose**
  * `sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose`
8. When done enter
   * `sudo chmod +x /usr/local/bin/docker-compose`
   * `docker-compose version` Should print the current version

### Minecraft server
1. Lets make a directory and a Docker Compose file
    * `mkdir minecraft`
    * `cd minecraft`
    * `touch compose.yml`
2. Now we will edit our **compose.yml** file
    * `vim compose.yml`
3. Copy/type the following
   
    ``` 
    services: 
        minecraft-server:    
        image: itzg/minecraft-server    
        tty: true    
        stdin_open: true    
        ports:      
            - "25565:25565"    
        environment:      
            EULA: true    
        restart: always    
        volumes:      
            - ./data:/data 
    ```
   * Press the `ESC` key
   * Now type `:wq` and press `Enter`. This will save our changes
  
4. We should now be ready to start our server!

### Starting the Minecraft server
1. Run `docker-compose up -d`
2. Wait for **Docker** to finish setting up
3. Run `docker container ls`
   * You should see a similar output
    ```   
        CONTAINER ID   IMAGE                   COMMAND    CREATED        STATUS                 PORTS                                           NAMES
        f2c4729d7197   itzg/minecraft-server   "/start"   13 hours ago   Up 2 hours (healthy)   0.0.0.0:25565->25565/tcp, :::25565->25565/tcp   minecraft-minecraft-server-1
    ```
4. Now lets check that our server restarts on system reboot
5. Run `sudo reboot`
6. Login in to your EC2 instance like before
7. Enter `docker container ls` again
8. Take note of the **Status** field
    ```  
        STATUS 
        13 hours ago   Up 15 seconds (health: starting)
    ```
    ```  
        STATUS 
        13 hours ago   Up 2 minutes (healthy)
    ```
    > [!NOTE] 
    > * Make sure you see the "healthy" **STATUS**
    > * The container takes some time to start up
    > * Wait a bit and enter `docker container ls` again if needed

9. If you made it this far then were ready to start playing on our server!

## Connecting to the Minecraft server
### Already own Minecraft ?
1. Start **Minecraft** and logon
2. Click **Add Server**
3. Enter your EC2 IP address
4. Have fun!

### Don't own Minecraft ?
1. You can check that your server is accessible and running
2. Using a different computer
3. Enter `nmap -sV -Pn -p T:<query_port> <instance_public_ip>` using your configuration
   * Example `nmap -sV -Pn -p T:25565 44.241.253.2`
4. If you see an output like below then your server is running
    ```
        Nmap scap report for ec2-user@ec2-44.241.253.2.us-west-2.compute.amazonaws.com (44.241.253.2)
        Host is up

        PORT        STATE     SERVICE    VERSION
        25565/tcp   filtered  minecraft  Minecraft 1.20.6 (Protocol: 127, Message: A Minecrafter Server, Users: 0/20)
    ```

## Conclusion
You should now have a better understanding of how virtual machines operate on Amazon Web Services.<br>
AWS is a powerful cloud computing tool that offers much more than what was convered in this turtorial.<br>
Now go and show off your new skill to your friends, and most importantly keep learning!.