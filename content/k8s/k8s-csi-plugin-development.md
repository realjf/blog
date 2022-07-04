---
title: "K8s CSI插件开发简介 K8s CSI Plugin Development Overview"
date: 2022-07-04T09:58:20+08:00
keywords: ["k8s", "csi"]
categories: ["k8s"]
tags: ["k8s", "csi"]
series: ["csi"]
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

[CSI插件开发官方文档](https://kubernetes-csi.github.io/docs/)

### 简介
容器存储接口 (CSI) 是一种标准，用于将任意块和文件存储系统暴露给 Kubernetes 等容器编排系统 (CO) 上的容器化工作负载。使用 CSI 第三方存储提供商可以编写和部署插件，在 Kubernetes 中公开新的存储系统，而无需接触核心 Kubernetes 代码。

kubernetes版本与CSI兼容版本关系
| kubernetes | CSI 兼容版本 | 版本状态 |
| :---: | :---:|:---:|
| v1.9 | v0.1.0 | Alpha |
| v1.10 | v0.2.0 | Beta|
| v1.11 | v0.3.0 | Beta|
| v1.13 | v0.3.0,v1.0.0| GA|

#### 开发和部署
**最小要求**
唯一的要求是关于 Kubernetes（主节点和节点）组件如何查找 CSI 驱动程序并与之通信

CSI要求如下：
- Kubelet 到 CSI 驱动程序的通信
  - Kubelet 通过 Unix Domain Socket 直接向 CSI 驱动程序发出 CSI 调用（如 NodeStageVolume、NodePublishVolume 等）以挂载和卸载卷
  - Kubelet 通过 kubelet 插件注册机制发现 CSI 驱动程序（以及用于与 CSI 驱动程序交互的 Unix 域套接字）。
  - 因此，部署在 Kubernetes 上的所有 CSI 驱动程序必须在每个支持的节点上使用 kubelet 插件注册机制注册自己。
- Master 到CSI驱动程序的通信
  - Kubernetes 主组件不直接与 CSI 驱动程序通信（通过 Unix 域套接字或其他方式）
  - Kubernetes 主组件仅与 Kubernetes API 交互。
  - 因此，需要依赖于 Kubernetes API 的操作（如卷创建、卷附加、卷快照等）的 CSI 驱动程序必须监视 Kubernetes API 并针对它触发适当的 CSI 操作

因为这些要求是最低限度的规定，所以 CSI 驱动程序开发人员可以自由地实施和部署他们认为合适的驱动程序。

也就是说，为了简化开发和部署，建议使用下面描述的机制。

#### 推荐机制（用于 Kubernetes 的 CSI 驱动开发和部署）

Kubernetes 开发团队建立了“推荐机制”，用于在 Kubernetes 上开发、部署和测试 CSI 驱动程序。它旨在减少样板代码并简化 CSI 驱动程序开发人员的整体流程

此“推荐机制”使用以下组件:
- Kubernetes CSI Sidecar 容器
- Kubernetes CSI 对象
- CSI 驱动程序测试工具

要使用这种机制实现 CSI 驱动程序，CSI 驱动程序开发人员应该：
1. 创建一个容器化应用程序，实现身份、节点和可选的 CSI 规范中描述的控制器服务（CSI 驱动程序容器）。
2. 使用 csi-sanity 对其进行单元测试
3. 定义 Kubernetes API YAML 文件以部署 CSI 驱动程序容器以及适当的 sidecar 容器。
4. 在 Kubernetes 集群上部署驱动程序并在其上运行端到端功能测试


### 为Kubernetes开发CSI驱动

所有 CSI 驱动程序的开发人员都应加入 https://groups.google.com/forum/#!forum/container-storage-interface-drivers-announce 以随时了解可能影响现有 CSI 驱动程序的 CSI 或 Kubernetes 更改。

#### 介绍
创建 CSI 驱动程序的第一步是编写实现 CSI 规范中描述的 gRPC 服务的应用程序

CSI 驱动程序至少必须实现以下 CSI 服务：
- CSI Identity 服务
  - 使调用者（Kubernetes 组件和 CSI sidecar 容器）能够识别驱动程序及其支持的可选功能。
- CSI Node 服务
  - 仅需要 NodePublishVolume、NodeUnpublishVolume 和 NodeGetCapabilities
  - 必需的方法使调用者能够使卷在指定路径上可用，并发现驱动程序支持哪些可选功能。

所有 CSI 服务都可以在同一个 CSI 驱动程序应用程序中实现。 CSI 驱动程序应用程序应该被容器化，以便于在 Kubernetes 上部署。容器化后，CSI 驱动程序可以与 CSI Sidecar Containers 配对，并根据需要以节点和/或控制器模式部署。

#### 能力
如果您的驱动程序支持附加功能，CSI“功能”可用于宣传它支持的可选方法/服务，例如：
- CONTROLLER_SERVICE（插件能力）
  - 整个 CSI 控制器服务是可选的。此功能指示驱动程序实现 CSI 控制器服务中的一个或多个方法
- VOLUME_ACCESSIBILITY_CONSTRAINTS（插件能力）
  - 此功能表明该驱动程序的卷可能无法从集群中的所有节点均等地访问，并且该驱动程序将返回额外的拓扑相关信息，Kubernetes 可以使用这些信息更智能地调度工作负载或影响将在何处配置卷。
- VolumeExpansion（插件能力）
  - 此功能表明驱动程序支持在创建后调整（扩展）卷的大小。
- CREATE_DELETE_VOLUME (ControllerServiceCapability)
  - 此功能表明驱动程序支持动态卷配置和删除
- PUBLISH_UNPUBLISH_VOLUME（控制器服务能力）
  - 此功能表明驱动程序实现了 ControllerPublishVolume 和 ControllerUnpublishVolume - 对应于 Kubernetes 卷附加/分离操作的操作。例如，这可能会导致针对 Google Cloud 控制平面执行“卷附加”操作，以将指定卷附加到 Google Cloud PD CSI 驱动程序的指定节点。
- CREATE_DELETE_SNAPSHOT (ControllerServiceCapability)
  - 此功能表明驱动程序支持配置卷快照以及使用这些快照配置新卷的能力。
- CLONE_VOLUME（控制器服务能力）
  - 此功能表明驱动程序支持卷的克隆。
- STAGE_UNSTAGE_VOLUME（节点服务能力）
  - 此功能表明驱动程序实现了 NodeStageVolume 和 NodeUnstageVolume -- 对应于 Kubernetes 卷设备挂载/卸载操作的操作。例如，这可以用于创建块存储设备的全局（每个节点）卷安装。

这是部分列表，请参阅 [CSI 规范](https://github.com/container-storage-interface/spec/blob/master/spec.md)以获取完整的功能列表。另请参阅[功能部分](https://kubernetes-csi.github.io/docs/features.html)以了解功能如何与 Kubernetes 集成。



[每个 Kubernetes 版本中所做的主要 CSI 更改](https://kubernetes-csi.github.io/docs/kubernetes-changelog.html)


Kubernetes 集群控制器负责管理跨多个 CSI 驱动程序的快照对象和操作，因此它们应该由 Kubernetes 分销商捆绑和部署，作为其 Kubernetes 集群管理过程的一部分（独立于任何 CSI 驱动程序）。

Kubernetes 开发团队维护以下 Kubernetes 集群控制器：
- snapshot-controller


#### Kubernetes CSI Sidecar容器
Kubernetes CSI Sidecar Containers 是一组标准容器，旨在简化 Kubernetes 上 CSI 驱动程序的开发和部署。 

这些容器包含用于监视 Kubernetes API、触发针对“CSI 卷驱动程序”容器的适当操作以及适当更新 Kubernetes API 的通用逻辑。 

这些容器旨在与第三方 CSI 驱动程序容器捆绑在一起，并作为 pod 一起部署。 

这些容器由 Kubernetes 存储社区开发和维护。 
容器的使用是严格可选的，但强烈建议使用。 

这些Sidecar容器的好处包括： 
- 减少“样板”代码。 
  - CSI 驱动程序开发人员不必担心复杂的“Kubernetes 特定”代码。 
- 关注点分离。 
  - 与 Kubernetes API 交互的代码与实现 CSI 接口的代码隔离（并且在不同的容器中）。 

Kubernetes 开发团队维护以下 Kubernetes CSI Sidecar 容器：
- external-provisioner
  - CSI external-provisioner 是一个sidecar容器，用于监视 Kubernetes API 服务器的 PersistentVolumeClaim 对象。
  - 它针对指定的 CSI 端点调用 CreateVolume 以供应新卷。
- external-attacher
  - CSI external-attacher 是一个 sidecar 容器，它监视 Kubernetes API 服务器中的 VolumeAttachment 对象并针对 CSI 端点触发 Controller[Publish|Unpublish]Volume 操作。
- external-snapshotter
  - 从 Beta 版本开始，快照控制器将监视 Kubernetes API 服务器中的 VolumeSnapshot 和 VolumeSnapshotContent CRD 对象。 CSI external-snapshotter sidecar 仅监视 Kubernetes API 服务器的 VolumeSnapshotContent CRD 对象。 CSI external-snapshotter sidecar 还负责调用 CSI RPC CreateSnapshot、DeleteSnapshot 和 ListSnapshots。
- external-resizer
  - CSI external-resizer 是一个 sidecar 容器，用于监视 Kubernetes API 服务器的 PersistentVolumeClaim 对象编辑，并在用户请求 PersistentVolumeClaim 对象上的更多存储时针对 CSI 端点触发 ControllerExpandVolume 操作。
- node-driver-registrar
  - CSI node-driver-registrar 是一个 sidecar 容器，它从 CSI 端点获取驱动程序信息（使用 NodeGetInfo），并使用 kubelet 插件注册机制将其注册到该节点上的 kubelet。
- cluster-driver-registrar(已弃用)
  - CSI cluster-driver-registrar 是一个sidecar容器，它通过创建一个 CSIDriver 对象向 Kubernetes 集群注册一个 CSI 驱动程序，该对象使驱动程序能够自定义 Kubernetes 与其交互的方式。
- livenessprobe
  - CSI livenessprobe 是一个 sidecar 容器，用于监控 CSI 驱动程序的健康状况，并通过 Liveness Probe 机制将其报告给 Kubernetes。这使 Kubernetes 能够自动检测驱动程序的问题并重新启动 pod 以尝试修复问题。

#### CSI对象
Kubernetes API 包含以下 CSI 特定对象：
- CSIDriver 对象
  - CSIDriver Kubernetes API 对象有两个用途：
    1. 简化驱动程序发现
    2. 自定义 Kubernetes 行为
- CSINode 对象卷拓扑
    1. 将 Kubernetes 节点名称映射到 CSI 节点名称，
    2. 驱动可用性
    3. 卷拓扑


















