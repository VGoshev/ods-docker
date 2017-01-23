#!/bin/sh
# Script for building ODS image in proper way
# $1 is make SSH image or standart one (use YES for SSH), default is YES
# $2 is ODS version, default is 12.5
# $3 is image name, default is $USER/ods

#Debug!
set -x

# CD to directory with Dockerfile
BUILD_DIR="./docker"
xPWD=`pwd`
RELATIVE_PATH=`dirname $0`
cd "$xPWD/$RELATIVE_PATH/$BUILD_DIR"


# In case you want to add something to "docker build" command
#DOCKER="echo docker"
#DOCKER="time docker"
#You could want add sudo here
[ -z "$DOCKER" ] && DOCKER="docker"
[ -z "$DOCKER_ARGS" ] && DOCKER_ARGS=""
[ -z "$DOCKER_BUILD_ARGS" ] && DOCKER_BUILD_ARGS=""

#Check if se should build SSH image or not
SSH_IMAGE="YES"
if [ ! -z "$1" ]; then
  SSH_IMAGE="$1"
fi

ODS_VERSION=12.5
if [ ! -z "$2" ]; then
  ODS_VERSION="$2"
fi

# Start lightweight Python HTTP Server
#  172.17.0.1 is default ip for host in docker network
#  Run python3 version or python2 version if python3 isn't found
CPID=
if which python3 >/dev/null; then
  python3 -m http.server --bind 172.17.0.1 8000 &
  CPID=$!
else
  python2 -m SimpleHTTPServer 8000 &
  CPID=$!
fi
#Wait 3 seconds to be sure, that http server have been started.
sleep 3


# Get user's UID and gid. So we'll create user with the same id's inside of Docker container
USER_GID=`id -g`
USER_UID=`id -u`

# But if we are doing this work under root user, then don't do all this.
if [ "x$USER_UID" != "x0" ]; then
  DOCKER_BUILD_ARGS="$DOCKER_BUILD_ARGS --build-arg USER_UID=$USER_UID --build-arg USER_GID=$USER_GID"
fi
# It would be goot to get our password, but it is impossible, i think

IMAGE_NAME=""
#Generate image name
if [ ! -z "$3" ]; then
  IMAGE_NAME="$3"
else
  #Get user name, for repository, if we aren't root
  USER_NAME=`id -un`
  if [ "$USER_NAME" = "root" ]; then
    IMAGE_NAME="ods"
  else
    IMAGE_NAME="${USER_NAME}/ods"
  fi
fi

#if we have md5sum utility, then add build.sh hash as build-arg
if which md5sum >/dev/null; then
  MD5HASH=`md5sum build.sh | awk {'print $1'}`
  DOCKER_BUILD_ARGS="$DOCKER_BUILD_ARGS --build-arg BUILD_SH_MD5=$MD5HASH"
else
  #Add --no-cache=true to invalidate cache if no md5 programs found
  DOCKER_BUILD_ARGS="$DOCKER_BUILD_ARGS --no-cache=true"
fi

#Which lines we should delete from Dockerfile
#No need to do COPY (it will not work anyway)
# You can add #|$ to strip Comments and empty lines as well (not very usefull however)
GREP='^\s*(COPY)'
#In case of NOT SSH image delete EXPOSE and VOLUME lines
if [ "x$SSH_IMAGE" != "xYES" ]; then
  GREP='^\s*(COPY|EXPOSE|VOLUME)'
fi

#$DOCKER $DOCKER_ARGS build -t "$IMAGE_NAME" -f Dockerfile .
#Fix Dockerfile and pass it to docker build
#We don't pass following arguments (use defaults):
# ODS_HOST='http://172.17.0.1:8000/'
# USER_PASSWD='$1$develope$TQhuT6npUu1n6QeTvcavi1'
# PRIVATE_IMAGE='NO'
#  --no-cache=true
cat Dockerfile | grep -vE "$GREP" | $DOCKER $DOCKER_ARGS build \
  $DOCKER_BUILD_ARGS \
  --build-arg "ODS_VERSION=$ODS_VERSION" \
  --build-arg "DO_SSH_IMAGE=$SSH_IMAGE" \
  --build-arg "HTTP_PROXY=$HTTP_PROXY"  -t "$IMAGE_NAME" -


#Stop(Kill) HTTP Server
kill $CPID
