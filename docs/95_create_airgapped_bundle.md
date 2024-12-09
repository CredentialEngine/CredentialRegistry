
# Create air-gapped registry application bundle
## Introduction
This document provides instructions on how to create the registry application bundle on a Linux environment.  This bundle is comprised of:
1. A main file which contains three container images:  
  a. Registry application  
  b. Postgres server  
  c. Redis server  
2. A `docker-compose.yml` file which orchestrates deployment and configuration of the above container images
3. A checksum verification file that validates the integrity of the main file. (optional)


## Pre-requisites
1. Linux workstation
2. Docker engine installed on the above mentioned server
   Note: although Podman might be a replacement of the Docker package for Red Hat Linux we cannot guarantee that it works correctly, so we strongly suggests to use Docker engine instead.
   Hints:
   ```
   sudo dnf config-manager --add-repo=https://download.docker.com/linux/rhel/docker-ce.repo
   sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   sudo systemctl enable docker
   sudo systemctl start docker
   sudo usermod -G docker [your linux user]
   ```   
   

## Instructions
1. Log in and update the CredentialRegistry application repository (master branch)
2. Create an encrypted private key secret
    Hint:
    ```
    $ openssl rand -hex 32
    ```
    Copy the above 32 char string and keep it to use in the next step
3. Create a docker image of the registry application
    Hint: 
    ```
     $ docker build --no-cache  --platform linux/amd64 . -t credentialregistry-app:latest-airgapped  --build-arg ENCRYPTED_PRIVATE_KEY_SECRET=[the-above-generated-32-char-string]

    ```
4. Pull Redis image from Docker Hub
    Hint: 
    ```
    $ docker pull --platform linux/amd64 redis:7.4.1
    ```
5. Pull Postgres image from Docker Hub
    Hint: 
    ```
    $ docker pull --platform linux/amd64 postgres:16-alpine
    ```
6. Save docker images in a file
    Hint: 
    ```
    $ docker save -o credentialregistry-app-latest-airgapped.tar credentialregistry-app:latest-airgapped 
    $ docker save -o postgres-16-alpine.tar postgres:16-alpine
    $ docker save -o redis-7.4.1.tar redis:7.4.1
    ```
7. Create a full bundle
    Hint:
    ```
    $ tar cvzf credregapp-bundle-v3.tar.gz redis-7.4.1.tar postgres-16-alpine.tar credentialregistry-app-latest-airgapped.tar
    ```

8. Create checksum file (optional)
9. Upload to a corresponding remote storage location

