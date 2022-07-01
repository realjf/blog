---
title: "K8s Build and Deploy a Basic Operator"
date: 2022-07-01T15:00:11+08:00
keywords: ["k8s", "operator"]
categories: ["k8s"]
tags: ["k8s"]
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

## 准备
- linux系统
- go开发环境
- operator sdk 包括：
  - operator-sdk 命令行界面（CLI）工具和SDK方便了算子的开发。
  - operator lifecycle manager 这有助于集群内操作员的安装、升级和基于角色的访问控制 (RBAC)
- kubernetes 集群，可以使用minikube之类的工具在本地安装一个单机集群
- 镜像仓库

### golang开发环境安装
[golang下载](https://go.dev/dl/)

### kubernetes集群安装
你需要的配置
- 2核以上cpu
- 2GB以上内存
- 20GB以上的磁盘空间
- docker

#### 下载安装
```sh
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```
#### 运行集群
```sh
minikube start
```

参考[minikube安装](https://minikube.sigs.k8s.io/docs/start/)

### operator sdk 安装
```golang
git clone https://github.com/operator-framework/operator-sdk
cd operator-sdk
git checkout master
make install
```
可以参考[operator sdk安装](https://sdk.operatorframework.io/docs/installation/)
### 构建kubernetes operator
#### 生成样板代码
首先，运行minikube start运行本地集群
```sh
mkdir -p $GOPATH/src/operators && cd $GOPATH/src/operators
minikube start init
```
然后运行operator-sdk init生成我们示例应用的样板代码
```sh
operator-sdk init
```
#### 创建API和自定义资源
在 Kubernetes 中，为您要提供的每个服务公开的功能都组合在一个资源中。因此，当我们为应用程序创建 API 时，我们还通过 CustomResourceDefinition (CRD) 创建它们的资源。
以下命令创建一个 API 并通过 --kind 选项将其标记为 Traveler。在该命令创建的 YAML 配置文件中，您可以找到一个标签为 kind 的字段，其值为 Traveller。
该字段表示在整个开发过程中使用 Traveler 来引用我们的 API：
```sh

```