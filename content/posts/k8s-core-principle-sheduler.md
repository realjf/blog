---
title: "kubernetes 核心原理之 Sheduler"
date: 2019-03-19T14:26:15+08:00
keywords: ["kubernetes", "k8s", "k8s核心原理"]
categories: ["kubernetes"]
tags: ["kubernetes", "k8s", "k8s核心原理"]
draft: false
related:
  threshold: 80
  includeNewer: false
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



作用是将待调度的pod按照特定的调度算法和调度策略绑定到集群中的某个合适的Node上，并将绑定信息写入etcd中。


目标节点上的kubelet通过api server监听到schduler产生的pod绑定事件，然后获取对应的pod清单，下载image镜像，并启动容器。 


#### Scheduler默认调度流程分为以下两步
- 预调度过程，即遍历所有目标node，筛选出符合要求的候选节点
- 确定最优节点，在上一步基础上，采用优选策略计算出每个候选节点的积分，积分高者胜出。


Scheduler调度流程是通过插件方式加载的“调度算法提供者”（AlgorithmProvider）具体实现的。一个AlgorithmProvider其实是一组预选策略与一组优先选择策略的结构体。


#### Scheduler中可选的预选策略
- NoDiskConflict 
- PodFitsResources
- PodSelectorMatches
- PodFitsHost
- CheckNodeLabelPresence
- CheckServiceAffinity
- PodFitsPorts


#### Scheduler优选策略
- LeastRequestedPriority（资源消耗最小）
- CalculateNodeLabelPriority
- BalancedResourceAllocation（各项资源使用率最均衡的节点）

每个节点通过优选策略算出一个得分，最终选出分值最大的节点作为优选的结果。



