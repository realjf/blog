---
title: "kubernetes 核心原理之 Controller Manager"
date: 2019-03-19T14:26:00+08:00
keywords: ["kubernetes", "k8s", "k8s核心原理"]
categories: ["kubernetes"]
tags: ["kubernetes", "k8s", "k8s核心原理"]
draft: false
---


controller manager作为集群内部的管理控制中心，负责集群内的Node、pod副本、服务端（Endpoint）、命名空间（Namespace）、服务账号（ServiceAccount）、资源定额（ResourceQuota）等的管理。

#### controller manager组件
- replication controller
- node controller
- resourceQuota controller
- namespace controller
- serviceAccount controller
- token controller
- service controller
- endpoint controller


#### 1. Replication Controller（副本控制器）
核心作用是确保在任何时候集群中一个RC所关联的pod副本数量保持预设值。
> 只有当pod的重启策略是always时（RestartPolicy=Always），Replication Controller才会管理该Pod的操作（创建、销毁、重启等）。

RC中的Pod模板就像一个模具，一旦pod被创建完毕，它们之间就没有关系了。

此外，可以通过修改Pod的标签来实现脱离RC的管控。该方法可以用于将pod从集群中迁移、数据修复等调试。


##### Replication Controller职责
- 确保当前集群中有且仅有N个pod实例，N是RC中定义的pod副本数量
- 通过调整RC的spec.replicas属性值来实现系统扩容或者缩容
- 通过改变RC中的pod模板（主要是镜像版本）来实现系统的滚动升级


##### Replication Controller典型使用场景
- 重新调度（Rescheduling）
- 弹性伸缩（Scaling）
- 滚动更新（Rolling Updates）

#### 2. Node Controller
Node Controller通过API Server实时获取Node的相关信息：节点健康状况、节点资源、节点名称、节点地址信息、操作系统版本、Docker版本、kubelet版本等。

##### node controller节点信息更新机制
比较节点信息和node controller的nodeStatusMap中保存的节点信息
- 如果没有收到kubelet发送的节点信息、第一次收到节点kubelet发送的节点信息，或处理过程中节点状态变成非健康状态，则在nodeStatusMap中保存改节点的状态信息，并用node controller所在节点的系统时间作为探测时间和节点状态变化时间。
- 如果指定时间内收到新的节点信息，且节点状态发生变化，则在nodeStatusMap保存改节点的状态信息，并用node controller所在节点的系统时间作为探测时间，用上次节点信息中的节点状态变化时间作为该节点的状态变化时间
- 如果某一段时间内没有收到该节点状态信息，则设置节点状态为未知，并通过api server保存节点状态


#### 3. ResourceQuota Controller（资源配额管理）
资源配额管理确保了指定的资源对象在任何时候都不会超量占用系统物理资源，避免由于某些业务进程的设计或实现的缺陷导致整个系统运行紊乱甚至意外宕机

##### k8s支持一下三个层次的资源配额管理
- 容器级别，可以对cpu和memory进行限制
- pod级别，可以对一个pod内所有容器的可用资源进行限制
- namespace级别，为namespace（多租户）级别的资源限制，包括：pod数量、replication controller数量，service数量，resourceQuota数量，secret数量，可持有的pv数量

配额管理通过admission control来控制，admission control当前提供两种方式的配额约束，分别是limitRanger与resourceQuota。

- limitRanger作用于pod和container上
- resourceQuota则作用于namespace上，限定一个namespace里的各类资源的使用总额。




#### 4. Namespace Controller
Namespace Controller定时通过api server读取这些namespace信息，如果namespace被api标识为优雅删除（通过设置删除期限，即DeletionTimestamp属性被设置），则将该namespace的状态设置为“Terminating”并保存到etcd中。同时namespace controller删除该namespace下的serviceAccount、rc、pod、secret、persistentVolume、listRange、resourceQuota和event等资源对象。


当namespace处于“terminating”后，由admission controller的namespacelifecycle插件来阻止为该namespace创建新的资源。同时，在删除所有资源后，namespace controller对该namespace执行finalize操作，删除namespace的spec.finalizers域中的信息

如果namespace controller观察到namespace设置了删除期限，同时其spec.finalizers域值为空时，namespace controller将通过api server删除该namespace资源。


#### 5. Service Controller与Endpoint Controller
Endpoints表示一个service对应的所有pod副本的访问地址，而Endpoints Controller就是负责生成和维护所有Endpoints对象的控制器。

Service Controller负责监听service和对应pod的变化。



