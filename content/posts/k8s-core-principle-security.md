---
title: "kubernetes 核心原理之 集群安全机制"
date: 2019-03-19T14:29:44+08:00
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


#### 安全性考虑目标
- 保证容器与其所在的宿主机的隔离
- 限制容器给基础设施及其他容器带来消极影响的能力
- 最小权限原则
- 明确组件间边界的划分
- 划分普通用户和管理员的角色
- 在必要时允许将管理员权限赋给普通用户
- 允许拥有secret数据（Keys、Certs、Passwords）的应用在集群中运行

#### 1. API Server认证管理（Authentication）
集群安全的关键就在于如何识别并认证客户端身份，以及随后访问权限的授权这两个关键问题

k8s提供3种级别的客户端身份认证方式：
- 最严格的https证书认证：基于ca根证书签名的双向数字证书认证
- http token认证：通过一个token来识别合法用户

> http token用一个很长的特殊编码方式并且难以被模仿的字符串——token来表明客户端身份，每个token对应一个用户名，存储在api server能访问的一个文件中，当客户端发起api调用请求时，需要在http header里放入token，这样一来，api server就能识别合法用户和非法用户了。

- http base认证：通过用户名+密码的方式


> http base是指把“用户名+冒号+密码”用base64算法进行编码后的字符串放在http request中的header authorization域里发送到服务端，服务端接受后进行解码，获取用户名及密码，然后进行用户身份鉴权过程

#### 2. API Server授权管理（Authorization）
通过授权策略来决定一个api调用是否合法。对合法用户进行授权并且随后在用户访问时进行鉴权，是权限与安全系统的重要一环。

目前支持的授权策略：
- AlwaysDeny：表示拒绝所有的请求，一般用于测试
- AlwaysAllow：允许接受所有请求，如果集群不需要授权，则可以采用这个策略，这也是默认配置
- ABAC：基于属性的访问控制，表示使用用户配置的授权规则对用户请求进行匹配和控制。
- Webhook：通过调用外部rest服务对用户进行授权
- RBAC：基于角色的访问控制

##### ABAC授权模式


##### Webhook授权模式

##### RBAC授权模式详解
基于角色的访问控制：
- 对集群中的资源和非资源权限均有完整的覆盖
- 整个RBAC完全由几个api对象完成，同其他api对象一样，可以用kubectl或api进行操作
- 可以在运行时进行调整，无需重新启动api server

> 要使用RBAC授权模式，需要在api server的启动参数中加上 --authorization-mode=RBAC




#### 3. Admission Control（准入控制）






