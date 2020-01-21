---
title: "Ceph 集群搭建一 之 集群搭建"
date: 2019-03-19T14:57:12+08:00
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


第一次练习时，我们创建一个 Ceph 存储集群，它有一个 Monitor 和两个 OSD 守护进程。一旦集群达到 active + clean 状态，再扩展它：增加第三个 OSD 、增加元数据服务器和两个 Ceph Monitors。为获得最佳体验，先在管理节点上创建一个目录，用于保存 ceph-deploy 生成的配置文件和密钥对。

> 如果你是用另一普通用户登录的，不要用 sudo 或在 root 身份运行 ceph-deploy ，因为它不会在远程主机上调用所需的 sudo 命令。

```
mkdir my-cluster
cd my-cluster
```

> **禁用 requiretty** 
 在某些发行版（如 CentOS ）上，执行 ceph-deploy 命令时，如果你的 Ceph 节点默认设置了 requiretty 那就会遇到报错。可以这样禁用此功能：执行 sudo visudo ，找到 Defaults requiretty 选项，把它改为 Defaults:ceph !requiretty ，这样 ceph-deploy 就能用 ceph 用户登录并使用 sudo 了。

#### 创建集群
如果在某些地方碰到麻烦，想从头再来，可以用下列命令配置：
```
ceph-deploy purgedata {ceph-node} [{ceph-node}]
ceph-deploy forgetkeys
```

用下列命令可以连ceph安装包一起清除：
```
ceph-deploy purge {ceph-node} [{ceph-node}]
```
如果执行了purge，你必须重新安装ceph

##### 开始创建集群
在管理节点上，进入刚创建的放置配置文件的目录，用 ceph-deploy 执行如下步骤。
1. 创建集群
```
ceph-deploy new node1 node2 node3
```

2. 把 Ceph 配置文件里的默认副本数从 3 改成 2 ，这样只有两个 OSD 也可以达到 active + clean 状态。把下面这行加入 [global] 段：
```
osd_pool_default_size = 2
```

3. 如果你有多个网卡，可以把 public network 写入 Ceph 配置文件ceph.conf的 [global] 段下。
```
public_network = {ip-address}/{netmask}
```

4. 安装ceph

```
ceph-deploy install node1 node2 node3
```
5. 配置初始monitor(s)，并收集所有密钥
```
ceph-deploy mon create-initial
```

完成上述操作后，当前目录里应该会出现这些密钥环：
```
{cluster-name}.client.admin.keyring
{cluster-name}.bootstrap-osd.keyring
{cluster-name}.bootstrap-mds.keyring
{cluster-name}.bootstrap-rgw.keyring
```

> 只有在安装 Hammer 或更高版时才会创建 bootstrap-rgw 密钥环。
>  如果此步失败并输出类似于如下信息 “Unable to find /etc/ceph/ceph.client.admin.keyring”，请确认 ceph.conf 中为 monitor 指定的 IP 是 Public IP，而不是 Private IP。


#### 开始创建osd
1. 添加两个osd。为了快速地安装，这篇快速入门把目录而整个硬盘用于osd守护进程。登录到ceph节点、并给osd守护进程创建一个目录。
```
ssh node2
sudo mkdir /var/local/osd0
exit

ssh node3
sudo mkdir /var/local/osd1
exit
```

然后，从管理节点执行ceph-deploy来准备osd。

```
ceph-deploy osd prepare {ceph-node}:/path/to/directory
```

最后，激活osd
```
ceph-deploy osd activate {ceph-node}:/path/to/directory
```

2. 用ceph-deploy把配置文件和admin密钥拷贝到管理节点和ceph节点，这样你每次执行ceph命令行时就无需指定monitor地址和ceph.client.admin.keyring了。
```
ceph-deploy admin {admin-node} {ceph-node}
```
如：
```
ceph-deploy admin admin-node node1 node2 node3
```

ceph-deploy和本地管理主机(admin-node)通信时，必须通过主机名可达。必要时可修改/etc/hosts，加入管理主机的名字。

