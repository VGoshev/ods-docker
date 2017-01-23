## Unofficial Oracle Developer Studio Docker image Dockerfile
### by Vladimir Goshev

Here you can found Dockerfile and helper scripts (and example of docker-compose.yml file as well)
for building (and running) image with Oracle Developer Studio and remote developing support.

## Building this image 
### Prerequirements
To build this image (or images) you need do download 
Oracle Developer Studo (ODS) first 
(Because you need to read and accept ODS license to get it)
Fot that:
* Go to ODS download page: http://www.oracle.com/technetwork/server-storage/developerstudio/downloads/index.html
* Go to Tarfile Downloads
* Read and Accept license
* Download tarfile for Oracle Linux/Red Hat Linux x86 architecture.
  * You would probably want to download IDE as well (ODS IDE is awesome for remote developmetn)
* Put downloaded tarfile to directory with Dockerfile (i.e. ./build directory)

### Building with docker build command

After it you could run
  **`docker build -t ods ./build`**
(You probably would like to choose another image name)

This Dockerfile support various arguments, so read it for more details 

In case you've chosen SSH image, script will create user 'developer' 
 with password 'developer' in container. If you want to change password, 
 then you can read Dockerfile for details

In case you need to use proxy for internet acces, do not forget to pass 
**`--build-arg HTTP_PROXY=<...>`** 
option to docker build command
enviroment variable HTTP_PROXY to build script 
(if it is isn't present in your enviroment already) or 

### Building with docker-build.sh build script 

This script will use local python HTTP-server on host 
and curl inside of container for getting ODS tarfile 
(it will reduce image size for tarfile size).

Build script accept up to 3 arguments:
* First one says if SSH image is building or not (use YES for SSH), default is YES
* Second one says ODS version, default is 12.5 (Only 12.5 was tested so far)
* Third one says image name, default is $USER/ods (or 'ods' for root)
    
Also build script suppport several enviroment variables:
* HTTP_PROXY - used for passing it to docker build (so youm inside of container will be able to reach its repositories)
* DOCKER - used if you need to specify path to docker binary or use sudo for runnind docker (use DOCKER="sudo docker" for it)
* DOCKER_ARGS - used for passing extra arguments to docker command (for example, you can set remote host, where you want to do build image)
* DOCKER_BUILD_ARGS - used for passing extra arguments to docker build command

## Running containers

When your image will be built, you can run your container. 
Do not forget about following moments:
* Running dbx inside of container (as like other debuggers) require SYS_PTRACE capability, so you'll probably want to pass **`--cap-add=SYS_PTRACE`** option to docker run command
* You probably will want to use ssh inside of container, so do not forget to publish 22 port of container (for example with **`-p "127.0.0.1:10022:22"`** option)
* You probably will want to mount some host directory to container to being able to access sources (for example with **`-v /home/user/DevStudioProjects:/home/developer/src`** option)

Or you can use docker-run.sh script to tun container. You can read this script to find, how it could be configured (this script uses ~/.docker-ods-ssh file for configuration)

There is also example docker-compose.yml file for docker-compose utility.
