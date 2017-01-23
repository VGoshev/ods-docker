#!/bin/sh -e
#Build script for Oracle Developer Studio Docker Image

#For The Great Debug, of course
set -x

# Check if ODS version was passed to script
ODS_VERSION="12.5"
[ "x$1" != "x" ] && ODS_VERSION=$1

ODS_TAR="OracleDeveloperStudio${ODS_VERSION}-linux-x86-bin.tar.bz2"

# Set yum proxy, if needed
[ ! -z "$HTTP_PROXY" ] && echo "proxy=${HTTP_PROXY}" >> /etc/yum.conf 

# Check if we should add ssh (for remote development) to this image
SSH_PACKAGES=""
if [ "x$DO_SSH_IMAGE" == "xYES" ]; then
  #openssh-server is needed for ssh access
  #file is needed for remote debugging
  #
  #Actually openssh-server IS in oraclelinux image already (I do not know, what for)
  # but I want to be sure, that it is there for future
  SSH_PACKAGES="openssh-server file"
fi

# Install required packages
#  * tar and bzip2 are needed for extracting Oracle Developer Studio tarfile
#  * Other dependencies was taken from ODS manual:
#      https://docs.oracle.com/cd/E60778_01/html/E60741/gnzpf.html
# Some of them could be already in image, but whatever
yum install -y tar bzip2 \
  glibc glibc.i686 glibc-devel glibc-devel.i686 \
  elfutils-libelf-devel elfutils-libelf-devel.i686 libgcc-4.8.5-4.el7.x86_64 \
  zlib zlib.i686 libstdc++ libstdc++.i686 libgcc libgcc.i686 openssl openssl.i686 \
  $SSH_PACKAGES

#Unpack & Install Oracle Developer Studio
#We use --strip=1 to get rid of (useless) OracleDeveloperStudio{VERSION}-linux-x86-bin directory
#Also exclude some useless (for this image) ODS components (But not all unneded components are excludes, actually)
mkdir -p /opt/oracle
tar xjf "/tmp/$ODS_TAR" -C /opt/oracle --strip=1 \
   --exclude=developerstudio12.5/OIC \
   --exclude=developerstudio12.5/lib/netbeans \
   --exclude=developerstudio12.5/lib/devstudio \


#Add ODS path to PATH variables   
echo "PATH=\$PATH:/opt/oracle/developerstudio${ODS_VERSION}/bin" >> /etc/profile.d/studio.sh
echo "MANPATH=\$MANPATH:/opt/oracle/developerstudio${ODS_VERSION}/man" >> /etc/profile.d/studio.sh

#Create container run script (Needed for SSH version only, actually)
echo '#!/bin/sh' > /bin/docker-run
chmod +x /bin/docker-run
#In case of SSH image we need to add user
if [ "x$DO_SSH_IMAGE" == "xYES" ]; then
  #To create password you can use:
  #$ openssl passwd -1 -salt developer developer
  #$1$develope$TQhuT6npUu1n6QeTvcavi1
  #
  #Or read http://unix.stackexchange.com/questions/81240/manually-generate-password-for-etc-shadow
  uGID=''
  uUID=''
  uPASSWD='$1$develope$TQhuT6npUu1n6QeTvcavi1'
  [ ! -z "$USER_UID" ] && uUID=" -u $USER_UID "
  [ ! -z "$USER_GID" ] && uGID=" -g $USER_GID "
  [ ! -z "$USER_PASSWD" ] && uPASSWD=$USER_PASSWD

  groupadd $uGID developer 
  useradd $uUID $uGID -m -p "$uPASSWD" developer
  mkdir /home/developer/src

  #Just in case, clearing nproc limits for everybody
  echo '*          soft    nproc unlimited' >> /etc/security/limits.d/90-nproc.conf
  
  #In case of PRIVATE_IMAGE we can generate SSHd keys, so all instances will have the same key signature. Why not?
  if [ "x$PRIVATE_IMAGE" = "xYES" ]; then
    /etc/init.d/sshd start && /etc/init.d/sshd stop
  fi
  
  #Start SSHd with container
  echo '/etc/init.d/sshd start' >> /bin/docker-run
fi

# switch to bash (For SSH & not SSH containers)
echo 'exec /bin/bash' >> /bin/docker-run

# Clean unneded files
# deleteing of $ODS_TAR is quite useles because it is already present in previous level, bur docker build --squash fixes it (Or, at least, I hope so)
rm -f /tmp/$ODS_TAR
yum clean -y all
rm -rf /var/cache/yum/*
rm -f /var/log/yum.log

#Make locale-archive more compact
# StackOverflow-driven development:
#  http://unix.stackexchange.com/questions/90006/how-do-i-reduce-the-size-of-locale-archive
localedef --list-archive | grep -v -i ^en | xargs localedef --delete-from-archive
mv -f /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.tmpl
build-locale-archive 

