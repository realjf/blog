---
title: "kubernetes 核心原理之 网络模型"
date: 2019-03-19T14:30:13+08:00
draft: false
---

主要解决以下问题：
- 容器与容器之间的直接通信
- pod与pod之间的通信
- pod到service之间的通信
- 集群外部与集群内部组件之间的通信



#### 容器与容器之间的通信
同一个Pod内的容器共享同一个linux协议栈，可以用localhost地址访问彼此的端口
kubernetes利用docker的网桥与容器内的映射eth0设备进行通信


#### pod之间的通信
每个pod都拥有一个真实的全局ip地址
- 同一个node内的不同pod之间 可以直接采用对方的pod的ip地址通信（因为他们都在同一个docker0网桥上，属于同一地址段）
- 不同node上的pod之间

