---
title: "kubernetes 核心原理之 Apiserver"
date: 2019-03-19T14:25:43+08:00
keywords: ["kubernetes", "k8s", "k8s核心原理", "apiserver"]
categories: ["kubernetes"]
tags: ["kubernetes", "k8s", "k8s核心原理", "apiserver"]
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


API Server的核心功能提供了kubernetes各类资源对象（如pod、rc、service等）的增删改查以及watch等http rest接口，是集群内各个功能模块之间数据交互和通信的中心枢纽，是整个系统的数据总线和数据中心。

- 是集群管理的api入口
- 是资源配额控制的入口
- 提供了完备的集群安全机制
