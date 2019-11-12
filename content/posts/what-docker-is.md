---
title: "什么是docker？"
date: 2019-03-19T14:40:53+08:00
keywords: ["docker"]
categories: ["docker"]
tags: ["docker"]
draft: false
---


![https://gss2.bdstatic.com/9fo3dSag_xI4khGkpoWK1HF6hhy/baike/crop%3D0%2C156%2C1354%2C894%3Bc0%3Dbaike180%2C5%2C5%2C180%2C60/sign=c97c7c9b9b13b07ea9f20a4831e7bd12/f703738da977391281957edbf0198618377ae2dd.jpg](https://gss2.bdstatic.com/9fo3dSag_xI4khGkpoWK1HF6hhy/baike/crop%3D0%2C156%2C1354%2C894%3Bc0%3Dbaike180%2C5%2C5%2C180%2C60/sign=c97c7c9b9b13b07ea9f20a4831e7bd12/f703738da977391281957edbf0198618377ae2dd.jpg)

#### 官方定义
```
Develop, Ship and Run Any Application, Anywhere
Docker is a platform for developers and sysadmins to develop, ship, and run applications. Docker lets you quickly assemble applications from components and eliminates the friction that can come when shipping code. Docker lets you get your code tested and deployed into production as fast as possible.
```
Docker 是 PaaS 提供商 dotCloud 开源的一个基于 LXC 的高级容器引擎，源代码托管在 Github 上, 基于go语言并遵从Apache2.0协议开源。

> LXC linux container容器是一种内核虚拟化技术，可以提供轻量级的虚拟化，以便隔离进程和资源。与kvm之类最明显的区别在于启动快，资源占用小。

#### 一个完整的docker有以下几部分
- docker Client客户端

用来向指定的docker daemon发起请求，执行相应的容器管理操作。
- docker daemon守护进程

核心后台进程，负责响应来自docker client的请求，然后翻译成系统调用完成容器操作。
- docker image镜像


- docker container 容器




![https://gss2.bdstatic.com/9fo3dSag_xI4khGkpoWK1HF6hhy/baike/c0%3Dbaike80%2C5%2C5%2C80%2C26/sign=9f1b2701eddde711f3df4ba4c686a57e/a50f4bfbfbedab644936dac4ff36afc379311e69.jpg](https://gss2.bdstatic.com/9fo3dSag_xI4khGkpoWK1HF6hhy/baike/c0%3Dbaike80%2C5%2C5%2C80%2C26/sign=9f1b2701eddde711f3df4ba4c686a57e/a50f4bfbfbedab644936dac4ff36afc379311e69.jpg)


#### docker典型应用场景和应用价值

在docker的网站上提到了docker的典型场景：
- Automating the packaging and deployment of applications（使应用的打包与部署自动化）
- Creation of lightweight, private PAAS environments（创建轻量、私密的PAAS环境）
- Automated testing and continuous integration/deployment（实现自动化测试和持续的集成/部署）
- Deploying and scaling web apps, databases and backend services（部署与扩展webapp、数据库和后台服务）



#### 特性
- 持续的集成和交付
- 因为LXC轻量级的特点，其启动快，而且docker能够只加载每个container变化的部分，这样资源占用小，能够在单机环境下与KVM之类的虚拟化方案相比能够更加快速和占用更少资源




#### 局限性

- docker无法再32bit的linux/windows/unix环境下运行
- LXC是基于cgroup等linux内核功能的，因此container的guest系统只能是linux base的
- 隔离性相比kvm有所欠缺，所有container共用一部分运行库
- 网络隔离基于namespace隔离
- cgroup的cpu和cpuset提供的cpu相比kvm等虚拟化方案比较难以衡量
- docker对disk的管理比较有限
- container随着用户进程的停止而销毁，container中的log等用户数据不变收集
- 上面几个决定了docker不适用与IaaS。




