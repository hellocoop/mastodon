#!/bin/bash

git pull
if [ -n "$(git status --porcelain)" ]; then
  echo "repository is not clean -- check in all changes"
  exit 1
fi

export HELLO_VERSION=$(./hello_version.sh) 
echo HELLO_VERSION=${HELLO_VERSION}
git commit -a -m${HELLO_VERSION}
git tag ${HELLO_VERSION}
git push
git push --tags

docker login
docker build . -t hello-mastodon:latest -t hello-mastodon:${HELLO_VERSION} --build-arg HELLO_VERSION=${HELLO_VERSION}
docker tag hello-mastodon:latest docker.io/hellocoop/mastodon:${HELLO_VERSION}
docker tag hello-mastodon:latest docker.io/hellocoop/mastodon:latest
docker push docker.io/hellocoop/mastodon:${HELLO_VERSION}
docker push docker.io/hellocoop/mastodon:latest