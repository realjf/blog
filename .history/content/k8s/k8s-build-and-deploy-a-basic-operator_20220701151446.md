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



### operator sdk 安装
```golang
git clone https://github.com/operator-framework/operator-sdk
cd operator-sdk
git checkout master
make install
```

### 创建