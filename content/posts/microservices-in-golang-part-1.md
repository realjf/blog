---
title: "golang 微服务 第一章"
date: 2019-10-28T14:52:55+08:00
keywords: ["微服务", "microservice", "golang", "grpc", "protobuf"]
categories: ["微服务", "golang"]
tags: ["微服务", "microservice", "golang", "grpc", "protobuf"]
draft: true
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





