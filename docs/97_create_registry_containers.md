# INTRO

This document contains instructions to set up the Registry application as docker containers, the AWS AMI (Amazon Machine Image) is standard Amazon Linux 2023 that was created using Terraform.

## Overall solution

![alt text](image.png)

## Pre-requisites

1. SSH client program, ie: Putty, or open-ssh (client).
2. Create a SSH key pair [hint](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html)
3. Import SSH keys recently created using AWS console [hint](https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#ImportKeyPair).
4. Create the AWS EC2 instance based on AWS AMI Linux 2023
5. Once the instance is created , use the SSH keys to access the AWS EC2 instance, ie:

   ```
   ssh -i [private key, ie: /home/my-user/.ssh/id_rsa] ec2-user@[instance ip addresss]
   ```

## Docker & Docker Compose install

    # Log in to the EC2 instance created in previous step using your ssh key (Hint: `ssh ec2-user@[IP address from previous step] -i [path to your private pem file]`  or using Putty program)
    sudo yum install docker -y
    sudo usermod ec2-user -G docker

    # log out and log back in from ssh session
    sudo systemctl start docker
    sudo yum install git -y
    sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m) -o /usr/bin/docker-compose && sudo chmod 755 /usr/bin/docker-compose && docker-compose --version

## Registry set up

    # Log in to the EC2 instance created in previous step using your ssh key (Hint: `ssh ec2-user@[IP address from previous step] -i [path to your private pem file]`  or using Putty program)
    git clone https://github.com/credentialengine/CredentialRegistry.git
    cd CredentialRegistry/

    # Make sure that Ruby version in Dockerfile (line #1) is 3.2.2
    docker-compose up -d
    docker-compose run app rake db:create db:migrate
    docker-compose run app rake app:generate_auth_token ADMIN_NAME=Admin PUBLISHER_NAME=Publisher USER_EMAIL=[valid email address] # (write down the resulting 32 alphanumeric code, this is your TOKEN)
    docker-compose run app rake app:create_envelope_community -- --name [community name] --default yes --secured no --secured-search yes


    curl -X POST localhost:9292/metadata/[community name]/config \
    --header 'Authorization: Bearer [TOKEN OBTAINED IN STEP #7]' \
    --header 'Content-Type: application/json' \
    --data '{
        "description": "Minimal config",
        "payload": {
        "id_field": "ceterms:ctid",
        "skip_validation_enabled": true
        }
    }'

The Registry application should be accessible from internet through: https://[DNS record].credentialengineregistry.org
