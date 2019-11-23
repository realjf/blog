---
title: "Golang Micro 微服务框架使用"
date: 2019-10-22T09:50:59+08:00
keywords: ["golang", "微服务", "microservice"]
categories: ["微服务", "golang"]
tags: ["golang", "微服务", "microservice"]
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

## 准备
- 搭建好golang开发环境
- 安装git等相关工具

## 开始
### 一、安装protobuf
protobuf用于生成微服务代码
```bash
go get github.com/micro/protoc-gen-micro

# 同时需要安装protoc和protoc-go-gen
go get -d -u github.com/golang/protobuf/protoc-gen-go
go install github.com/golang/protobuf/protoc-gen-go

```
> 如果需要别的语言的代码生成器，请参阅[https://github.com/protocolbuffers/protobuf](https://github.com/protocolbuffers/protobuf)

> 关于protobuf的使用，请参阅[https://developers.google.com/protocol-buffers/](https://developers.google.com/protocol-buffers/)


### 二、服务发现
服务发现用于将服务名称解析为地址，服务发现可以使用etcd、zookeeper、consul等组件
#### 安装etcd
etcd下载地址[https://github.com/etcd-io/etcd/releases](https://github.com/etcd-io/etcd/releases)


### 三、写一个服务
以下为一个简单的rpc服务例子

#### 创建服务proto
微服务的关键要求之一是严格定义接口。 

Micro使用protobuf来实现这一目标。 
在这里，我们使用Hello方法定义了Greeter处理程序。
它需要一个字符串参数同时使用一个HelloRequest和HelloResponse。

```proto
syntax = "proto3";

service Greeter {
    rpc Hello(HelloRequest) returns (HelloResponse) {}
}

message HelloRequest {
    string name = 1;
}

message HelloResponse {
    string greeting = 2;
}

```
#### 生成proto
```bash
protoc --proto_path=$GOPATH/src:. --micro_out=. --go_out=. path/to/greeter.proto
```

#### 写服务业务逻辑
服务需要遵循以下规则：

- 实现greeter定义的接口
- 初始化一个micro.Service
- 注册greeter处理函数
- 运行服务

```go
package main

import (
	"context"
	"fmt"

	micro "github.com/micro/go-micro"
	proto "github.com/micro/examples/service/proto"
)

type Greeter struct{}

func (g *Greeter) Hello(ctx context.Context, req *proto.HelloRequest, rsp *proto.HelloResponse) error {
	rsp.Greeting = "Hello " + req.Name
	return nil
}

func main() {
	// Create a new service. Optionally include some options here.
	service := micro.NewService(
		micro.Name("greeter"),
	)

	// Init will parse the command line flags.
	service.Init()

	// Register handler
	proto.RegisterGreeterHandler(service.Server(), new(Greeter))

	// Run the server
	if err := service.Run(); err != nil {
		fmt.Println(err)
	}
}
```

#### 运行服务
```go
go run examples/service/main.go
```
#### 定义一个客户端
```go
package main

import (
	"context"
	"fmt"

	micro "github.com/micro/go-micro"
	proto "github.com/micro/examples/service/proto"
)


func main() {
	// Create a new service. Optionally include some options here.
	service := micro.NewService(micro.Name("greeter.client"))
	service.Init()

	// Create new greeter client
	greeter := proto.NewGreeterService("greeter", service.Client())

	// Call the greeter
	rsp, err := greeter.Hello(context.TODO(), &proto.HelloRequest{Name: "John"})
	if err != nil {
		fmt.Println(err)
	}

	// Print response
	fmt.Println(rsp.Greeting)
}
```
#### 运行客户端
```bash
go run client.go
```

### 四、发布订阅
Go-micro具有用于事件驱动架构的内置消息代理接口。

PubSub与RPC在protobuf生成的相同消息上运行。它们会自动进行编码/解码，并通过代理发送。默认情况下，go-micro包含点对点http代理，但是可以通过go-plugins替换掉

#### 发布
创建一个发布者
```go
p := micro.NewPublisher("events", service.Client())
// 其中的events是话题名称
```
发布一个proto消息
```go
p.Publish(context.TODO(), &proto.Event{Name: "event"})
```
#### 订阅
创建一个消息句柄，
```go
func ProcessEvent(ctx context.Context, event *proto.Event) error {
	fmt.Printf("Got event %+v\n", event)
	return nil
}
```
注册消息句柄到一个话题
```go
micro.RegisterSubscriber("events", ProcessEvent)
```
> 详细例子请参考[https://github.com/micro/examples/tree/master/pubsub](https://github.com/micro/examples/tree/master/pubsub)



### 五、插件
默认情况下，go-micro仅在核心提供每个接口的一些实现，但它是完全可插入的。
github.com/micro/go-plugins上已有许多插件

#### 插件使用
创建一个plugins.go文件
```go
import (
        // etcd v3 registry
        _ "github.com/micro/go-plugins/registry/etcdv3"
        // nats transport
        _ "github.com/micro/go-plugins/transport/nats"
        // kafka broker
        _ "github.com/micro/go-plugins/broker/kafka"
)
```
构建二进制包
```bash
go build -i -o service ./main.go ./plugins.go
```
插件使用
```go
service --registry=etcdv3 --transport=nats --broker=kafka
```


### 六、包装器
go-micro有很多中间件可以作为包装器使用

#### 处理句柄
以下是一个处理句柄的日志函数示例
```go
func logWrapper(fn server.HandlerFunc) server.HandlerFunc {
	return func(ctx context.Context, req server.Request, rsp interface{}) error {
		fmt.Printf("[%v] server request: %s", time.Now(), req.Endpoint())
		return fn(ctx, req, rsp)
	}
}
```
初始化如下
```go
service := micro.NewService(
	micro.Name("greeter"),
	// wrap the handler
	micro.WrapHandler(logWrapper),
)
```
#### client
以下为一个客户端包装器log请求示例
```go
type logWrapper struct {
	client.Client
}

func (l *logWrapper) Call(ctx context.Context, req client.Request, rsp interface{}, opts ...client.CallOption) error {
	fmt.Printf("[wrapper] client request to service: %s endpoint: %s\n", req.Service(), req.Endpoint())
	return l.Client.Call(ctx, req, rsp)
}

// implements client.Wrapper as logWrapper
func logWrap(c client.Client) client.Client {
	return &logWrapper{c}
}
```
初始化创建
```go
service := micro.NewService(
	micro.Name("greeter"),
	// wrap the client
	micro.WrapClient(logWrap),
)

```
