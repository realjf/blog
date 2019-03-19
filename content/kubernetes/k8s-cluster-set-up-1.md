---
title: "Kubernetes集群搭建一 之 etcd集群"
date: 2019-03-19T14:13:46+08:00
draft: false
---

#### 系统要求

软硬件 | 最低配置 | 推荐配置
---|--- | ---
cpu和内存 | master:至少2core和4GB内存 Node：至少4core和16GB|Master:4core和16GB Node: 应根据需要运行的容器数量进行配置
linux操作系统 | 基于x86_64架构的各种linux发行版本 | Red Hat Linux 7 CentOS 7
Docker | 1.9版本以上|1.12版本
etcd | 2.0版本及以上 | 3.0版本

本次实验选用的是centos7 1804版本
    
> 需要注意，kubernetes的master和node节点之间会有大量的网络通信，安全的做法是在防火墙上配置各组件需要相互通信的端口号。在一个安全的内网环境中，可以关闭防火墙服务
```sh
#关闭防火墙
systemctl disable firewalld
systemctl stop firewalld
# 禁用SELinux
setenforce 0
# 也可以修改/etc/sysconfig/selinux，将SELINUX=enforcing修改成SELINUX=disabled
```

#### 这里将搭建一个master节点和一个node节点的k8s集群
> 由于 raft 算法的特性，集群的节点数必须是奇数

- | ip | etcd节点名称 
---|---|---
master节点| 192.168.37.150 | etcd1
node1节点 | 192.168.37.152 | etcd2

> 请确保节点直接可以互相ping通

#### 1. 安装docker
- docker版本为1.13.1
```sh
yum install docker -y

# 由于后面都采用服务方式启动，所以docker启动参数需要加上--exec-opt native.cgroupdriver=systemd
vim /usr/lib/systemd/system/docker.service
# 在启动项上加上这行就可以
systemctl start docker
```

##### 创建安装目录
```sh
mkdir -p /opt/kubernetes/bin
```

