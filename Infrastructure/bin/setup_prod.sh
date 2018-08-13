#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Production Environment in project ${GUID}-parks-prod"

# Create MongoDB statefulset servers with 3 replicas from template
oc process -f ./Infrastructure/templates/mongodb_statefulset_template_build.yaml | oc create -f - -n ${GUID}-parks-prod

oc policy add-role-to-group system:image-puller system:serviceaccounts:${GUID}-parks-prod -n ${GUID}-parks-dev
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-prod

# Create shared configmap for database connection
oc create configmap mongodb-config --from-literal=DB_HOST=mongodb --from-literal=DB_PORT=27017 --from-literal=DB_USERNAME=mongodb --from-literal=DB_PASSWORD=mongodb --from-literal=DB_NAME=parks --from-literal=DB_REPLICASET=rs0 -n ${GUID}-parks-prod

## Tasks for MLBParks Blue microservice setup ##
# Create binary build using jboss-eap container called mlbparks-blue
oc new-build --binary=true --name="mlbparks-blue" jboss-eap70-openshift:1.7 -n ${GUID}-parks-prod
# Add image stream using mlbparks-blue binary build
oc new-app mlbparks-blue --name=mlbparks-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
# Remove build triggers from mlbparks-blue deployment config
oc set triggers dc/mlbparks-blue --remove-all -n ${GUID}-parks-prod
# Create configmap which will be loaded as env variables
oc create configmap mlbparks-config --from-literal=APPNAME="MLB Parks (Green)" -n ${GUID}-parks-prod
# Add env variables from configmap to mlbparks-blue deployment config
oc set env --from=configmap/mongodb-config dc/mlbparks-blue -n ${GUID}-parks-prod
oc set env --from=configmap/mlbparks-config dc/mlbparks-blue -n ${GUID}-parks-prod
# Expose mlbparks-blue service on port 8080 for deployment testing
oc expose dc mlbparks-blue --port 8080 --labels=activeApp=mlbparks-blue -n ${GUID}-parks-prod

## Tasks for MLBParks Green microservice setup ##
# Create binary build using jboss-eap container called mlbparks-green
oc new-build --binary=true --name="mlbparks-green" jboss-eap70-openshift:1.7 -n ${GUID}-parks-prod
# Add image stream using mlbparks-green binary build
oc new-app mlbparks-green --name=mlbparks-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
# Remove build triggers from mlbparks-green deployment config
oc set triggers dc/mlbparks-green --remove-all -n ${GUID}-parks-prod
# Add env variables from configmap to mlbparks-green deployment config
oc set env --from=configmap/mongodb-config dc/mlbparks-green -n ${GUID}-parks-prod
oc set env --from=configmap/mlbparks-config dc/mlbparks-green -n ${GUID}-parks-prod
# Expose mlbparks-green service on port 8080 for deployment testing
oc expose dc mlbparks-green --port 8080 --labels=activeApp=mlbparks-green -n ${GUID}-parks-prod

## Tasks for NationalParks Blue microservice setup ##
# Create binary build using redhat-openjdk18 container called nationalparks-blue
oc new-build --binary=true --name="nationalparks-blue" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-prod
# Add image stream using nationalparks-blue binary build
oc new-app nationalparks-blue --name=nationalparks-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
# Remove build triggers from nationalparks-blue deployment config
oc set triggers dc/nationalparks-blue --remove-all -n ${GUID}-parks-prod
# Create configmap which will be loaded as env variables
oc create configmap nationalparks-config --from-literal=APPNAME="MLB Parks (Green)" -n ${GUID}-parks-prod
# Add env variables from configmap to nationalparks-blue deployment config
oc set env --from=configmap/mongodb-config dc/nationalparks-blue -n ${GUID}-parks-prod
oc set env --from=configmap/nationalparks-config dc/nationalparks-blue -n ${GUID}-parks-prod
# Expose nationalparks-blue service on port 8080 for deployment testing
oc expose dc nationalparks-blue --port 8080 --labels=activeApp=nationalparks-blue -n ${GUID}-parks-prod

## Tasks for NationalParks Green microservice setup ##
# Create binary build using redhat-openjdk18 container called nationalparks-green
oc new-build --binary=true --name="nationalparks-green" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-prod
# Add image stream using nationalparks-green binary build
oc new-app nationalparks-green --name=nationalparks-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
# Remove build triggers from nationalparks-green deployment config
oc set triggers dc/nationalparks-green --remove-all -n ${GUID}-parks-prod
# Add env variables from configmap to nationalparks-green deployment config
oc set env --from=configmap/mongodb-config dc/nationalparks-green -n ${GUID}-parks-prod
oc set env --from=configmap/nationalparks-config dc/nationalparks-green -n ${GUID}-parks-prod
# Expose nationalparks-green service on port 8080 for deployment testing
oc expose dc nationalparks-green --port 8080 --labels=activeApp=nationalparks-green -n ${GUID}-parks-prod

##  Tasks for ParksMap microservice setup ##
# Allow permissions for discovering backend services
oc policy add-role-to-user view --serviceaccount=default
# Create binary build using openjdk18 container called parksmap-blue
oc new-build --binary=true --name="parksmap-blue" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-prod
# Add image stream using parksmap-blue binary build
oc new-app parksmap-blue --name=parksmap-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
# Remoe build triggers from parksmap deployment config
oc set triggers dc/parksmap-blue --remove-all -n ${GUID}-parks-prod
# Create configmap which will be loaded as env variables
oc create configmap parksmap-config --from-literal=APPNAME="ParksMap (Green)" -n ${GUID}-parks-prod
# Add env variables from configmap to nationalparks-blue deployment config
oc set env --from=configmap/parksmap-config dc/parksmap-blue -n ${GUID}-parks-prod
# Expose parksmap-blue service on port 8080
oc expose dc parksmap-blue --port 8080 --labels=type=parksmap-blue -n ${GUID}-parks-prod

##  Tasks for ParksMap microservice setup ##
# Create binary build using openjdk18 container called parksmap-green
oc new-build --binary=true --name="parksmap-green" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-prod
# Add image stream using parksmap-green binary build
oc new-app parksmap-green --name=parksmap-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
# Remove build triggers from parksmap deployment config
oc set triggers dc/parksmap-green --remove-all -n ${GUID}-parks-prod -n ${GUID}-parks-prod
# Add env variables from configmap to nationalparks-blue deployment config
oc set env --from=configmap/parksmap-config dc/parksmap-green -n ${GUID}-parks-prod
# Expose parksmap-green service on port 8080
oc expose dc parksmap-green --port 8080 --labels=type=parksmap-green -n ${GUID}-parks-prod
# Expose the parksmap-green service as starting external route
oc expose service parksmap-green --name=parksmap -n ${GUID}-parks-prod
oc expose service parksmap-green --name=parksmap-dark -n ${GUID}-parks-prod

