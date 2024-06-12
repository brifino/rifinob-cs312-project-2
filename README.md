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
* Personal Computer or laptop with internet access
* Active AWS account
* SSH Client
* Terraform installed
* Ansible installed
* Git installed

## Setting Up AWS Credentials
We will use the AWS Cli to complete this task. For information on how to install the AWS Cli use the following link - <https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>
<br>
For educational purposes we will store our credentials and other important information in a directory named **aws-minecraft**.
You can choose the location of this directory but for the purpose of this tutorial we will store it in the home directory.
1. Open a terminal and navigate to the root directory
   * `cd ~`
2. Create a directory that will hold the AWS account credentials
   * `mkdir aws-minecraft
3. Navigate to this directory and create the credentials file
   * `cd aws-minecraft`
   * `touch credentials`
4. From the AWS module. Click the icon **AWS Details** located in the upper right corner.
   * ![AWS Details](/images/aws-details.png) 
5. Click the **Show** button that is next to the label **AWS CLI**
   * ![AWS CLI](/images/aws-credentials.png)
6. Follow the instructions by copying the text into the **credentials** file
7. Save the **credentials** file and close the text editor

## Creating a Key Pair
We will create a Key Pair that will be used to connect to the EC2 instance.

### Windows Users
1. You will need to create a key pair using PuTTY
     * [Detailed instuctions for using PuTTYgen](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html)
2. Save the key pair in the **aws-minecraft** directory
### Linux Users
1. Open a terminal and navigate to the **aws-minecraft** directory
   * `cd ~/aws-minecraft`
2. Enter `ssh-keygen -t rsa -b 4096 -a 100 -f minecraft-key` and press enter
3. Press enter to save the key in the current directory
4. Press enter to not use a passphrase
5. Change the permissions of the key
   * `chmod 400 minecraft-key`

### Move the public key to the 
   
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
        shared_credentials_file = ["./credentials"]
      }

      resource "aws_instance" "minecraft-server" {
        ami           = "ami-00a0b62a1660255c0"
        instance_type = "t4g.small"

        tags = {
          Name = "minecraft-server"
        }
      }
    ```