#### 2.安装etcd
下载地址：[https://github.com/coreos/etcd/releases/](https://github.com/coreos/etcd/releases/)
```sh
wget https://github.com/coreos/etcd/releases/download/v3.3.5/etcd-v3.3.5-linux-amd64.tar.gz
tar zxvf etcd-v3.3.5-linux-amd64.tar.gz

# 复制etcd和etcdctl到/usr/bin
cd etcd-v3.3.5-linux-amd64
cp etcd /usr/bin/
cp etcdctl /usr/bin/
```
##### 配置节点1
创建工作目录
```
mkdir /var/lib/etcd/etcd1 -p
```
设置systemd服务文件/usr/lib/systemd/system/etcd.service
```
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/etcd1
EnvironmentFile=-/etc/etcd/etcd.conf
ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/bin/etcd \
  --name ${ETCD_NAME} \
  --initial-advertise-peer-urls ${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
  --listen-peer-urls ${ETCD_LISTEN_PEER_URLS} \
  --listen-client-urls ${ETCD_LISTEN_CLIENT_URLS} \
  --advertise-client-urls ${ETCD_ADVERTISE_CLIENT_URLS} \
  --initial-cluster-token ${ETCD_INITIAL_CLUSTER_TOKEN} \
  --initial-cluster ${ETCD_INITIAL_CLUSTER} \
  --initial-cluster-state ${ETCD_INITIAL_CLUSTER_STATE} \
  --data-dir=${ETCD_DATA_DIR}"
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

```
- WorkingDirectory表示etcd数据保存的目录，需要在启动etcd服务之前创建
- /etc/etcd/etcd.conf通常不需要特别设置（详见官方文档），etcd默认监听在：http://127.0.0.1:2379供客户端连接


创建配置文件etcd.conf
```
# [member]
ETCD_NAME=etcd1
ETCD_DATA_DIR="/var/lib/etcd/etcd1"
ETCD_LISTEN_PEER_URLS="http://192.168.37.150:2380"
ETCD_LISTEN_CLIENT_URLS="http://192.168.37.150:2379,http://127.0.0.1:2379"

#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.37.150:2380"
ETCD_INITIAL_CLUSTER="etcd1=http://192.168.37.150:2380,etcd2=http://192.168.37.152:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.37.150:2379"

```
- name
etcd集群中的节点名，这里可以随意，可区分且不重复就行  
- listen-peer-urls
监听的用于节点之间通信的url，可监听多个，集群内部将通过这些url进行数据交互(如选举，数据同步等)
- initial-advertise-peer-urls 
建议用于节点之间通信的url，节点间将以该值进行通信。
- listen-client-urls
监听的用于客户端通信的url,同样可以监听多个。
- advertise-client-urls
建议使用的客户端通信url,该值用于etcd代理或etcd成员与etcd节点通信。
- initial-cluster-token etcd-cluster-1
节点的token值，设置该值后集群将生成唯一id,并为每个节点也生成唯一id,当使用相同配置文件再启动一个集群时，只要该token值不一样，etcd集群就不会相互影响。
- initial-cluster
也就是集群中所有的initial-advertise-peer-urls 的合集
- initial-cluster-state new
新建集群的标志


##### 配置节点2
创建工作目录
```
mkdir /var/lib/etcd/etcd2 -p
```
设置systemd服务文件/usr/lib/systemd/system/etcd.service
```
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/etcd2
EnvironmentFile=-/etc/etcd/etcd.conf
ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/bin/etcd \
  --name ${ETCD_NAME} \
  --initial-advertise-peer-urls ${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
  --listen-peer-urls ${ETCD_LISTEN_PEER_URLS} \
  --listen-client-urls ${ETCD_LISTEN_CLIENT_URLS} \
  --advertise-client-urls ${ETCD_ADVERTISE_CLIENT_URLS} \
  --initial-cluster-token ${ETCD_INITIAL_CLUSTER_TOKEN} \
  --initial-cluster ${ETCD_INITIAL_CLUSTER} \
  --initial-cluster-state ${ETCD_INITIAL_CLUSTER_STATE} \
  --data-dir=${ETCD_DATA_DIR}"
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

创建配置文件etcd.conf
```
# [member]
ETCD_NAME=etcd2
ETCD_DATA_DIR="/var/lib/etcd/etcd2"
ETCD_LISTEN_PEER_URLS="http://192.168.37.152:2380"
ETCD_LISTEN_CLIENT_URLS="http://192.168.37.152:2379,http://127.0.0.1:2379"

#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.37.152:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER="etcd1=http://192.168.37.150:2380,etcd2=http://192.168.37.152:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.37.152:2379"

```


##### 节点配置完毕后，在各节点上运行以下命令，开启etcd服务即可

```
# 将服务加入开机启动列表
systemctl daemon-reload
systemctl enable etcd.service
systemctl start etcd.service
```
##### 最后检查集群是否启动
```
# 通过执行etcdctl cluster-health，可以验证etcd是否正确启动
etcdctl cluster-health

# 运行结果如下：
member 454b8832d6d4269d is healthy: got healthy result from http://192.168.37.150:2379
member 60024e9df3f177a4 is healthy: got healthy result from http://192.168.37.152:2379
cluster is healthy
```

##### 遇到的问题
问题1：配置好启动后报错：Failed at step CHDIR spawning /bin/bash: No such file or directory
```
# 1. 先检查配置，如有问题及时修改，如还是报错
# 2. 可能是没有创建工作目录，创建工作目录即可
mkdir -p /var/lib/etcd/etcd1
```
到此，etcd集群搭建完毕，接下来在节点上安装k8s


#### 3. 安装kubernetes
#### master节点配置
- 官网下载地址：[https://kubernetes.io/docs/imported/release/notes/#downloads-for-v1-10-0](https://kubernetes.io/docs/imported/release/notes/#downloads-for-v1-10-0)
- github下载地址：[https://github.com/kubernetes/kubernetes/releases](https://github.com/kubernetes/kubernetes/releases)
- github二进制包下载地址：[https://dl.k8s.io/v1.10.3/kubernetes-server-linux-amd64.tar.gz](https://dl.k8s.io/v1.10.3/kubernetes-server-linux-amd64.tar.gz)
```sh
wget https://dl.k8s.io/v1.10.3/kubernetes-server-linux-amd64.tar.gz
tar zxvf kubernetes-server-linux-amd64.tar.gz
cd kubernetes-server-linux-amd64/server/bin
cp kube-apiserver /usr/bin/
cp kube-controller-manager /usr/bin/
cp kube-scheduler /usr/bin/

# 如果复制到其他目录，则相应的将systemd服务文件中的文件路径修改正确即可
```
##### kube-apiserver服务安装
编辑systemd服务文件/usr/lib/systemd/system/kube-apiserver.service，内容如下：
```
[Uint]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=etcd.service
Wants=etcd.service

[Service]
EnvironmentFile=/etc/kubernetes/apiserver
ExecStart=/usr/bin/kube-apiserver $KUBE_API_ARGS
Restart=on-failure
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

```
配置文件/etc/kubernetes/apiserver的内容包含了kube-apiserver的全部启动参数，主要的配置参数变量KUBE_API_ARGS中指定。
具体内容如下：
```
###
# kubernetes system config
#
# The following values are used to configure the kube-apiserver
#

# The address on the local server to listen to.
#aipServer的监听地址，默认为127.0.0.1，若要配置集群，则要设置为0.0.0.0才能被其他主机找到
KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"

#apiserver的监听端口
# The port on the local server to listen on.
KUBE_API_PORT="--port=8080"

# kubelet的监听端口，若只作为Master节点则可以不配置
# Port minions listen on
KUBELET_PORT="--kubelet-port=10250"

#etcd的地址，若etcd是集群，则配置集群所有地址，用逗号隔开
# Comma separated list of nodes in the etcd cluster
KUBE_ETCD_SERVERS="--etcd-servers=http://demo.etcd.server:2379"

# service的地址范围，用于创建service的时候自动生成或指定serviceIP使用
# Address range to use for services
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"

#使用的系统组件，具体组件的作用参考下文以及官网
# default admission control policies
KUBE_ADMISSION_CONTROL="--admission_control=NamespaceLifecycle,NamespaceExists,NamespaceAutoProvision,LimitRanger,ResourceQuota"

#此处可以添加其他配置，具体配置待笔者完善
# Add your own!
KUBE_API_ARGS="--storage-backend=etcd3 --etcd-servers=http://127.0.0.1:2379 --insecure-bind-address=0.0.0.0 --insecure-port=8080 --service-cluster-ip-range=169.169.0.0/16 --service-node-port-range=1-65535 --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,ResourceQuota,DefaultTolerationSeconds --logtostderr=false --log-dir=/var/log/kubernetes --v=2"
```

###### 这里有个准入控制推荐可供参考
```sh
# 对于 Kubernetes >= 1.6.0 版本，我们强烈建议运行以下一系列准入控制插件（顺序也很重要）

--admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,ResourceQuota,DefaultTolerationSeconds

# 对于 Kubernetes >= 1.4.0 版本，我们强烈建议运行以下一系列准入控制插件（顺序也很重要）

--admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota

# 对于 Kubernetes >= 1.2.0 版本，我们强烈建议运行以下一系列准入控制插件（顺序也很重要）

--admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota

# 对于 Kubernetes >= 1.0.0 版本，我们强烈建议运行以下一系列准入控制插件（顺序也很重要）

--admission-control=NamespaceLifecycle,LimitRanger,SecurityContextDeny,ServiceAccount,PersistentVolumeLabel,ResourceQuota
```


##### kube-controller-manager服务
kube-controller-manager服务依赖于kube-apiserver服务：
```
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/googleCloudPlatform/kubernetes
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
EnvironmentFile=/etc/kubernetes/controller-manager
ExecStart=/usr/bin/kube-controller-manager $KUBE_CONTROLLER_MANAGER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

```

配置文件etc/kubernets/controller-manager
```
###
# kubernetes system config
#
# The following values are used to configure various aspects of all
# kubernetes services, including
#
#   kube-apiserver.service
#   kube-controller-manager.service
#   kube-scheduler.service
#   kubelet.service
#   kube-proxy.service
#日志默认存储方式，默认存储在系统的journal服务中
# logging to stderr means we get it in the systemd journal
KUBE_LOGTOSTDERR="--logtostderr=true"

#日志等级
# journal message level, 0 is debug
KUBE_LOG_LEVEL="--v=0"

#
# Should this cluster be allowed to run privileged docker containers
KUBE_ALLOW_PRIV="--allow-privileged=false"

#kubernetes Master 的apiserver地址和端口
# How the controller-manager, scheduler, and proxy find the apiserver
KUBE_MASTER="--master=http://192.168.37.150:8080"

#etcd地址
KUBE_ETCD_SERVERS="--etcd_servers=http://demo.etcd.server:2379"

KUBE_CONTROLLER_MANAGER_ARGS="--master=http://192.168.37.150:8080 --logtostderr=false --log-dir=/var/log/kubernetes --v=2"
```

##### kube-scheduler服务
```
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/googleCloudPlatform/kubernetes
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
EnvironmentFile=/etc/kubernetes/scheduler
ExecStart=/usr/bin/kube-scheduler $KUBE_SCHEDULER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

配置文件/etc/kubernetes/scheduler
```
KUBE_SCHEDULER_ARGS="--master=http://192.168.37.150:8080 --logtostderr=false --log-dir=/var/log/kubernetes --v=2"
```

#### node节点配置
##### kubelet服务
```
# 创建工作目录
mkdir /var/lib/kubelet
```

启动服务文件/usr/lib/systemd/system/kubelet.service
```
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/googleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/var/lib/kubelet
EnvironmentFile=/etc/kubernetes/kubelet
ExecStart=/usr/bin/kubelet $KUBELET_ARGS
Restart=on-failure


[Install]
WantedBy=multi-user.target
```

配置文件
```
KUBELET_ARGS="--kubeconfig=/var/lib/kubelet/kubeconfig --hostname-override=192.168.37.152 --fail-swap-on=false  --cgroup-driver=systemd --logtostderr=false --log-dir=/var/log/kubernetes --v=2"
```

> 如果设置了 --hostname-override 选项，则 kube-proxy 也需要设置该选项，否则会出现找不到 Node 的情况；

**注意**： 1.10版本的--api-servers已经被--kubeconfig标签替代，具体的配置请参照本章的 2. kubernetes 集群安全设置

> 注意，一定要用--fail-swap-on=false标记关闭swap on

由于docker采用systemd启动，所以需要再加上--cgroup-driver=systemd标记才能正常启动，如果不加上，可能出现如下报错：
```sh
failed to run Kubelet: failed to create kubelet: misconfiguration: kubelet cgroup driver: "cgroupfs" is different from docker cgroup driver: "systemd"
```

##### kube-proxy服务
```
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/googleCloudPlatform/kubernetes
After=network.service
Requires=network.service

[Service]
EnvironmentFile=/etc/kubernetes/proxy
ExecStart=/usr/bin/kube-proxy $KUBE_PROXY_ARGS
Restart=on-failure
LimitNOFILE=65536


[Install]
WantedBy=multi-user.target
```

配置文件
```
KUBE_PROXY_ARGS="--master=http://192.168.37.150:8080 --hostname-override=192.168.37.152 --logtostderr=false --log-dir=/var/log/kubernetes --v=2"
```


##### 遇到的问题
运行kubectl get nodes报错：The connection to the server localhost:8080 was refused - did you specify the right host or port?
```
检查配置文件，或者运行
kubectl --server=192.168.37.150:8080 get nodes
```






