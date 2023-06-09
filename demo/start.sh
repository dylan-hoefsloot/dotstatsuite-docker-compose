#!/bin/bash

##################
# Initialization #
##################
HOST=$1
DIR_CONFIG='./config'
#determine current OS
CURRENT_OS=$(uname -s)
echo "OS detected: $CURRENT_OS"

if [ -z "$HOST" ]; then
   #If HOST parameter is not provided, use the default hostname/address:

   # if [ "$CURRENT_OS" = "Darwin" ]; then
   #    # Max OS X - not tested!!!
   #    HOST=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | head -1);
   # else
      HOST="host.docker.internal"
   # fi
fi

# Display the hostname/ip address that will be applied on configuration files
COLOR='\033[1;32m'
NOCOLOR='\033[0m' # No Color
# Remove existing configuration directory (of JavaScript services)
if [ -d $DIR_CONFIG ]; then
   echo -e "Delete config ? (if yes, latest one will be downloaded with the host adress: $COLOR $HOST $NOCOLOR)? (Y/N)"
   while true; do
      read -p "" yn
      case $yn in
         [Yy]* ) ./scripts/download-config.sh; break;;
         [Nn]* ) break;;
         * ) echo "Please answer yes or no.";;
      esac
   done
fi
if [ ! -d $DIR_CONFIG ]; then
   ./scripts/download-config.sh;
fi


# Re-initialize js configuration
scripts/init.config.mono-tenant.two-dataspaces.sh $HOST

# Apply host value at KEYCLOAK_HOST variable in ENV file
sed -Ee "s#^KEYCLOAK_HOST=.*#KEYCLOAK_HOST=$HOST#g" .env

# Apply host value at HOST variable in ENV file
sed -Ee "s#^HOST=.*#HOST=$HOST#g" .env

#########################
# Start docker services #
#########################

read -p "Clean solr volumes ? (Y/N)" cl
if [ $cl = 'y' ] || [ $cl = 'Y' ]
then
   scripts/clean-solr-volumes.sh;
fi

echo "Starting Keycloak services"
docker compose -f docker-compose-demo-keycloak.yml up -d

echo "Starting .Net services"
docker compose -f docker-compose-demo-dotnet.yml up -d

echo "Starting JS services"
docker compose -f docker-compose-demo-js.yml up -d

echo -n "Services being started."

#Wait until keycloak service is started ('Admin console listening' message appears in log')
LOG="$(docker logs keycloak 2>&1 | grep -o 'Admin console listening')"

while [ -z "$LOG" ];
do
   echo -n "."
   sleep 2

   LOG="$(docker logs keycloak 2>&1 | grep -o 'Admin console listening')"
done

echo "."
echo "Switching off HTTPS requirement in Keycloak"
./scripts/disable-ssl.sh

echo "Services started:"

docker ps
