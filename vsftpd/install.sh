#!/bin/bash
git="https://gitee.com/focusbe/installsh/raw/master/vsftpd/configs"
echo "安装vsftpd"
yum install vsftpd -y
echo "安装完成"
# 创建配置文件
echo "备份配置文件"
mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak
echo "创建配置文件"
wget "${git}/vsftpd.conf" -O "/etc/vsftpd/vsftpd.conf"
# 安装db4
yum install db4 db4-utils -y
# 创建用户
read -p "请输入用户名:" username
read -p "请输入密码:" password
touch /etc/vsftpd/vuser_passwd.txt
echo "${username}
${password}" >> /etc/vsftpd/vuser_passwd.txt
db_load -T -t hash -f /etc/vsftpd/vuser_passwd.txt /etc/vsftpd/vuser_passwd.db
mv /etc/pam.d/vsftpd /etc/pam.d/vsftpd.bak
wget "${git}/vsftpd.pam" -O "/etc/pam.d/vsftpd"

# 创建用户配置文件
mkdir /etc/vsftpd/vuser_conf
touch /etc/vsftpd/vuser_conf/${username}
echo "local_root=/var/ftp
write_enable=YES
anon_umask=022
anon_world_readable_only=NO
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
" >> /etc/vsftpd/vuser_conf/${username}
chown -R ftp:ftp /var/ftp
# 开启setsebool
setsebool -P allow_ftpd_anon_write=1
setsebool -P tftp_home_dir=1
setsebool -P allow_ftpd_full_access=1

# 设置防火墙

firewall-cmd --permanent --zone=public --add-port=21/tcp
firewall-cmd --permanent --zone=public --add-port=20/tcp
firewall-cmd --permanent --zone=public --add-port=40000-40100/tcp
firewall-cmd --reload

# 设置防火墙iptables
iptables -I INPUT -p tcp --dport 21 -j ACCEPT
iptables -I INPUT -p tcp --dport 20 -j ACCEPT
iptables -I INPUT -p tcp --dport 40000:40100 -j ACCEPT
service iptables save

# 重启vsftpd
systemctl restart vsftpd
systemctl enable vsftpd
echo "安装完成"
echo "用户名:${username}"
echo "密码:${password}"
echo "port:21"
echo "ip:$(curl -s https://ipinfo.io/ip)"
echo "请自行在服务商（阿里云/腾讯云）管理后台设置防火墙需开启端口 21,20，40000-40100"