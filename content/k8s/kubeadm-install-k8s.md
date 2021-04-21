---
title: "使用kubeadm工具安装 kubernetes Use Kubeadm Install K8s"
date: 2021-04-20T10:07:28+08:00
keywords: ["k8s", "kubeadm"]
categories: ["k8s"]
tags: ["k8s", "kubeadm"]
series: [""]
draft: false
toc: false
related:
  threshold: 50
  includeNewer: true
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

### 环境准备
- centos-7 x86_64 2009
- vmware 16 虚拟机 
- kubernetes: v1.21.0
- docker-ce: 20.10.5
- cpu最少：4核
- 内存最少：4GB
- swap：禁用
- 最小磁盘：100GB

请先在vmware虚拟机中安装好centos7,并且关闭防火墙和selinux

```sh
# 关闭防火墙
sed -ri 's#(SELINUX=).*#\1disabled#' /etc/selinux/config
setenforce 0
systemctl disable firewalld
systemctl stop firewalld

# 禁用swap
# 注释/etc/fstab关于swap的配置
# 然后执行如下命令
echo vm.swappiness=0 >> /etc/sysctl.conf 
# 重启
reboot
# 查看是否禁用
free -m
# 如果swap全部是0表示成功
```
docker-ce安装
```sh
# 安装yum源
yum install -y wget && wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
# 安装docker
yum install docker-ce
# 设置开机自启
systemctl enable docker && systemctl start docker
docker version
```


### 第一步：安装kubeadm和相关工具
官网yum源：https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64。
如果无法访问，可以使用国内阿里云的yum源，地址是：http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
，具体的yum配置文件/etc/yum.repos.d/kubernetes.repo内容如下：
```sh
[kubernetes]
name=Kubernetes Repository
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
```
然后运行安装kubeadm命令：
```sh
yum install -y kubelet kubeadm --disableexcludes=kubernetes
```
本次实验安装的版本分别如下：

- kubeadm 1.21.0
- kubelet 1.21.0
- kubectl 1.21.0
- kubernetes-cni 0.8.7 

然后在启动docker服务和kubelet服务
```sh
systemctl enable docker && systemctl start docker
systemctl enable kubelet && systemctl start kubelet
```

#### kubeadm config配置
kubeadm config子命令解释
```sh
kubeadm config upload from-file # 由配置文件上传到集群中生成ConfigMap
kubeadm config upload from-flags # 由配置参数生成ConfigMap
kubeadm config view # 查看当前集群中的配置值
kubeadm config print init-defaults # 输出kubeadm init默认参数文件的内容
kubeadm config print join-defaults # 输出kubeadm join默认参数文件的内容
kubeadm config migrate # 在新旧版本之间进行配置转换
kubeadm config images list # 列出所需的镜像列表
kubeadm config images pull # 拉取镜像到本地
```
可以执行kubeadm config print init-defaults取得默认的初始化参数文件：
```sh
kubeadm config print init-defaults > init.default.yaml
```
对生成的文件进行编辑，可以按需生成合适的配置。如，若需要定制镜像仓库的地址，以及pod的地址范围，可以使用如下配置：
```yaml
...
kind: InitConfiguration
localAPIEndpoint:
  # 修改ip地址为本机ip地址
  advertiseAddress: 192.168.37.150
  bindPort: 6443
...
apiVersion: kubeadm.k8s.io/v1beta2
imageRepository: registry.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: 1.21.0
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12
  # 新增pod地址范围
  podSubnet: "192.168.0.0/16"
scheduler: {}
```
这里使用国内阿里云的镜像，
将上面的内容保存为init-config.yaml备用


#### 下载kubernetes的相关镜像
为了从国内的镜像托管站点获得镜像加速支持，建议修改docker的配置文件，增加Registry Mirror参数，
将镜像配置写入配置参数中，例如：
```sh
echo '{"registry-mirrors":["https://registry.docker-cn.com"]}' > /etc/docker/daemon.json
# 然后重启docker服务
```
使用config images pull 子命令下载所需的镜像，如：
```sh
kubeadm config images pull --config=init-config.yaml
```

