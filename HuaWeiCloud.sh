#!/bin/bash
# author: Aka
# init scripts for CentOS 7.x (systemd)

# set yum source
echo -e "\033[31m ####################### 设置 yum 源为阿里源 ####################### \033[0m" 
cd  /etc/yum.repos.d/
mv  CentOS-Base.repo CentOS-Base.repo.bak && mv epel.repo epel.repo.bak
wget  http://mirrors.aliyun.com/repo/epel-7.repo && mv epel-7.repo epel.repo
wget http://mirrors.163.com/.help/CentOS7-Base-163.repo && mv CentOS7-Base-163.repo CentOS-Base.repo
yum clean all && yum makecache && yum update -y

# Set Hostname
echo -e "\033[31m ####################### 设置主机名为 IP 地址 ####################### \033[0m"  
IP=$(ip add | egrep -A 3 "enp0s3|eth0|em0" | grep -w inet | awk '{print $2}' | awk -F/ '{print $1}' | tr '.' '-')
hostnamectl set-hostname $IP
if [ $(cat /etc/hosts | grep $IP | wc -l ) -eq 0 ];then
    sed -i "1,2s/$/ $IP/" /etc/hosts
fi

# Install common commands
echo -e "\033[31m ####################### 安装常见包 ####################### \033[0m"  
yum install -y vim ntpdate bash-completion net-tools git yum-versionlock nmap nfs-utils telnet zip unzip wget epel-release bind-utils epel-release lrzsz iftop iotop htop

# Disable Service
echo -e "\033[31m ####################### 关闭与开启相关服务 ####################### \033[0m"  
systemctl disable firewalld
systemctl stop firewalld
systemctl disable postfix
systemctl stop postfix

# Update Kernel
echo -e "\033[31m ####################### 升级 Centos 内核 ####################### \033[0m"  
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
yum install -y --enablerepo=elrepo-kernel kernel-lt
grub2-set-default 0

# set vim
echo -e "\033[31m ####################### Vim 配置 ####################### \033[0m"  
cat <<'EOF'>> /etc/vimrc
" 设置默认 paste 模式
set paste
"设置tab键为2个空格
set tabstop=2
EOF

# 关闭 SElinx
if [ `getenforce` != "Disabled" ];then
    sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
fi

# 修改默认最大文件打开数
cat >> /etc/systemd/system.conf <<EOF
DefaultLimitNOFILE=65535
DefaultLimitNPROC=65535
EOF

# install docker
echo -e "\033[31m ####################### 安装 Docker 服务 ####################### \033[0m"  
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum -y install docker-ce-19.03.11-3.el7
systemctl daemon-reload && systemctl restart docker && systemctl enable docker

# install docker-compose
echo -e "\033[31m ####################### 安装 Docker Compose 服务 ####################### \033[0m"  
curl -L "https://get.daocloud.io/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# set docker daemon
echo -e "\033[31m ####################### 设置 Docker 镜像加速 ####################### \033[0m"  
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://pgwp6fr3.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload && systemctl restart docker

# set .bashrc
echo -e "\033[31m ####################### 设置高亮 ####################### \033[0m"  
echo "PS1='\[\e[1;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '" >> /root/.bashrc

# set ssh Port
echo -e "\033[31m ####################### 修改 SSH 端口 ####################### \033[0m"  
sed -i "s@#Port 22@Port 1798@g" /etc/ssh/sshd_config
service sshd restart

# 创建定时任务
cat <<'EOF'> /var/spool/cron/root
# 每30分钟 清理页面缓存
*/30 * * * * sync && echo 1 > /proc/sys/vm/drop_caches 2>&1
# 每30分钟清理索引节点（inode）链接
*/30 * * * * sync && echo 2 > /proc/sys/vm/drop_caches 2>&1
# 每30分钟 清理页面缓存＋索引节点链接
*/30 * * * * sync && echo 3 > /proc/sys/vm/drop_caches 2>&1

# 每周一清理无效镜像
* * * * 1 /usr/bin/docker image prune -a --force --filter "until=240h" 2>&1
EOF

# restart
reboot