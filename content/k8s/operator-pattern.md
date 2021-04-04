---
title: "k8s 之 Operator模式 Operator Pattern"
date: 2021-04-04T10:26:27+08:00
keywords: ["k8s"]
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

Operator模式介绍[https://kubernetes.io/zh/docs/concepts/extend-kubernetes/operator/](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/operator/)

Operator 模式旨在捕获（正在管理一个或一组服务的）运维人员的关键目标。 负责特定应用和 service 的运维人员，在系统应该如何运行、如何部署以及出现问题时如何处理等方面有深入的了解。

在 Kubernetes 上运行工作负载的人们都喜欢通过自动化来处理重复的任务。 Operator 模式会封装你编写的（Kubernetes 本身提供功能以外的）任务自动化代码。

Operator 是 Kubernetes API 的客户端，充当[定制资源](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/api-extension/custom-resources/)的控制器。

使用operator可以自动化的事情：

- 按需部署应用
- 获取/还原应用状态的备份
- 处理应用代码的升级以及相关改动。例如，数据库 schema 或额外的配置设置
- 发布一个 service，要求不支持 Kubernetes API 的应用也能发现它
- 模拟整个或部分集群中的故障以测试其稳定性
- 在没有内部成员选举程序的情况下，为分布式应用选择首领角色


部署 Operator 最常见的方法是将自定义资源及其关联的控制器添加到你的集群中。 跟运行容器化应用一样，控制器通常会运行在 控制平面 之外。

部署 Operator 后，你可以对 Operator 所使用的资源执行添加、修改或删除操作。


### 编写自己的operator
以下是一些库和工具，你可以用于编写自己的云原生operator

- kubebuilder [https://book.kubebuilder.io/](https://book.kubebuilder.io/)
- KUDO [https://kudo.dev/](https://kudo.dev/)
- Metacontroller [https://metacontroller.app/](https://metacontroller.app/)
- Operator Framework [https://operatorframework.io/](https://operatorframework.io/)

当然也可以在[OperatorHub.io](https://operatorhub.io/)上找到现成的、适合你的operator