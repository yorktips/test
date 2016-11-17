#!/bin/bash

# Set some global variables, in case they change in the future
FLEXSWITCH_TAG="flex2"
UBUNTU_VERSION="14.04"

# This is your ssh public key, in case you want to test out ansible
SSH_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdcNsRQzkzWIKUEz6OZqAXPGYvrEwgeC41W+uUP9ZMoDGP+mGCHHAFR3hXi+ICjtGMJZwWB4eTlg/5H+QM2f8msbVZ1IwLNw3oTTfIJnx0rQz0yfY+YR5l/vQIgihSD1Z5g+qvxOlKRibSCnPzEnilVz4LgVaY3c2V9PIiENTkcMUkIjznG2NVuf8M4yxCVEzaRS2tT4HdBEg2f3X97bt0LIVLwu+/kIQ3DyyjaSGez4iVjC1QpHb8xCmiPnqsqy1rpgPZP/xdKUcj5NW4M5OvhYD+Anc+ziy7CCH/8MrOmKxIwgz3N3tga1WcYW87DFpzGqgpQarA12/gFzRvvYmfrnrKMgvjxQjxIZzVvARRB8m+L4Tpde4Fof0q8BmG033r3R0/JFg6StKWIDqMnJVAa/0lVGAT97dsBQ1hAmc29YrDrYf900piSsE3acHf+p60pRg+/W6bDcNcVA2QqygBdTOvMMei82AKV/dUWBV4zFh3dZeFrBxIOljVsvpcmFtXvu24AbBNQvzUI9ltHT+7478DsO9E5A/GnL1QzSlPFgY8VJrsCpV5UkBZlsllD2YKitmTjnewprIy3H3jB4wRtJbQsF06TlHqkWEu1A2WHtXVFz4/6Vq2OERmzDLk4S7PFo9sleozHuWdjXkrksar4FbKJHuP2gc155Yf46WKsw== ansible"

sudo -l > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "cannot run sudo on host.  check your permissions"
    exit 1
fi

echo "***** Checkout the flexswitch base image *******"
docker pull snapos/flex:$FLEXSWITCH_TAG
echo "***** Checkout the ubuntu base image *******"
docker pull ubuntu:$UBUNTU_VERSION

echo "***** Spawn 6 docker instances core1 core2 access1 access2 host1 host2"

# core[1,2]
docker run -dt --privileged --log-driver=syslog --cap-add=ALL  --name core1 -P snapos/flex:$FLEXSWITCH_TAG
docker run -dt --privileged --log-driver=syslog --cap-add=ALL --name core2 -P snapos/flex:$FLEXSWITCH_TAG

# access[1,2]
docker run -dt --privileged --log-driver=syslog --cap-add=ALL  --name access1 -P snapos/flex:$FLEXSWITCH_TAG
docker run -dt --privileged --log-driver=syslog --cap-add=ALL --name access2 -P snapos/flex:$FLEXSWITCH_TAG

# host[1,2]
docker run -dt --privileged --log-driver=syslog --cap-add=ALL --name host1 -P ubuntu:$UBUNTU_VERSION
docker run -dt --privileged --log-driver=syslog --cap-add=ALL --name host2 -P ubuntu:$UBUNTU_VERSION

sleep 20

core1_pid=`docker inspect -f '{{.State.Pid}}' core1`
core2_pid=`docker inspect -f '{{.State.Pid}}' core2`
access1_pid=`docker inspect -f '{{.State.Pid}}' access1`
access2_pid=`docker inspect -f '{{.State.Pid}}' access2`
host1_pid=`docker inspect -f '{{.State.Pid}}' host1`
host2_pid=`docker inspect -f '{{.State.Pid}}' host2`

mkdir -p /var/run/netns

sudo ln -s /proc/$core1_pid/ns/net /var/run/netns/$core1_pid
sudo ln -s /proc/$core2_pid/ns/net /var/run/netns/$core2_pid
sudo ln -s /proc/$access1_pid/ns/net /var/run/netns/$access1_pid
sudo ln -s /proc/$access2_pid/ns/net /var/run/netns/$access2_pid
sudo ln -s /proc/$host1_pid/ns/net /var/run/netns/$host1_pid
sudo ln -s /proc/$host2_pid/ns/net /var/run/netns/$host2_pid