拉取到最后报错：
```sh
failed to pull image "registry.aliyuncs.com/google_containers/coredns/coredns:v1.8.0": output: Error response from daemon: manifest for registry.aliyuncs.com/google_containers/coredns/coredns:v1.8.0 not found: manifest unknown: manifest unknown
```
解决方法是直接使用docker拉取，然后打tag
```sh
# 先拉取官方镜像
docker pull coredns/coredns:1.8.0
# 然后打上tag
docker tag docker.io/coredns/coredns:1.8.0 registry.aliyuncs.com/google_containers/coredns/coredns:v1.8.0
```
使用kubeadm config images list --config=init-config.yaml可以查看需要的镜像文件
```sh
registry.aliyuncs.com/google_containers/kube-apiserver:v1.21.0
registry.aliyuncs.com/google_containers/kube-controller-manager:v1.21.0
registry.aliyuncs.com/google_containers/kube-scheduler:v1.21.0
registry.aliyuncs.com/google_containers/kube-proxy:v1.21.0
registry.aliyuncs.com/google_containers/pause:3.4.1
registry.aliyuncs.com/google_containers/etcd:3.4.13-0
registry.aliyuncs.com/google_containers/coredns/coredns:v1.8.0
```
然后使用docker images可以查看本地的镜像是否包含了上面所有的镜像
```sh
REPOSITORY                                                        TAG          IMAGE ID       CREATED        SIZE
registry.cn-hangzhou.aliyuncs.com/google_containers/kicbase       v0.0.20      c6f4fc187bc1   10 days ago    1.09GB
registry.aliyuncs.com/google_containers/kube-apiserver            v1.21.0      4d217480042e   11 days ago    126MB
registry.aliyuncs.com/google_containers/kube-proxy                v1.21.0      38ddd85fe90e   11 days ago    122MB
registry.aliyuncs.com/google_containers/kube-controller-manager   v1.21.0      09708983cc37   11 days ago    120MB
registry.aliyuncs.com/google_containers/kube-scheduler            v1.21.0      62ad3129eca8   11 days ago    50.6MB
vesoft/nebula-graphd                                              v2-nightly   ed51f7efd7ee   3 weeks ago    292MB
vesoft/nebula-storaged                                            v2-nightly   efdfb1a1cd3d   3 weeks ago    296MB
vesoft/nebula-metad                                               v2-nightly   bdc1edaa036c   3 weeks ago    296MB
vesoft/nebula-console                                             v2-nightly   ff7f72b06a10   3 weeks ago    14.5MB
hello-world                                                       latest       d1165f221234   6 weeks ago    13.3kB
registry.aliyuncs.com/google_containers/pause                     3.4.1        0f8457a4c2ec   3 months ago   683kB
coredns/coredns                                                   1.8.0        296a6d5035e2   5 months ago   42.5MB
registry.aliyuncs.com/google_containers/coredns/coredns           v1.8.0       296a6d5035e2   5 months ago   42.5MB
registry.aliyuncs.com/google_containers/etcd                      3.4.13-0     0369cf4303ff   7 months ago   253MB
```
如果镜像都有，则可以进行下一步

#### 运行kubeadm init命令安装master节点
执行kubeadm init命令可以一键安装kubernetes到master节点

如果需要制定参数，如：安装calico插件时需要指定--pod-network-cidr=192.168.0.0/16。

接下来使用前面创建的配置文件进行集群控制面的初始化
```sh
kubeadm init --config=init-config.yaml
```

运行前，需要禁用swap分区，可以运行如下命令禁用：
```sh
# 注释/etc/fstab关于swap的配置
# 然后执行如下命令
echo vm.swappiness=0 >> /etc/sysctl.conf 
# 重启
reboot
# 查看是否禁用
free -m
# 如果swap全部是0表示成功
```

运行kubeadm init报错如下，没有可以跳过这步：
```sh
[init] Using Kubernetes version: v1.21.0
[preflight] Running pre-flight checks
	[WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
	[WARNING Hostname]: hostname "node" could not be reached
	[WARNING Hostname]: hostname "node": lookup node on 192.168.37.2:53: no such host
error execution phase preflight: [preflight] Some fatal errors occurred:
	[ERROR Port-10259]: Port 10259 is in use
	[ERROR Port-10257]: Port 10257 is in use
	[ERROR FileAvailable--etc-kubernetes-manifests-kube-apiserver.yaml]: /etc/kubernetes/manifests/kube-apiserver.yaml already exists
	[ERROR FileAvailable--etc-kubernetes-manifests-kube-controller-manager.yaml]: /etc/kubernetes/manifests/kube-controller-manager.yaml already exists
	[ERROR FileAvailable--etc-kubernetes-manifests-kube-scheduler.yaml]: /etc/kubernetes/manifests/kube-scheduler.yaml already exists
	[ERROR FileAvailable--etc-kubernetes-manifests-etcd.yaml]: /etc/kubernetes/manifests/etcd.yaml already exists
	[ERROR Port-10250]: Port 10250 is in use
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
To see the stack trace of this error execute with --v=5 or higher
```
提示端口被使用，初始化失败时，可以重启一下kubeadm：
```sh
# 初始化失败时，可以重启下
kubeadm reset
```

