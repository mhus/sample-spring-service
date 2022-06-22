#!/bin/bash

version="latest"
docker_user="mhus"

if [ -z "$docker_pass" ]; then
  echo "Plese export docker_pass=... for user $docker_user"
  exit 1
fi

# check out soruces
kubectl exec -it -c box agent -- /bin/bash -c \
 "cd /home/jenkins/agent/;
 rm -rf sample-spring-service;
 git clone https://github.com/mhus/sample-spring-service.git"

# build jar file
kubectl exec -it -c maven agent -- \
 /bin/bash -c "cd /home/jenkins/agent/sample-spring-service;
 mvn package"

# pack container image
kubectl exec -it -c buildpacks agent -- /bin/bash -c \
 "cd /home/jenkins/agent/sample-spring-service;
 pack build sample-spring-service -p target/sample-spring-service-1.0.0-SNAPSHOT.jar -B paketobuildpacks/builder:base"

# push to docker hub
kubectl exec -it -c podman agent -- /bin/bash -c \
 "podman tag sample-spring-service docker.io/$docker_user/sample-spring-service:$version;"
kubectl exec -it -c podman agent -- /bin/bash -c \
 "podman login -u $docker_user -p '$docker_pass' docker.io/$docker_user"
kubectl exec -it -c podman agent -- /bin/bash -c \
 "podman push docker.io/$docker_user/sample-spring-service:$version"
