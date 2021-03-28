# SBFspot multi-arch docker image 

Docker image for SBFspot. For more documentation about this project see https://github.com/SBFspot/SBFspot.

Typically you create a container which is run every x minutes to collect data from your inverter. Next you
(optionally) create another container which will upload data to pvoutput.org. 

Supported architectures: amd64, arm64, arm v7 Raspberry PI

## 1. Create a local user
```shell
sudo groupadd -g 2000 sbfspot
sudo useradd -m -u 2000 -g 2000 -s /bin/bash sbfspot
sudo -iu sbfspot
mkdir config
mkdir data
```

## 2. Set your time zone
```shell
sudo dpkg-reconfigure tzdata
```
## 3. Setup Bluetooth

Note: these instructions were tested on ubuntu 20.04 for pi.

Install bluetooth (if not done already)
```shell
sudo apt install bluetooth pi-bluetooth
sudo reboot
```

### 3.1 Pair with SMA converter

```shell
sudo bluetoothctl [-a]
[bluetooth]# default-agent
[bluetooth]# agent on
[bluetooth]# scan on
<... note MAC address of SMA inverter>
[bluetooth]# pair <MAC address>
[bluetooth]# trust <MAC address>
[bluetooth]# exit
```

## 4. Setup Docker containers

Install docker (if not done already)

```shell
sudo apt install docker.io
sudo docker pull solarexplorer/sbfspot-sqlite 
```

### 4.1 Test inverter connectivity
```shell
docker run -it --rm \
 -v /etc/localtime:/etc/localtime:ro \
 -v ~sbfspot/data:/var/smadata \
 -v ~sbfspot/config/SBFspot.cfg:/opt/sbfspot/SBFspot.cfg \
 --device=/dev/tty \
 --net=host \
 solarexplorer/sbfspot-sqlite /opt/sbfspot/SBFspot -v -finq -nocsv -nosql
```

### 4.2 Create SBFspot daily collector container
```shell
docker create -t \
 -v /etc/localtime:/etc/localtime:ro \
 -v ~sbfspot/data:/var/smadata \
 -v ~sbfspot/config/SBFspot.cfg:/opt/sbfspot/SBFspot.cfg \
 --device=/dev/tty \
 --net=host \
 --name sbfspot-daydata \
 solarexplorer/sbfspot-sqlite /opt/sbfspot/SBFspot -v -ad1 -am0 -ae1
```

### 4.3 Create SBFspot monthly collector container (optional)
```shell
docker create -t \
 -v /etc/localtime:/etc/localtime:ro \
 -v ~sbfspot/data:/var/smadata \
 -v ~sbfspot/config/SBFspot.cfg:/opt/sbfspot/SBFspot.cfg \
 --device=/dev/tty \
 --net=host \
 --name sbfspot-monthdata \
 solarexplorer/sbfspot-sqlite /opt/sbfspot/SBFspot -v -sp0 -ad0 -am1 -ae1 -finq
```

### 4.4 Run SBFspot PVoutput uploader (optional)
```shell
docker run -dt --restart=unless-stopped \
 -v /etc/localtime:/etc/localtime:ro \
 -v /home/sbfspot/data:/var/smadata \
 -v /home/sbfspot/config/SBFspotUpload.cfg:/opt/sbfspot/SBFspotUpload.cfg \
 --name sbfspot-uploader \
 solarexplorer/sbfspot-sqlite /opt/sbfspot/SBFspotUploadDaemon
```

## 5. Configure crontab on Docker host

If you want the SBFspot collector container to be run automatically you can use standard crontab functionality to run it at set intervals;

Run the following command as root:

```shell
(crontab -u sbfspot -l 2>/dev/null; echo "*/5 5-23 * * * docker start -a sbfspot-daydata > /dev/null 2>&1") | crontab -u sbfspot -
```

or:

```shell
sudo -iu sbfspot
crontab -e
```
and edit the crontab file by adding the following line:
```text
*/5 5-23 * * * docker start -a sbfspot-daydata > /dev/null 2>&1
```

## 6. Build this image locally

Build image and load into local docker.

```shell
docker buildx build -t solarexplorer/sbfspot-sqlite --load .
```
