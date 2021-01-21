# SBFspot multi-arch docker image 

Supported architectures: amd64, arm64, arm v7 Raspberry PI

## Create a local user
```shell
sudo groupadd -g 2000 sbfspot
sudo useradd -m -u 2000 -g 2000 -s /bin/bash sbfspot
```

## Set your time zone
```shell
sudo dpkg-reconfigure tzdata
```
## Setup Bluetooth

```shell
sudo bluetoothctl -a
[bluetooth]# default-agent
[bluetooth]# agent on
[bluetooth]# scan on
<... note MAC address of SMA inverter>
[bluetooth]# pair <MAC address>
[bluetooth]# exit
```

## Create/Run SBFspot collector container
```shell
docker create -t --restart=unless-stopped \
 -v /etc/localtime:/etc/localtime:ro \
 -v ~sbfspot/data:/var/smadata \ 
 -v ~sbfspot/config/SBFspot.cfg:/opt/sbfspot/SBFspot.cfg \
 --privileged \
 --name sbfspot-collector \
 registry-nexus.renait.nl/sbfspot-sqlite:3.7.1
```

## Running SBFspot uploader
```shell
docker run -dt \
 -v /etc/localtime:/etc/localtime:ro \
 -v /home/sbfspot/data:/var/smadata \
 -v /home/sbfspot/config/SBFspotUpload.cfg:/opt/sbfspot/SBFspotUpload.cfg \
 --name sbfspot-uploader \
 registry-nexus.renait.nl/sbfspot-sqlite:3.7.1 /opt/sbfspot/SBFspotUploadDaemon
```

## Configure crontab on Docker host

If you want the SBFspot collector container to be run automatically you can use standard crontab functionality to run it at set intervals;

Run the following command as root:

```shell
(crontab -u sbfspot -l 2>/dev/null; echo "*/5 5-23 * * * docker start -a sbfspot-collector > /dev/null 2>&1") | crontab -u sbfspot -
```

or:

```shell
sudo -iu sbfspot
crontab -e
```
and edit the crontab file by adding the following line:
```text
*/5 5-23 * * * docker start -a sbfspot-collector > /dev/null 2>&1
```