echo -e "done!\n"

# core1 <-> core2
sudo ip link add eth20 type veth peer name eth25
sudo ip link add eth21 type veth peer name eth26

# core1 <-> access1
sudo ip link add eth22 type veth peer name eth30

# core1 <-> access2
sudo ip link add eth23 type veth peer name eth41

# core2 <-> access2
sudo ip link add eth27 type veth peer name eth40

# core2 <-> access1
sudo ip link add eth28 type veth  peer name eth31

# access1 <-> host1
sudo ip link add eth32 type veth peer name eth50

# access2 <-> host2
sudo ip link add eth42 type veth peer name eth55

# core1
sudo ip link set eth20 netns $core1_pid
sudo ip netns exec $core1_pid ip link set eth20 up

sudo ip link set eth21 netns $core1_pid
sudo ip netns exec $core1_pid ip link set eth21 up

sudo ip link set eth22 netns $core1_pid
sudo ip netns exec $core1_pid  ip link set eth22 up

sudo ip link set eth23 netns $core1_pid
sudo ip netns exec $core1_pid  ip link set eth23 up

# core2
sudo ip link set eth25 netns $core2_pid
sudo ip netns exec $core2_pid ip link set eth25 up

sudo ip link set eth26 netns $core2_pid
sudo ip netns exec $core2_pid ip link set eth26 up

sudo ip link set eth27 netns $core2_pid
sudo ip netns exec $core2_pid ip link set eth27 up

sudo ip link set eth28 netns $core2_pid
sudo ip netns exec $core2_pid ip link set eth28 up

# access1
sudo ip link set eth30 netns $access1_pid
sudo ip netns exec $access1_pid ip link set eth30 up

sudo ip link set eth31 netns $access1_pid
sudo ip netns exec $access1_pid ip link set eth31 up

sudo ip link set eth32 netns $access1_pid
sudo ip netns exec $access1_pid ip link set eth32 up

# access2
sudo ip link set eth40 netns $access2_pid
sudo ip netns exec $access2_pid ip link set eth40 up

sudo ip link set eth41 netns $access2_pid
sudo ip netns exec $access2_pid ip link set eth41 up

sudo ip link set eth42 netns $access2_pid
sudo ip netns exec $access2_pid ip link set eth42 up

# host1
sudo ip link set eth50 netns $host1_pid
sudo ip netns exec $host1_pid ip link set eth50 up

# host2
sudo ip link set eth55 netns $host2_pid
sudo ip netns exec $host2_pid ip link set eth55 up


echo -e "Start flexswtich to pick up the interfaces "
echo "##############################"
echo "#######core1 FS restart######"
echo "##############################"
docker exec core1 sh -c "echo {} > /opt/flexswitch/events.json"
docker exec core1 sh -c "/etc/init.d/flexswitch restart"
docker exec core1 sh -c "hostname core1"
docker exec core1 sh -c "echo core1 > /etc/hostname"
docker exec core1 sh -c "rm -rf /var/lib/apt/lists/*"
docker exec core1 sh -c "apt-get update"
docker exec core1 sh -c "apt-get -y install ssh telnet tcpdump traceroute mtr"
docker exec core1 sh -c "mkdir -p /root/.ssh ; chmod 700 /root/.ssh ; echo $SSH_PUBLIC_KEY > /root/.ssh/authorized_keys ; chmod 600 /root/.ssh/authorized_keys"
# This is an awful hack to get around a permission denied error
docker exec core1 sh -c "mv /usr/sbin/tcpdump /usr/bin/tcpdump"


echo "##############################"
echo "#######core2 FS restart######"
echo "##############################"
docker exec core2 sh -c "echo {} > /opt/flexswitch/events.json"
docker exec core2 sh -c "/etc/init.d/flexswitch restart"
docker exec core2 sh -c "hostname core2"
docker exec core2 sh -c "echo core2 > /etc/hostname"
docker exec core2 sh -c "rm -rf /var/lib/apt/lists/*"
docker exec core2 sh -c "apt-get update"
docker exec core2 sh -c "apt-get -y install ssh telnet tcpdump traceroute mtr"
docker exec core2 sh -c "mkdir -p /root/.ssh ; chmod 700 /root/.ssh ; echo $SSH_PUBLIC_KEY > /root/.ssh/authorized_keys ; chmod 600 /root/.ssh/authorized_keys"
# This is an awful hack to get around a permission denied error
docker exec core2 sh -c "mv /usr/sbin/tcpdump /usr/bin/tcpdump"


