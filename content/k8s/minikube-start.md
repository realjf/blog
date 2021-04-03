---
title: "k8s集群 之一 创建集群 minikube安装使用 Minikube Start"
date: 2021-04-03T13:59:47+08:00
keywords: ["k8s", "minikube"]
categories: ["k8s"]
tags: ["k8s", "minikube"]
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

使用Minikube部署本地k8s集群相对比较简单，非常推荐将其用于本地k8s开发环境，唯一麻烦点的仅仅是网络问题

## 实验环境
- CentOS 7.9.2009
- minikube v1.18
- Docker v1.13.1
- Kubernetes v1.20.2


### 什么是minikube？
Minikube 是一个轻量级的Kubernetes实现，会在本机创建一台虚拟机，并部署一个只包含一个节点的简单集群。 Minikube适用于Linux, Mac OS和Windows系统。Minikube CLI提供了集群的基本引导操作，包括启动、停止、状态和删除。

Minikube的目标是成为本地Kubernetes应用程序开发的最佳工具，并支持所有适合的Kubernetes功能！

### minikube安装
可以参考minikube 安装的网站[minikube安装](https://minikube.sigs.k8s.io/docs/start/)

```sh
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
sudo rpm -ivh minikube-latest.x86_64.rpm
```

minikube二进制下载地址：[https://github.com/kubernetes/minikube/releases](https://github.com/kubernetes/minikube/releases)

### 安装docker
```sh
yum update
yum install docker -y
systemctl enable docker 
systemctl start docker 

# 检查docker版本
docker version

# 添加docker组，将当前用户加入该组（需要在非root用户下执行）
sudo groupadd docker
sudo usermod -aG docker ${USER}
sudo systemctl restart docker
su root # 需要切换下用户，让配置生效
su ${USER}
```

### minikube开始
```sh
minikube start --registry-mirror=https://registry.docker-cn.com --vm-driver="docker" --memory=4096
```
- --registry-mirror参数用于设置镜像服务地址，这里设置为国内镜像服务地址。
- --vm-driver参数设置了虚拟机类型，这里我们使用Docker，默认是VirtualBox。参数–vm-driver=none表示minikube运行在宿主机，不需要提前安装VirtualBox或者KVM
- --memory参数设置了虚拟机内存大小。
- --base-image该参数指定依赖下载国内镜像地址，如：--base-image registry.cn-hangzhou.aliyuncs.com/google_containers/kicbase:v0.0.10
- --image-repository来设置Minikube指定镜像仓库地址。如：--image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers

> 在中国，由于网络和防火墙的原因，通常会无法拉取k8s相关镜像或者下载速度过于缓慢，因此，我们可以通过参数--image-repository来设置Minikube使用阿里云镜像。

```sh
minikube start --registry-mirror=https://registry.docker-cn.com --vm-driver="docker"  --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
```

> 记住，运行上面的命令不应该在root权限下运行
```sh
# 需要添加当前用户到docker group中
sudo usermod -aG docker $USER && newgrp docker
```

成功之后，我们就可以使用kubectl来操作集群了，比如查看当前所有pod的状态

```sh
minikube kubectl get pods -A
minikube kubectl get deployment
minikube kubectl get nodes
minikube kubectl get services
# 查看nodes信息
minikube kubectl describe nodes 
minikube kubectl describe services
```

刚才我们使用Minikube创建了默认的集群，我们还可以使用Minikube创建新的集群，比如：
```sh
minikube start -p mycluster
```

### 打开minikube可视化面板
```sh
minikube dashboard
```

> 安装过程中如出现问题，可以执行以下命令之后再重新尝试：
```sh
minikube delete
rm ~/.minikube
```

