# Deploy air-gapped registry application bundle
## Introduction
This document provides instructions on how to deploy the registry application bundle on a Linux RHEL environment without necessity of retrieving any dependency from public internet repositories.  This bundle is comprised of:
1. A main file which contains three container images:  
  a. Registry application  
  b. Postgres server  
  c. Redis server  
2. A `docker-compose.yml` file which orchestrates deployment and configuration of the above container images
3. A checksum verification file that validates the integrity of the main file.

**IMPORTANT NOTE: this deployment is designed for use in development and proof of concept stages only**.  It is not intended for deployment in a production environment. For deployment to a production environment, consider implementing best practices for containerized applications, which include secure handling of secrets, implementing scaling and orchestration solutions (such as Kubernetes), and setting up comprehensive monitoring and logging systems.

## Pre-requisites
1. Red Hat Linux server release 9.x
2. Docker engine and Docker compose installed on the above mentioned server
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
1. Log in and create application's root directory
```
mkdir CredentialRegistry
cd CredentialRegistry
``` 
2. Retrieve the checksum validation file
```
curl https://credregbundle.s3-accelerate.amazonaws.com/credregapp-bundle-v3.tar.gz.sha256 -o credregapp-bundle-v3.tar.gz.sha256
```
3. Retrieve and validate main bundle integrity
```
curl https://credregbundle.s3-accelerate.amazonaws.com/credregapp-bundle-v3.tar.gz -o credregapp-bundle-v3.tar.gz
sha256sum credregapp-bundle-v3.tar.gz
cat credregapp-bundle-v3.tar.gz.sha256

... then compare both values, they must match 4da3404df153d1087c7d7eb7f51d6bc2a194fec7c9e4f4855fcad27e85190be5

```
4. Uncompress the main bundle
```
tar xvzf credregapp-bundle-v3.tar.gz
```
5. Load docker images:
```
   docker load -i [docker images]
```
6. Create docker-compose.yml file:
```
version: '3'
services:
  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_PASSWORD=postgres
    ports:
      - 5432:5432
    volumes:
      - postgres:/var/lib/postgresql/data

  redis:
    image: redis:7.4.1
    expose:
      - 6379

  app:
    image: credentialregistry-app:latest-airgapped
    command: bash -c "bin/rake db:create db:migrate && bin/rackup -o 0.0.0.0"
    environment:
      - POSTGRESQL_ADDRESS=db
      - POSTGRESQL_DATABASE=cr_development
      - POSTGRESQL_USERNAME=postgres
      - POSTGRESQL_PASSWORD=postgres
      - REDIS_URL=redis://redis:6379/1
      - RACK_ENV=production
      - DOCKER_ENV=true
    volumes:
      - bundle:/usr/local/bundle
    ports:
      - 9292:9292
    depends_on:
      - db
      - redis
    security_opt:
      - seccomp:unconfined

volumes:
  bundle:
  postgres:
  rails_cache:
```

## Tech notes
### SELinux
The sandbox environment uses the SElinux mode "enforcing", and it does not need to mount "/app" directory using the label ":z" or ":Z".  Instead of we use label "/app:z" the application container returns "Could not locate Gemfile" which indicates that the application is not able to access the "/app" directory for reading.
