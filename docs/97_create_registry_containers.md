# INTRO

This document contains instructions to set up the Registry application as docker containers, it is based on the assumption that the workstation is Debian/Ubuntu.

NOTE: this procedure is meant to be executed by an individual with basic docker/container management skills.  We will be installing docker, docker-compose, building docker images, running docker containers, etc.

## Overall solution

![alt text](image.png)

## Pre-requisites
1. Install Docker (below instructions might vary depending on the workstation's operating system)
Hint:
```
    sudo apt install docker -y
    sudo usermod ec2-user -G docker
```

2. Install Docker Compose (below instructions might vary depending on the workstation's operating system)
Hint:
```
    sudo systemctl start docker
    sudo apt install git -y
    sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m) -o /usr/bin/docker-compose && sudo chmod 755 /usr/bin/docker-compose && docker-compose --version
```

## Docker image build

If not already built the Registry application image must be build:

1. In your workstation access the CredentialRegistry repository (master branch)
2. Create an encrypted private key secret
   Hint:
   ```
   openssl rand -hex 32
   ```

   Copy the above 32 char string and keep it to use in the next step

3. Create a docker image of the registry application
   Hint:
   ```
    docker build --no-cache  . -t credentialregistry-app:latest  --build-arg ENCRYPTED_PRIVATE_KEY_SECRET=[the-previously-generated-32-char-string]
   ```

## Registry set up

    # Make sure that Ruby version in Dockerfile (line #1) matches the `.ruby-version` file (ie: `3.3.5`)
    docker-compose up -d
    docker-compose run app bundle exec rake db:create db:migrate
    docker-compose run app bundle exec rake app:generate_auth_token ADMIN_NAME=Admin PUBLISHER_NAME=Publisher USER_EMAIL=[valid email address] # (write down the resulting 32 alphanumeric code, this is your TOKEN for the next steps)
    docker-compose run app bundle exec rake app:create_envelope_community -- --name [community name] --default yes --secured no --secured-search yes


    curl -X POST localhost:9292/metadata/[community name]/config \
    --header 'Authorization: Bearer [TOKEN from previous step]' \
    --header 'Content-Type: application/json' \
    --data '{
        "description": "Minimal config",
        "payload": {
        "id_field": "ceterms:ctid",
        "skip_validation_enabled": true
        }
    }'

The Registry application should be accessible from internet through: https://[DNS record].credentialengineregistry.org