echo "##############################"
echo "#######access1 FS restart######"
echo "##############################"
docker exec access1 sh -c "echo {} > /opt/flexswitch/events.json"
docker exec access1 sh -c "/etc/init.d/flexswitch restart"
docker exec access1 sh -c "hostname access1"
docker exec access1 sh -c "echo access1 > /etc/hostname"
docker exec access1 sh -c "rm -rf /var/lib/apt/lists/*"
docker exec access1 sh -c "apt-get update"
docker exec access1 sh -c "apt-get -y install ssh telnet tcpdump traceroute mtr"
docker exec access1 sh -c "mkdir -p /root/.ssh ; chmod 700 /root/.ssh ; echo $SSH_PUBLIC_KEY > /root/.ssh/authorized_keys ; chmod 600 /root/.ssh/authorized_keys"
# This is an awful hack to get around a permission denied error
docker exec access1 sh -c "mv /usr/sbin/tcpdump /usr/bin/tcpdump"


echo "##############################"
echo "#######access2 FS restart######"
echo "##############################"
docker exec access2 sh -c "echo {} >> /opt/flexswitch/events.json"
docker exec access2 sh -c "/etc/init.d/flexswitch restart"
docker exec access2 sh -c "hostname access2"
docker exec access2 sh -c "echo access2 > /etc/hostname"
docker exec access2 sh -c "rm -rf /var/lib/apt/lists/*"
docker exec access2 sh -c "apt-get update"
docker exec access2 sh -c "apt-get -y install ssh telnet tcpdump traceroute mtr"
docker exec access2 sh -c "mkdir -p /root/.ssh ; chmod 700 /root/.ssh ; echo $SSH_PUBLIC_KEY > /root/.ssh/authorized_keys ; chmod 600 /root/.ssh/authorized_keys"
# This is an awful hack to get around a permission denied error
docker exec access2 sh -c "mv /usr/sbin/tcpdump /usr/bin/tcpdump"


echo "##############################"
echo "#######host1 FS restart######"
echo "##############################"
docker exec host1 sh -c "hostname host1"
docker exec host1 sh -c "echo host1 > /etc/hostname"
docker exec host1 sh -c "rm -rf /var/lib/apt/lists/*"
docker exec host1 sh -c "apt-get update"
docker exec host1 sh -c "apt-get -y install ssh telnet tcpdump traceroute mtr"
docker exec host1 sh -c "mkdir -p /root/.ssh ; chmod 700 /root/.ssh ; echo $SSH_PUBLIC_KEY > /root/.ssh/authorized_keys ; chmod 600 /root/.ssh/authorized_keys"
docker exec host1 sh -c "/etc/init.d/ssh start"
# This is an awful hack to get around a permission denied error
docker exec host1 sh -c "mv /usr/sbin/tcpdump /usr/bin/tcpdump"
docker exec host1 sh -c "ifconfig eth50 inet 10.1.3.1/31 ; route delete default ; route add default gw 10.1.3.0"


echo "##############################"
echo "#######host2 FS restart######"
echo "##############################"
docker exec host2 sh -c "hostname host2"
docker exec host2 sh -c "echo host2 > /etc/hostname"
docker exec host2 sh -c "rm -rf /var/lib/apt/lists/*"
docker exec host2 sh -c "apt-get update"
docker exec host2 sh -c "apt-get -y install ssh telnet tcpdump traceroute mtr"
docker exec host2 sh -c "mkdir -p /root/.ssh ; chmod 700 /root/.ssh ; echo $SSH_PUBLIC_KEY > /root/.ssh/authorized_keys ; chmod 600 /root/.ssh/authorized_keys"
docker exec host2 sh -c "/etc/init.d/ssh start"
# This is an awful hack to get around a permission denied error
docker exec host2 sh -c "mv /usr/sbin/tcpdump /usr/bin/tcpdump"
docker exec host2 sh -c "ifconfig eth55 inet 10.1.4.1/31 ; route delete default ; route add default gw 10.1.4.0"