3. 确保你对ceph.client.admin.keyring有正确的操作权限。
```
chmod +r /etc/ceph/ceph.client.admin.keyring
```

4. 检查集群的健康状况
```
ceph health
```

等peering完成后，集群应该达到active+clean状态


#### 扩容集群
##### 添加osd
你运行的这个三节点集群只是用于演示的，把osd添加到monitor节点就行
```
ssh node1
sudo mkdir /var/local/osd2
exit
```
然后，从ceph-deploy节点准备osd
```
ceph-deploy osd prepare {ceph-node}:/path/to/directory
```
如：
```
ceph-deploy osd prepare node1:/var/local/osd2
```

最后，激活osd
```
ceph-deploy osd activate {ceph-node}:/path/to/directory
```


一旦新增osd，ceph集群会重新均衡，把归置组迁到新osd。可以用下面的ceph命令观察此过程：
```
ceph -w
```





## 问题
#### 安装ceph报错：No section: 'ceph'
版本冲突，移除旧版本
```
yum remove ceph-release
```
然后重新运行安装命令

#### 初始化mon出错
![http://blog.realjf.com/wp-content/uploads/2018/12/ceph-mon-initial-error.png](http://blog.realjf.com/wp-content/uploads/2018/12/ceph-mon-initial-error.png)

主要是报错：admin_socket: exception getting command descriptions: [Errno 2] No such file or directory

**解决方法**

1. 报错信息是“没有文件或者文件夹”。应该是创建的文件夹出错。

2. 切换到对应的 /var/run/ceph/ 目录下，发现确实没有这个文件。

3. 经过调研分析，创立的文件是 “ceph-mon.locahost.asok” , 通过观察admin的节点的ceph 日志发现，其中有一步骤需要获取node1的hostname， 而node1电脑的hostname是localhost. 因此只需要改hostname就可以。

#### 执行ceph-deploy报错
```sh
Traceback (most recent call last):
  File "/bin/ceph-deploy", line 18, in <module>
    from ceph_deploy.cli import main
  File "/usr/lib/python2.7/site-packages/ceph_deploy/cli.py", line 1, in <module>
    import pkg_resources
ImportError: No module named pkg_resources
```
**解决方法**
原因是缺python-setuptools
```sh
yum install python-setuptools
```

#### Some monitors have still not reached quorum
```sh
[ceph_deploy.mon][WARNIN] waiting 5 seconds before retrying
[ceph-node2][INFO  ] Running command: sudo ceph --cluster=ceph --admin-daemon /var/run/ceph/ceph-mon.ceph-node2.asok mon_status
[ceph_deploy.mon][WARNIN] mon.ceph-node2 monitor is not yet in quorum, tries left: 4
[ceph_deploy.mon][WARNIN] waiting 10 seconds before retrying
[ceph-node2][INFO  ] Running command: sudo ceph --cluster=ceph --admin-daemon /var/run/ceph/ceph-mon.ceph-node2.asok mon_status
[ceph_deploy.mon][WARNIN] mon.ceph-node2 monitor is not yet in quorum, tries left: 3
[ceph_deploy.mon][WARNIN] waiting 10 seconds before retrying
[ceph-node2][INFO  ] Running command: sudo ceph --cluster=ceph --admin-daemon /var/run/ceph/ceph-mon.ceph-node2.asok mon_status
[ceph_deploy.mon][WARNIN] mon.ceph-node2 monitor is not yet in quorum, tries left: 2
[ceph_deploy.mon][WARNIN] waiting 15 seconds before retrying
[ceph-node2][INFO  ] Running command: sudo ceph --cluster=ceph --admin-daemon /var/run/ceph/ceph-mon.ceph-node2.asok mon_status
[ceph_deploy.mon][WARNIN] mon.ceph-node2 monitor is not yet in quorum, tries left: 1
[ceph_deploy.mon][WARNIN] waiting 20 seconds before retrying
[ceph_deploy.mon][ERROR ] Some monitors have still not reached quorum:
[ceph_deploy.mon][ERROR ] ceph-node1
[ceph_deploy.mon][ERROR ] ceph-node2
```
**解决方法**

清理重装ceph


