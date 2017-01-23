#[Unofficial] Oracle Developer Studio image
FROM oracle/oraclelinux:6
MAINTAINER Vladimir Goshev <vladimir.goshev@oracle.com>

### !!! ###
#Do not forget to add --build-arg "HTTP_PROXY=$HTTP_PROXY" in case if you need to use proxy
### !!! ###

# Define some build arguments. #
#Where we can download ODS (in case of build script based build)
ARG ODS_HOST='http://172.17.0.1:8000/'
# ODS version to install (only 12.5 was tested so far)
ARG ODS_VERSION=12.5
# If we should add ssh to image (for remote developmetn support)
ARG DO_SSH_IMAGE='YES'
# user GID for created user (ssh image only)
ARG USER_GID=101024
# user UID for created user (ssh image only)
ARG USER_UID=101024
# user password hash for created user (ssh image only)
# default password is 'developer'
ARG USER_PASSWD='$1$develope$TQhuT6npUu1n6QeTvcavi1'
# If we should generate SSHd keys in build-time
ARG PRIVATE_IMAGE='NO'
# md5 hash of build.sh script. 
#  Should be used by docker-build.sh build script only 
#  (to not force cache invalidation)
ARG BUILD_SH_MD5="NONE"
#To create password hash you can use:
#$ openssl passwd -1 -salt <salt> <password>
#$ openssl passwd -1 -salt <salt> <password>
#Or read http://unix.stackexchange.com/questions/81240/manually-generate-password-for-etc-shadow

# I'm not sure if I should to declare ENV as well
#ENV ODS_HOST=$ODS_HOST \
#      ODS_VERSION=$ODS_VERSION \
#      USER_GID=$USER_GID \
#      USER_UID=$USER_UID \
#      USER_PASSWD=$USER_PASSWD \
#      DO_SSH_IMAGE=$DO_SSH_IMAGE \
#      PRIVATE_IMAGE=$PRIVATE_IMAGE

COPY build.sh /tmp/build.sh
COPY OracleDeveloperStudio${ODS_VERSION}-linux-x86-bin.tar.bz2 /tmp/OracleDeveloperStudio${ODS_VERSION}-linux-x86-bin.tar.bz2

#This image could be built via docker build command or with build script (docker-build.sh)
# Build script will pass all binaries via curl
# As this command depend on all ARGs, lets show what it uses them as ENV
RUN ODS_HOST=$ODS_HOST \
      ODS_VERSION=$ODS_VERSION \
      USER_GID=$USER_GID \
      USER_UID=$USER_UID \
      USER_PASSWD=$USER_PASSWD \
      DO_SSH_IMAGE=$DO_SSH_IMAGE \
      PRIVATE_IMAGE=$PRIVATE_IMAGE \
      HTTP_PROXY=$HTTP_PROXY \
      BUILD_SH_MD5=$BUILD_SH_MD5 \
      sh -c "if [ -f /tmp/build.sh ]; then \
        sh /tmp/build.sh $ODS_VERSION && rm /tmp/build.sh; else \
        curl -sSL \"$ODS_HOST/build.sh\" | sh -s $ODS_VERSION; fi"

# Expose and volue are valid for ssh image only
# But I don't want to maintain 2 separate Dockerfiles
# And ssh image is more usefull
EXPOSE 22
VOLUME /home/developer/src
CMD ["/bin/docker-run"]
