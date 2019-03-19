---
title: "Ceph 集群搭建一 之 准备"
date: 2019-03-19T14:57:05+08:00
draft: false
---


#### 1. 配置ceph yum源
```sh
vim /etc/yum.repos.d/ceph.repo
[ceph-noarch]
name=Cephnoarch packages
baseurl=http://ceph.com/rpm-{ceph-release}/{distro}/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc

```
ceph release [http://docs.ceph.com/docs/master/releases/](http://docs.ceph.com/docs/master/releases/)

#### 2. 更新源并且安装hosts文件
```sh
yum update && yum install ceph-deploy -y
```

#### 3. 配置各节点hosts文件
cat /etc/hosts
```sh
192.168.1.2 node1
192.168.1.3 node2
192.168.1.4 node3
```
#### 4. 配置各节点ssh无密码登录，通过ssh方式连接各节点服务器，以安装部署集群。输入ssh-keygen命令，在命令行输入以下内容：
```sh
ssh-keygen

```

#### 5. 拷贝key到各节点
```sh
ssh-copy-id node1
ssh-copy-id node2
ssh-copy-id node3
```

#### 6. 在执行ceph-deploy的过程中会发生一些配置文件，建议创建一个目录
```sh
mkdir my-cluster
cd my-cluster
```

#### 7. 创建集群，部署新的monitor节点
```sh
ceph-deploy new {initial-monitor-node(s)}
#例如
ceph-deploy new node1

```

#### 8. 配置ceph.conf配置文件
```sh
filestore_xattr_use_omap = true
<!---- 以上部分都是ceph-deploy默认生成的 --->
public network = {ip-address}/{netmask}
cluster network = {ip-address}/{netmask}
<!--- 以上两个网络 --->
```

