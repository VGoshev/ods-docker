#!/bin/bash
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

#Check, if tar file exists
ODS_TAR="OracleDeveloperStudio${ODS_VERSION}-linux-x86-bin.tar.bz2"
if [ ! -f ./$ODS_TAR ]; then
  echo "You need to download $ODS_TAR file first"
  echo "You can download it from official Oracle Developer Studio download  web page:"
  echo "  http://www.oracle.com/technetwork/server-storage/developerstudio/downloads/index.html"
  exit 1
fi


# Get user's UID and gid. So we'll create user with the same id's inside of Docker container
USER_GID=`id -g`
USER_UID=`id -u`

# But if we are doing this work under root user, then don't do all this.
if [ "x$USER_UID" != "x0" ]; then
  DOCKER_BUILD_ARGS="$DOCKER_BUILD_ARGS --build-arg USER_UID=$USER_UID --build-arg USER_GID=$USER_GID"
fi
# It would be good to get our password, but it is impossible, I think

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

# Now, with docker 1.13 we can use --squash option to squash all image layers into one:
#  https://github.com/docker/docker/pull/22641
# But only in experimental mode. 
#  See https://github.com/docker/docker/tree/master/experimental for more information about experimental mode
DOCKER_VERSION=`$DOCKER $DOCKER_ARGS version -f '{{.Server.Version}}'`
IS_EXPERIMENTAL=`$DOCKER $DOCKER_ARGS version -f '{{.Server.Experimental}}'`

# http://stackoverflow.com/questions/4023830/how-compare-two-strings-in-dot-separated-version-format-in-bash
vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

vercomp $DOCKER_VERSION "1.13.0"
DOCKER_13=$?
#0) =
#1) >
#2) <
# Do only for docker 1.13.0 and newer
if [ $DOCKER_13 -lt 2 ]; then
  if [ "$IS_EXPERIMENTAL" = "true" ]; then
    DOCKER_BUILD_ARGS="$DOCKER_BUILD_ARGS --squash"
  fi
fi

#We don't pass following arguments (use defaults):
# USER_PASSWD='$1$develope$TQhuT6npUu1n6QeTvcavi1'
# PRIVATE_IMAGE='NO'
$DOCKER $DOCKER_ARGS build \
  $DOCKER_BUILD_ARGS \
  --build-arg "ODS_VERSION=$ODS_VERSION" \
  --build-arg "DO_SSH_IMAGE=$SSH_IMAGE" \
  --build-arg "HTTP_PROXY=$HTTP_PROXY"  -t "$IMAGE_NAME" -f Dockerfile .
