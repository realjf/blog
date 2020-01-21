---
title: "Ceph 集群搭建二 之 预检"
date: 2019-03-19T14:57:09+08:00
keywords: ["ceph", "ceph集群"]
categories: ["分布式存储", "ceph"]
tags: ["ceph", "ceph集群搭建", "分布式存储"]
series: ["ceph集群搭建"]
draft: false
related:
  threshold: 80
  includeNewer: false
  toLower: false
  indices:
  - name: keywords
    weight: 100
  - name: tags
    weight: 90
  - name: categories
    weight: 50
  - name: date
    weight: 10
---

集群部署如下：
![http://blog.realjf.com/wp-content/uploads/2018/12/ceph-admin.png](http://blog.realjf.com/wp-content/uploads/2018/12/ceph-admin.png)

## 预检
#### 安装ceph部署工具
在 Red Hat （rhel6、rhel7）、CentOS （el6、el7）和 Fedora 19-20 （f19 - f20） 上执行下列步骤：
##### 用subscription-manager注册你的目标机器，确认你的订阅，并启用安装依赖包的extras软件仓库。例如：
```
sudo subscription-manager repos --enable=el-7-server-extras-rpms
```

##### 在centos上执行以下命令
```
sudo yum install -y yum-utils && sudo yum-config-manager --add-repo https://dl.fedoraproject.org/pub/epel/7/x86_64/ && sudo yum install --nogpgcheck -y epel-release && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 && sudo rm /etc/yum.repos.d/dl.fedoraproject.org*
```

##### 把软件包源加入软件仓库。用文本编辑器创建一个 YUM (Yellowdog Updater, Modified) 库文件，其路径为 /etc/yum.repos.d/ceph.repo 
```
sudo vim /etc/yum.repos.d/ceph.repo
```
把如下内容粘帖进去，用 Ceph 的最新主稳定版名字替换 {ceph-stable-release} （如 firefly，hammer, infernalis ），用你的Linux发行版名字替换 {distro} （如 el6 为 CentOS 6 、 el7 为 CentOS 7 、 rhel6 为 Red Hat 6.5 、 rhel7 为 Red Hat 7 、 fc19 是 Fedora 19 、 fc20 是 Fedora 20 ）。最后保存到 /etc/yum.repos.d/ceph.repo 文件中。

```
[ceph-noarch]
name=Ceph noarch packages
baseurl=http://download.ceph.com/rpm-{ceph-release}/{distro}/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc

# 如：
[Ceph]
name=Ceph packages for $basearch
baseurl=http://mirrors.163.com/ceph/rpm-jewel/el7/$basearch
enabled=1
gpgcheck=0
type=rpm-md
gpgkey=https://mirrors.163.com/ceph/keys/release.asc
priority=1

[Ceph-noarch]
name=Ceph noarch packages
baseurl=http://mirrors.163.com/ceph/rpm-jewel/el7/noarch
enabled=1
gpgcheck=0
type=rpm-md
gpgkey=https://mirrors.163.com/ceph/keys/release.asc
priority=1

[ceph-source]
name=Ceph source packages
baseurl=http://mirrors.163.com/ceph/rpm-jewel/el7/SRPMS
enabled=1
gpgcheck=0
type=rpm-md
gpgkey=https://mirrors.163.com/ceph/keys/release.asc
priority=1
```

##### 更新软件库并安装ceph-deploy
```
sudo yum update && sudo yum install ceph-deploy -y
```

#### ceph节点安装
##### 配置hosts文件
cat /etc/hosts
```
192.168.1.1 node1
192.168.1.2 node2
192.168.1.3 node3
```
修改hostname
```
hostnamectl set-hostname node1
```


你的管理节点必须能够通过 SSH 无密码地访问各 Ceph 节点。如果 ceph-deploy 以某个普通用户登录，那么这个用户必须有无密码使用 sudo 的权限。

##### 安装NTP
```
yum install ntp ntpdate ntp-doc
```

##### 安装ssh服务器
```
yum install openssh-server
```

##### 创建部署ceph的用户
较新版的 ceph-deploy 支持用 --username 选项提供可无密码使用 sudo 的用户名（包括 root ，虽然不建议这样做）。使用 ceph-deploy --username {username} 命令时，指定的用户必须能够通过无密码 SSH 连接到 Ceph 节点，因为 ceph-deploy 中途不会提示输入密码。

```
useradd -d /home/{username} -m {username}
passwd {username}

# 确保ceph节点上新创建用户的sudo权限
echo "{username} ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/{username}
chmod 0440 /etc/sudoers.d/{username}

echo "ceph ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph
chmod 0440 /etc/sudoers.d/ceph
```

##### 允许无密码ssh登录
正因为 ceph-deploy 不支持输入密码，你必须在 **管理节点** 上生成 SSH 密钥并把其公钥分发到各 Ceph 节点。ceph-deploy 会尝试给初始 monitors 生成 SSH 密钥对。

生成ssh密钥对，但不要sudo或root用户。
```
ssh-keygen
```
把公钥拷贝到各ceph节点，把下列命令中的{username}替换成前面创建的用户名
```
ssh-copy-id {username}@node1
ssh-copy-id {username}@node2
ssh-copy-id {username}@node3
```


##### 确保连通性

##### 开放所需端口
若使用iptables，要开放ceph monitors使用的6789端口和osd使用的6800:7300端口范围。
```
iptables -A INPUT -i {iface} -p tcp -s {ip-address}/{netmask} --dport 6789 -j ACCEPT
```



