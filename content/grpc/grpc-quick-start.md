---
title: "grpc应用之二 gRPC使用 grpc Quick Start"
date: 2021-04-25T12:41:57+08:00
keywords: ["grpc"]
categories: ["grpc"]
tags: ["grpc"]
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

### 安装grpc
在上一个例子[grpc应用之一 使用protobuf](https://realjf.io/grpc/protobuf-quick-start)的项目下，执行如下命令:
```sh
go get -u google.golang.org/grpc@latest
```

### gRPC的四种调用方式

- 一元RPC
- 服务端流式RPC
- 客户端流式RPC
- 双向流式RPC

修改server目录下的server.go文件，其代码如下：
```golang
package main

import (
	"flag"
  // 用pb别名来引用proto里定义的类型方法
	pb "github.com/realjf/grpc-demo/proto"
)

var port string

func init() {
	flag.StringVar(&port, "p", "8000", "启动端口号")
	flag.Parse()
}

```
每次在proto文件中定义RPC方法的proto时，需要重新在根目录下运行如下命令重新编译生成语句：
```sh
protoc --go_out=plugins=grpc:. ./proto/*.proto
```

### 一元RPC
一元 RPC，也就是是单次 RPC 调用，简单来讲就是客户端发起一次普通的 RPC 请求，响应，是最基础的调用类型，也是最常用的方式，

#### proto文件
```proto
rpc SayHello(HelloRequest) returns (HelloRespnose) {};
```
#### server端
server.go代码如下：
```golang
package main

import (
	"context"
	"flag"
	"net"

	pb "github.com/realjf/grpc-demo/proto"
	"google.golang.org/grpc"
)

var port string

func init() {
	flag.StringVar(&port, "p", "8000", "启动端口号")
	flag.Parse()
}

type GreeterServer struct{}

func (s *GreeterServer) SayHello(ctx context.Context, r *pb.HelloRequest) (*pb.HelloResponse, error) {
	return &pb.HelloResponse{Code: 200, Message: "success"}, nil
}

func main() {
	server := grpc.NewServer()
	pb.RegisterGreeterServer(server, &GreeterServer{})
	lis, _ := net.Listen("tcp", ":"+port)
	server.Serve(lis)
}

```
- 创建gRPC Server对象，你可以理解为它是Server端的抽象对象
- 将GreeterServer注册到gRPC Server的内部注册中心，这样可以在接收到请求时，通过内部的“服务发现”，发现该服务端接口并转移进行逻辑处理
- 创建Listen，监听TCP端口
- gRPC Server开始lis.Accept，直到Stop或GracefulStop

##### client
client/client.go的代码如下：

```golang
package main

import (
	"context"
	"flag"
	"log"

	pb "github.com/realjf/grpc-demo/proto"
	"google.golang.org/grpc"
)

var port string

func init() {
	flag.StringVar(&port, "p", "8000", "启动端口号")
	flag.Parse()
}

func main() {
	conn, _ := grpc.Dial(":"+port, grpc.WithInsecure())
	defer conn.Close()

	client := pb.NewGreeterClient(conn)
	_ = SayHello(client)
}

func SayHello(client pb.GreeterClient) error {
	resp, _ := client.SayHello(context.Background(), &pb.HelloRequest{Name: "realjf"})
	log.Printf("client.SayHello resp: %s", resp.Message)
	return nil
}

```
- 创建与给定服务端的连接句柄
- 创建Greeter的客户端对象
- 发送RPC请求，等待同步响应，得到回调后返回响应结果

现在可以运行一元RPC的服务端和客户端查看结果

### 服务端流式RPC
服务器端流式 RPC，也就是是单向流，并代指 Server 为 Stream，Client 为普通的一元 RPC 请求。

简单来讲就是客户端发起一次普通的 RPC 请求，服务端通过流式响应多次发送数据集，客户端 Recv 接收数据集。

#### proto文件

新增如下内容：
```proto
rpc SayList(HelloRequest) returns (stream HelloResponse) {};
```
#### server端

```golang
func (s *GreeterServer) SayList(r *pb.HelloRequest, stream pb.Greeter_SayListServer) error {
	for n := 0; n <= 6; n++ {
		_ = stream.Send(&pb.HelloResponse{Code: 200, Message: "hello.list"})
	}
	return nil
}
```
在 Server 端，主要留意 stream.Send 方法，是 protoc 在生成时，根据定义生成了各式各样符合标准的接口方法。最终再统一调度内部的 SendMsg 方法，该方法涉及以下过程:

- 消息体序列化
- 压缩序列化后的消息体
- 对正在传输的消息体增加5个字节的header（标志位）
- 判断压缩+序列化后的消息体的总字节长度是否大于预设的maxSendMessageSize，若超出则提示错误。
- 写入给流的数据集

#### client端

```golang
func SayList(client pb.GreeterClient, r *pb.HelloRequest) error {
	stream, _ := client.SayList(context.Background(), r)
	for {
		resp, err := stream.Recv()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		log.Printf("resp: %v", resp)
	}
	return nil
}
```
在client端，stream.Recv()方法是对ClientStream.RecvMsg方法的封装，而RecvMsg方法会从流中读取完整的gRPC消息体，

- RecvMsg是阻塞等待的
- RecvMsg当流成功/结束（调用了Close）时，会返回io.EOF
- RecvMsg当流出现任何错误时，流会被终止，错误信息会包含RPC错误码，而在RecvMsg中可能出现如下错误：
  - io.EOF、io.ErrUnexpectedEOF
  - transport.ConnectionError
  - google.golang.org/grpc/codes（grpc的预定义错误码）
 
> 需要注意的是，默认的 MaxReceiveMessageSize 值为 1024 *1024* 4，若有特别需求，可以适当调整。

### 客户端流式RPC
客户端流式 RPC，单向流，客户端通过流式发起多次 RPC 请求给服务端，服务端发起一次响应给客户端，

#### proto文件
```proto
rpc SayRecord(stream HelloRequest) returns (HelloResponse) {};
```

#### server端
```golang
func (s *GreeterServer) SayRecord(stream pb.Greeter_SayRecordServer) error {
	for {
		resp, err := stream.Recv()
		if err == io.EOF {
			return stream.SendAndClose(&pb.HelloResponse{Message: "say.record"})
		}
		if err != nil {
			return err
		}
		log.Printf("resp: %v", resp)
	}
	return nil
}

```
你可以发现在这段程序中，我们对每一个 Recv 都进行了处理，当发现 io.EOF (流关闭) 后，需要通过 stream.SendAndClose 方法将最终的响应结果发送给客户端，同时关闭正在另外一侧等待的 Recv。

#### client端
```golang
func SayRecord(client pb.GreeterClient, r *pb.HelloRequest) error {
	stream, _ := client.SayRecord(context.Background())
	for n := 0; n < 6; n++ {
		_ = stream.Send(r)
	}
	resp, _ := stream.CloseAndRecv()

	log.Printf("resp err: %v", resp)
	return nil
}
```
在 Server 端的 stream.CloseAndRecv，与 Client 端 stream.SendAndClose 是配套使用的方法。

### 双向流式RPC
双向流式 RPC，顾名思义是双向流，由客户端以流式的方式发起请求，服务端同样以流式的方式响应请求。

首个请求一定是 Client 发起，但具体交互方式（谁先谁后、一次发多少、响应多少、什么时候关闭）根据程序编写的方式来确定（可以结合协程）。

#### proto文件
```proto
rpc SayRoute(stream HelloRequest) returns (stream HelloResponse) {};
```

#### server端
```golang
func (s *GreeterServer) SayRoute(stream pb.Greeter_SayRouteServer) error {
	n := 0
	for {
		_ = stream.Send(&pb.HelloResponse{Code: 200, Message: "say.route"})

		resp, err := stream.Recv()
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}

		n++
		log.Printf("resp: %v", resp)
	}
}
```

#### client端
```golang
func SayRoute(client pb.GreeterClient, r *pb.HelloRequest) error {
	stream, _ := client.SayRoute(context.Background())
	for n := 0; n <= 6; n++ {
		_ = stream.Send(r)
		resp, err := stream.Recv()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}

		log.Printf("resp err: %v", resp)
	}

	_ = stream.CloseSend()
	
	return nil
}
```

