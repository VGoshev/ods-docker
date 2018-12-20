#!/bin/sh

#Default values could be changed in ~/.docker-ods-ssh config file

LOCAL_VOLUME_PATH="$HOME/DevStudioProjects"
LOCAL_PORT="127.0.0.1:10022"
CONTAINER_HOSTNAME="ODS"
CONTAINER_NAME="ods-ssh"
IMAGE_NAME=""
#Generate image name
CONTAINER_IMAGE="$USER/ods"
if [ "$USER" = "root" ]; then
	CONTAINER_IMAGE="ods"
fi
EXTRA_ARGS="-ti -d"
#You could want to add sudo here
DOCKER="docker"

[ -f ~/.docker-ods-ssh ] && . ~/.docker-ods-ssh

docker run --cap-add=SYS_PTRACE -v "$LOCAL_VOLUME_PATH:/home/developer/src" -p "$LOCAL_PORT:22" --name="$CONTAINER_NAME" --hostname="$CONTAINER_HOSTNAME" $EXTRA_ARGS  "$CONTAINER_IMAGE"