运行kubeadm init卡住并报错，没有可以跳过这步：
```sh
...
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[kubelet-check] Initial timeout of 40s passed.

	Unfortunately, an error has occurred:
		timed out waiting for the condition

	This error is likely caused by:
		- The kubelet is not running
		- The kubelet is unhealthy due to a misconfiguration of the node in some way (required cgroups disabled)

	If you are on a systemd-powered system, you can try to troubleshoot the error with the following commands:
		- 'systemctl status kubelet'
		- 'journalctl -xeu kubelet'

	Additionally, a control plane component may have crashed or exited when started by the container runtime.
	To troubleshoot, list all containers using your preferred container runtimes CLI.

	Here is one example how you may list all Kubernetes containers running in docker:
		- 'docker ps -a | grep kube | grep -v pause'
		Once you have found the failing container, you can inspect its logs with:
		- 'docker logs CONTAINERID'

error execution phase wait-control-plane: couldn't initialize a Kubernetes cluster
To see the stack trace of this error execute with --v=5 or higher
```
检查配置，发现配置文件中的advertiseAddress为1.2.3.4，需要修改下：
```yaml
kind: InitConfiguration
localAPIEndpoint:
  # 修改ip地址为本机ip地址
  advertiseAddress: 192.168.37.150
  bindPort: 6443
```
然后重启下kubeadm reset，之后重新初始化kubeadm init --config=init-config.yaml，结果如下：
```sh
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.37.150:6443 --token abcdef.0123456789abcdef \
	--discovery-token-ca-cert-hash sha256:b90b7155024b10d3ff27d91bba2f3caef6fff492f866728b01514ee1ae9bb349
```
看到上述结果表示初始化成功

根据提示，需要用普通用户执行如下操作，复制配置文件到home目录
```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

这样就成功安装了kubernetes的master节点。但是目前集群内没有可用的node节点，并缺少对容器网络的配置。

提示最后几行信息，其中包含了加入节点指令（kubeadm join）和所需的token
```sh
kubeadm join 192.168.37.150:6443 --token abcdef.0123456789abcdef \
	--discovery-token-ca-cert-hash sha256:b90b7155024b10d3ff27d91bba2f3caef6fff492f866728b01514ee1ae9bb349
```
如果你没有token信息，可以执行如下命令获取：
```sh
kubeadm token list

TOKEN                     TTL         EXPIRES                     USAGES                   DESCRIPTION                                                EXTRA GROUPS
abcdef.0123456789abcdef   3h          2021-04-21T12:50:13+08:00   authentication,signing   <none>                                                     system:bootstrappers:kubeadm:default-node-token

```


此时，可以用kubectl命令验证前面提到的ConfigMap：
```sh
kubectl get -n kube-system configmap
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS      MESSAGE                                                                                       ERROR
scheduler            Unhealthy   Get "http://127.0.0.1:10251/healthz": dial tcp 127.0.0.1:10251: connect: connection refused   
controller-manager   Unhealthy   Get "http://127.0.0.1:10252/healthz": dial tcp 127.0.0.1:10252: connect: connection refused   
etcd-0               Healthy     {"health":"true"}                                                                             
[neyo@bogon ~]$ kubectl get -n kube-system configmap
NAME                                 DATA   AGE
coredns                              1      11m
extension-apiserver-authentication   6      11m
kube-proxy                           2      11m
kube-root-ca.crt                     1      11m
kubeadm-config                       2      11m
kubelet-config-1.21                  1      11m
```
#### 安装node节点，加入集群
在新节点，系统准备和kubernetes yum源的配置过程和master节点一致，在node节点上执行如下安装命令：
yum源
```sh
[kubernetes]
name=Kubernetes Repository
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
```
安装kubeadm、kubelet
```sh
yum install kubelet kubeadm --disableexcludes=kubernetes
```
然后运行如下命令启动docker和kubelet服务，并设置开机自启
```sh
systemctl enable docker && systemctl start docker
systemctl enable kubelet && systemctl start kubelet
```
为kubeadm命令生成配置文件，创建文件join-config.yaml，内容如下：
```yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: 192.168.37.150:6443
    token: abcdef.0123456789abcdef
    unsafeSkipCAVerification: true
  tlsBootstrapToken: abcdef.0123456789abcdef
