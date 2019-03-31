#!/bin/sh -eux
export DEBIAN_FRONTEND=noninteractive

ubuntu_version="`lsb_release -r | awk '{print $2}'`";
major_version="`echo $ubuntu_version | awk -F. '{print $1}'`";

# Disable release-upgrades
sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades;

echo "修改源配置"
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
cat > /etc/apt/sources.list << EOF

deb http://mirrors.aliyun.com/ubuntu/ xenial main
deb-src http://mirrors.aliyun.com/ubuntu/ xenial main
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main
deb http://mirrors.aliyun.com/ubuntu/ xenial universe
deb-src http://mirrors.aliyun.com/ubuntu/ xenial universe
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates universe
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates universe
deb http://mirrors.aliyun.com/ubuntu/ xenial-security main
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main
deb http://mirrors.aliyun.com/ubuntu/ xenial-security universe
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security universe

EOF


# Update the package list
apt-get -y update;

# Disable systemd apt timers/services
if [ "$major_version" -ge "16" ]; then
  systemctl stop apt-daily.timer;
  systemctl stop apt-daily-upgrade.timer;
  systemctl disable apt-daily.timer;
  systemctl disable apt-daily-upgrade.timer;
  systemctl mask apt-daily.service;
  systemctl mask apt-daily-upgrade.service;
  systemctl daemon-reload;
fi

# Disable periodic activities of apt to be safe
cat <<EOF >/etc/apt/apt.conf.d/10periodic;
APT::Periodic::Enable "0";
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

# Clean and nuke the package from orbit
rm -rf /var/log/unattended-upgrades;
apt-get -y purge unattended-upgrades;

# Upgrade all installed packages incl. kernel and kernel headers
apt-get -y dist-upgrade -o Dpkg::Options::="--force-confnew";

echo "添加Docker源"

sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common bash-completion
sudo curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"

echo "安装Docker"
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export docker_version=17.03.2
sudo apt-get -y update
version=$(apt-cache madison docker-ce|grep ${docker_version}|awk '{print $3}')
sudo apt-get -y install docker-ce=${version} --allow-downgrades
sudo systemctl enable docker
