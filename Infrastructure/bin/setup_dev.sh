#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Allow edit for ${GUID}-jenkins project jenkins service account
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev

# Create MongoDB standalone persistent server from template
oc process -f ./Infrastructure/templates/mongodb_template_build.yaml | oc create -f - -n ${GUID}-parks-dev

# Create shared configmap for database connection
oc create configmap mongodb-config --from-literal=DB_HOST=mongodb --from-literal=DB_PORT=27017 --from-literal=DB_USERNAME=mongodb --from-literal=DB_PASSWORD=mongodb --from-literal=DB_NAME=parks -n ${GUID}-parks-dev

## Tasks for MLBParks microservice setup ##
# Create binary build using jboss-eap container called mlbparks
oc new-build --binary=true --name="mlbparks" jboss-eap70-openshift:1.7 -n ${GUID}-parks-dev
# Add image stream using mlbparks binary build
oc new-app mlbparks --name=mlbparks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
# Remoe build triggers from mlbparks deployment config
oc set triggers dc/mlbparks --remove-all -n ${GUID}-parks-dev
# Create configmap which will be loaded as env variables
oc create configmap mlbparks-config --from-literal=APPNAME="MLB Parks (Blue)" -n ${GUID}-parks-dev
# Add env variables from configmap to mlbparks deployment config
oc set env --from=configmap/mongodb-config dc/mlbparks -n ${GUID}-parks-dev
oc set env --from=configmap/mlbparks-config dc/mlbparks -n ${GUID}-parks-dev
# Expose mlbparks service on port 8080
oc expose dc mlbparks --port 8080 --labels=type=parksmap-backend -n ${GUID}-parks-dev


##  Tasks for NationalParks microservice setup ##
# Create binary build using openjdk18 container called nationalparks
oc new-build --binary=true --name="nationalparks" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
# Add image stream using nationalparks binary build
oc new-app nationalparks --name=nationalparks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
# Remoe build triggers from nationalparks deployment config
oc set triggers dc/nationalparks --remove-all -n ${GUID}-parks-dev
# Create configmap which will be loaded as env variables
oc create configmap nationalparks-config --from-literal=APPNAME="National Parks (Blue)" -n ${GUID}-parks-dev
# Add env variables from configmaps to nationalparks deployment config
oc set env --from=configmap/mongodb-config dc/nationalparks -n ${GUID}-parks-dev
oc set env --from=configmap/nationalparks-config dc/nationalparks -n ${GUID}-parks-dev
# Expose nationalparks service on port 8080
oc expose dc nationalparks --port 8080 --labels=type=parksmap-backend -n ${GUID}-parks-dev


##  Tasks for NationalParks microservice setup ##
# Allow permissions for discovering backend services
oc policy add-role-to-user view --serviceaccount=default
# Create binary build using openjdk18 container called parksmap
oc new-build --binary=true --name="parksmap" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
# Add image stream using parksmap binary build
oc new-app parksmap --name=parksmap --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
# Remoe build triggers from parksmap deployment config
oc set triggers dc/parksmap --remove-all -n ${GUID}-parks-dev
# Create configmap which will be loaded as env variables
oc create configmap parksmap-config --from-literal=APPNAME="ParksMap(Blue)" -n ${GUID}-parks-dev
# Add env variables from configmaps to nationalparks deployment config
oc set env --from=configmap/parksmap-config dc/parksmap -n ${GUID}-parks-dev
# Expose parksmap service on port 8080
oc expose dc parksmap --port 8080 --labels=type=parksmap -n ${GUID}-parks-dev
oc expose service parksmap --name=parksmap -n ${GUID}-parks-dev

