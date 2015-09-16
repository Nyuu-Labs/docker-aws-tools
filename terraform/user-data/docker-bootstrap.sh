#!/bin/sh

# Preparing EBS for mount
(file -s /dev/xvdk | grep -q ext4) || mkfs.ext4 /dev/xvdk

# Mount it
mount /dev/xvdk /mnt

# On EC2, the ephemeral disk might be mounted on /mnt.
# If /mnt is a mountpoint, place Docker workspace on it.
if mountpoint -q /mnt
then
	mkdir /mnt/docker
	ln -s /mnt/docker /var/lib/docker
fi

# Set the hostname to be the public IP address of the instance.
# If the call to myip fails, set a default hostname.
if ! curl --silent --fail curl http://169.254.169.254/latest/meta-data/public-ipv4 > /etc/hostname; then
    echo dockerhost > /etc/hostname
fi
service hostname restart

# adding prompt and some aliases
echo "
export PAGER='less'
export EDITOR='vim'

if [[ \$EUID -eq 0 ]] ; then
  export PS1='\[\e[0;34m\][\D{%T}] \[\e[1;31m\]\u@\H \w \[\e[0m\]> '
else
  export PS1='\[\e[0;34m\][\D{%T}] \[\e[1;32m\]\u@\H \w \[\e[0m\]> '
fi

alias ls='ls --color=auto --human-readable --classify'
alias df='df --human-readable'
alias du='du --human-readable'
alias rsync='rsync --numeric-ids'
alias grep='grep --color=auto'

alias l='ls -lhA1'
alias la='ls -lhA'
alias ll='ls -lh'
alias lsa='ls -lha'

HISTTIMEFORMAT='%Y/%m/%d %T '" | tee -a /etc/bash.bashrc /home/ubuntu/.bashrc /root/.bashrc /etc/skel/.bashrc

# Create Docker user.
useradd -d /home/docker -m -s /bin/bash docker

echo docker:docker | chpasswd

echo "docker ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/docker

sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && service ssh restart

apt-get -q update && apt-get -qy install git jq htop

# This will install the latest Docker.
curl -s https://get.docker.com/ | sh

# Allow connections through a local HTTP socket.
# This is to allow API experimentation with curl
# and communication with machines in the same SG as the current machine
echo 'DOCKER_OPTS="-H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375"' >> /etc/default/docker
service docker restart

pip install -U docker-compose

# Wait for docker to be up.
# If we don't do this, Docker will not be responsive during the next step.
while ! docker version
do
	sleep 1
done

echo "Docker is now ready ! Pulling some images for you..." | wall

# Pre-pull a bunch of images.
for I in \
	debian:latest ubuntu:latest fedora:latest centos:latest \
	redis swarm
do
	docker pull $I
done

echo "Post-deployment done." | wall
