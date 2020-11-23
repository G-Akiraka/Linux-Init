# install docker
echo -e "\033[31m ####################### 安装 Docker 服务 ####################### \033[0m"  
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y docker-ce-19.03.13-3.el7
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