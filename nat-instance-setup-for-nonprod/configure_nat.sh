#!/bin/bash
sudo yum install iptables-services -y
sudo systemctl enable iptables
sudo systemctl start iptables
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/custom-ip-forwarding.conf
sudo sysctl -p /etc/sysctl.d/custom-ip-forwarding.conf
PRIMARY_IF=$(netstat -i | awk '/^e/{print $1; exit}')
sudo /sbin/iptables -t nat -A POSTROUTING -o $PRIMARY_IF -j MASQUERADE
sudo /sbin/iptables -F FORWARD
sudo service iptables save