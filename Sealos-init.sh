# 替换 yum 为阿里源
cd  /etc/yum.repos.d/
mv  CentOS-Base.repo CentOS-Base.repo.bak && mv epel.repo epel.repo.bak
wget  http://mirrors.aliyun.com/repo/epel-7.repo && mv epel-7.repo epel.repo
wget  http://mirrors.aliyun.com/repo/Centos-7.repo && mv Centos-7.repo CentOS-Base.repo
yum clean all && yum makecache && yum update -y

# 安装常用工具
yum install -y vim ntpdate bash-completion net-tools git yum-versionlock nmap nfs-utils telnet unzip wget

# 关闭防火墙
systemctl stop firewalld && systemctl disable firewalld

# 升级内核 kernel-lt:长期支持版本 kernel-ml:稳定主线版本
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
yum --enablerepo=elrepo-kernel install -y kernel-ml
# 查看可升级内核命令
# yum --disablerepo="*" --enablerepo="elrepo-kernel" list available

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

# 每天1点同步一次时间
0 1 * * * /usr/sbin/ntpdate pool.ntp.org > /dev/null 2>&1
EOF

# 命令补全
# kubectl completion bash > /etc/bash_completion.d/kubectl

# 关闭 SElinx
if [ `getenforce` != "Disabled" ];then
    sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
fi

# 修改默认最大文件打开数
cat >> /etc/systemd/system.conf <<EOF
DefaultLimitNOFILE=65535
DefaultLimitNPROC=65535
EOF

# 修改 SSH 端口
sed -i "s@#Port 22@Port 1798@g" /etc/ssh/sshd_config

# 添加描述
cat <<'EOF'> /etc/motd


 ___  ____     ____     ______        ______   ________  _________     _
|_  ||_  _|  .' __ '. .' ____ \      |_   _ \ |_   __  ||  _   _  |   / \
  | |_/ /    | (__) | | (___ \_|______ | |_) |  | |_ \_||_/ | | \_|  / _ \
  |  __'.    .`____'.  _.____`.|______||  __'.  |  _| _     | |     / ___ \
 _| |  \ \_ | (____) || \____) |      _| |__) |_| |__/ |   _| |_  _/ /   \ \_
|____||____|`.______.' \______.'     |_______/|________|  |_____||____| |____|



EOF

# 添加高亮
echo "PS1='\[\e[1;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '" >> ~/.bashrc

# 设置 vim
cat <<'EOF'>> /etc/vimrc
" 设置默认 paste 模式
set paste
"设置tab键为2个空格
set tabstop=2
EOF

# 重启
reboot