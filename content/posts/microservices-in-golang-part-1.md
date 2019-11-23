---
title: "golang 微服务 第一章"
date: 2019-10-28T14:52:55+08:00
keywords: ["微服务", "microservice", "golang", "grpc", "protobuf"]
categories: ["微服务", "golang"]
tags: ["微服务", "microservice", "golang", "grpc", "protobuf"]
draft: true
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

## 环境准备
- 安装gRPC/protobuf [这里](https://grpc.io/docs/quickstart/go/)
- 安装golang [这里](https://golang.org/doc/install)
- 安装golang依赖包

```go
go get -u google.golang.org/grpc
go get -u github.com/golang/protobuf/protoc-gen-go
```

### 什么是微服务以及为什么使用微服务？
简单说，微服务就是把原来大型的单个应用程序或服务拆分成功能单一的简单服务，使得各个单服务各司其职，提高了服务的高可用和可扩展性。


### 为什么使用golang？
- Golang相对轻量级，构建速度快，运行速度快，并且对并发具有出色的支持，这在跨多台机器和内核运行时具有强大的功能。
- golang标准库支持全面，对web服务编写简单易用
- Go有很多的微服务框架，go-micro、micro、gokit等


### 什么是grpc?
grpc是一个出自google的轻量级基于rpc通信协议的库。

gRPC使用新的HTTP 2.0规范，该规范允许使用二进制数据。它甚至允许双向流传输，这非常酷！ HTTP 2对于gRPC的工作原理非常重要

grpc数据交换描述语言叫protobuf，protobuf允许你定义一个开发友好格式的服务接口

> 如果向更深入了解grpc，可以阅读[这里](https://blog.gopheracademy.com/advent-2017/go-grpc-beyond-basics/)

首先创建proto文件，添加如下内容
```proto
// 



```