```
其中，apiServerEndpoint的值来自master服务器的地址，token和tlsBootstrapToken的值就是kubeadm init成功后最后一行提示信息里的token。

执行kubeadm join命令，将本节点加入集群：
```sh
kubeadm join --config=join-config.yaml
```

master节点上的kubelet，默认不参与工作负载，如果希望安装一个单机all-in-one的kubernetes环境，
则可以执行下面的命令（删除node的Label"node-role.kubernetes.io/master"），
让master节点成为一个Node,
```sh
kubectl taint nodes --all node-role.kubernetes.io/master-
```

#### 安装网络插件
执行kubectl get nodes命令，会发现kubernetes提示master为notReady状态，这是因为还没有安装CNI网络插件：
```sh
kubectl get nodes
NAME   STATUS     ROLES                  AGE   VERSION
node   NotReady   control-plane,master   24m   v1.21.0
```
下面根据提示安装CNI网络插件，对于CNI网络插件，有很多选择，可以参考[https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#pod-network](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#pod-network)说明。

```sh
kubectl apply -f <add-on.yaml>
```
例如：目前最流行的Kubernetes网络插件有Flannel、Calico、Canal、Weave这里选择使用flannel，部署网络插件flannel
```sh
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

Warning: policy/v1beta1 PodSecurityPolicy is deprecated in v1.21+, unavailable in v1.25+
podsecuritypolicy.policy/psp.flannel.unprivileged created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.apps/kube-flannel-ds created
```
然后运行kubectl get nodes查看pod状态
```sh
kubectl get nodes

NAME    STATUS   ROLES                  AGE    VERSION
bogon   Ready    <none>                 2m6s   v1.21.0
node    Ready    control-plane,master   21h    v1.21.0
```
可以看到状态已经变为Ready了。

#### 验证集群是否安装完成
执行如下命令，查看相关pod是否都正常创建并运行：
```sh
kubectl get pods --all-namespaces
```
如果有状态错误的pod，可以执行kubectl --namespace=kube-system describe pod<pod_name>查看错误原因。

记得，如果安装失败，则可以执行kubeadm reset命令将主机恢复原状，重新执行kubeadm init命令，再次进行安装。

#### 测试集群是否可用
创建一个pod容器，验证是否正常运行
```sh
# 创建一个nginx容器
kubectl create deployment nginx --image=nginx
# 暴露对外端口
kubectl expose deployment nginx --port=80 --type=NodePort
# 查看nginx是否正常运行
kubectl get pod,svc

NAME                         READY   STATUS              RESTARTS   AGE
pod/nginx-6799fc88d8-phqfk   0/1     ContainerCreating   0          17s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP        21h
service/nginx        NodePort    10.108.143.57   <none>        80:32711/TCP   7s

# 查看 nginx容器运行状态，如果为Running，则表示可以访问
kubectl get pods

NAME                     READY   STATUS    RESTARTS   AGE
nginx-6799fc88d8-phqfk   1/1     Running   0          2m5s
# 在浏览器中访问 192.168.37.151:32711 即可访问nginx服务
# 扩容nginx副本到3个
kubectl scale deployment nginx --replicas=3
kubectl get pods
```

#### 部署dashboard
略

### kubeadm升级集群

首先要升级的是kubeadm
```sh
yum install -y kubeadm-1.22.0 --disableexcludes=kubernetes

kubeadm version
```
接下来查看kubeadm的升级计划
```sh
kubeadm upgrade plan
```
按照任务指引进行升级
```sh
kubeadm upgrade apply 1.22.0
```
输入y确认后，开始进行升级，运行完成之后，再次查看版本
```sh
kubectl version
```
查看node版本，发现node版本滞后，对node节点配置进行升级
```sh
kubeadm upgrade node config --kubelet-version 1.22.0
```


**参考文献**

- [https://blog.csdn.net/xtjatswc/article/details/109234575](https://blog.csdn.net/xtjatswc/article/details/109234575)
- [https://www.cnblogs.com/cptao/p/10912644.html](https://www.cnblogs.com/cptao/p/10912644.html)