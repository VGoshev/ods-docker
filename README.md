## Unofficial Oracle Developer Studio Docker image Dockerfile
### by Vladimir Goshev

Here you can found Dockerfile and helper scripts (and example of docker-compose.yml file as well)
for building (and running) image with Oracle Developer Studio and remote developing support.

## Building this image 
### Pre-requirements
To build this image (or images) you need do download 
Oracle Developer Studio (ODS) first 
(Because you need to read and accept ODS license to get it)
For that:
* Go to ODS download page: http://www.oracle.com/technetwork/server-storage/developerstudio/downloads/index.html
* Go to Tarfile Downloads
* Read and Accept license
* Download tar file for Oracle Linux/Red Hat Linux x86 architecture.
  * You would probably want to download IDE as well (ODS IDE is awesome for remote developmetn)
* Put downloaded tar file to directory with Dockerfile (i.e. ./build directory)

### Building with docker build command

After it you could run
  **`docker build -t ods ./build`**
(You probably would like to choose another image name)

If you have docker version `1.13.0` or newer and experimental features is turned on (see [docker documentation](https://github.com/docker/docker/tree/master/experimental) for details),
then you probably would like to use `--squash` build option to greatly reduce image size

This Dockerfile support various arguments, so read it for more details.

In case you've chosen SSH image, script will create user 'developer' 
 with password 'developer' in container. If you want to change password, 
 then you can pass USER_PASSWD build argument, see [Dockerfile](/docker/Dockerfile) for details.

In case you need to use proxy to access Internet, do not forget to pass 
**`--build-arg HTTP_PROXY=<...>`** 
environment variable HTTP_PROXY to build script 
(if it is isn't present in your environment already) or 
option to docker build command

### Building with docker-build.sh build script 

Build script accept up to 3 arguments:
* First one says if SSH image is building or not (use YES for SSH), default is YES
* Second one says ODS version, default is 12.5 (Only 12.5 was tested so far)
* Third one says image name, default is $USER/ods (or 'ods' for root)
    
Also build script support several environment variables:
* HTTP_PROXY - used for passing it to docker build (so yum inside of container will be able to reach its repositories)
* DOCKER - used if you need to specify path to docker binary or use sudo for running docker (use DOCKER="sudo docker" for it)
* DOCKER_ARGS - used for passing extra arguments to docker command (for example, you can set remote host, where you want to do build image)
* DOCKER_BUILD_ARGS - used for passing extra arguments to docker build command

Build script automatically detects your user ID and group ID and passes them to `docker build` command, it will also does some other checks like adding `--squash` to `docker build` to squashing image (which will delete layer with big tar.bz2 file) and some other minor things.

## Running containers

When your image will be built, you can run your container. 
Do not forget about following moments:
* Running dbx inside of container (as like other debuggers) require SYS_PTRACE capability, so you'll probably want to pass **`--cap-add=SYS_PTRACE`** option to docker run command
* You probably will want to use ssh inside of container, so do not forget to publish 22 port of container (for example with **`-p "127.0.0.1:10022:22"`** option)
* You probably will want to mount some host directory to container to being able to access sources (for example with **`-v /home/user/DevStudioProjects:/home/developer/src`** option)

Or you can use [docker-run.sh](/docker-run.sh) script to tun container. You can read this script to find, how it could be configured (this script uses ~/.docker-ods-ssh file for configuration)

There is also example [docker-compose.yml](/docker-compose.yml) file for docker-compose utility.
