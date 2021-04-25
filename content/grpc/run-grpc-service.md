---
title: "grpc应用之三 运行一个grpc服务 Run Grpc Service"
date: 2021-04-25T14:51:48+08:00
keywords: ["grpc"]
categories: ["grpc"]
tags: ["grpc"]
series: [""]
draft: true
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


### 初始化项目
```sh
mkdir $GOPATH/src/tag-service
cd $GOPATH/src/tag-service
go mod init github.com/realjf/tag-service
```
最终目录结构如下：
```sh
.
├── go.mod
├── internal
├── main.go
├── pkg
├── proto
├── server
└── third_party
```
运行grpc安装命令
```sh
go get -u google.golang.org/grpc
```

### 编译和生成proto文件
在proto目录下新建common.proto文件
```proto
syntax = "proto3";

package proto;

message Pager {
    int64 page = 1;
    int64 page_size = 2;
    int64 total_rows = 3;
}
```
再新建tag.proto文件，内容如下：
```proto
syntax = "proto3";

package proto;

import "proto/common.proto";

service TagService {
    rpc GetTagList (GetTagListRequest) returns (GetTagListReply) {}
}

message GetTagListRequest {
    string name = 1;
    uint32 state = 2;
}

message Tag {
    int64 id = 1;
    string name = 2;
    uint32 state = 3;
}

message GetTagListReply {
    repeated Tag list = 1;
    Pager pager = 2;
}
```
在项目根目录下运行如下命令：
```sh
protoc --go_out=plugins=grpc:. ./proto/*.proto 
```
需要注意的一点是，我们在 tag.proto 文件中 import 了 common.proto，因此在执行 protoc 命令生成时，如果你只执行命令 protoc --go_out=plugins=grpc:. ./proto/tag.proto 是会存在问题的。

因此建议若所需生成的 proto 文件和所依赖的 proto 文件都在同一目录下，可以直接执行 ./proto/*.proto 命令来解决，又或是指定所有含关联的 proto 引用 ./proto/common.proto ./proto/tag.proto ，这样子就可以成功生成.pb.go 文件，并且避免了很多的编译麻烦

但若实在是存在多层级目录的情况，可以利用 protoc 命令的 -I 和 M 指令来进行特定处理。

### 编写gRPC方法
#### 获取博客api数据

在pkg/bapi目录下，新建文件api.go，其内容如下：

```golang
package bapi

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
)

const (
	APP_KEY    = "realjf"
	APP_SECRET = "go-language"
)

type AccessToken struct {
	Token string `json:"token"`
}

func (a *API) getAccessToken(ctx context.Context) (string, error) {
	body, err := a.httpGet(ctx, fmt.Sprintf("%s?app_key=%s&app_secret=%s", "auth", APP_KEY, APP_SECRET))
	if err != nil {
		return "", err
	}

	var accessToken AccessToken
	_ = json.Unmarshal(body, &accessToken)
	return accessToken.Token, nil
}

func (a *API) httpGet(ctx context.Context, path string) ([]byte, error) {
	resp, err := http.Get(fmt.Sprintf("%s/%s", a.URL, path))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, _ := ioutil.ReadAll(resp.Body)
	return body, nil
}

type API struct {
	URL string
}

func NewAPI(url string) *API {
	return &API{URL: url}
}

func (a *API) GetTagList(ctx context.Context, name string) ([]byte, error) {
	token, err := a.getAccessToken(ctx)
	if err != nil {
		return nil, err
	}

	body, err := a.httpGet(ctx, fmt.Sprintf("%s?token=%s&name=%s", "api/v1/tags", token, name))
	if err != nil {
		return nil, err
	}

	return body, nil
}

```

#### 编写gRPC Server端
在项目的server目录下新建tag.go文件，内容如下：
```golang
package server

import (
	"context"
	"encoding/json"

	"github.com/realjf/tag-service/pkg/bapi"
	pb "github.com/realjf/tag-service/proto"
)

type TagServer struct{}

func NewTagServer() *TagServer {
	return &TagServer{}
}

func (t *TagServer) GetTagList(ctx context.Context, r *pb.GetTagListRequest) (*pb.GetTagListResponse, error) {
	api := bapi.NewAPI("http://127.0.0.1:8000")
	body, err := api.GetTagList(ctx, r.GetName())
	if err != nil {
		return nil, err
	}

	tagList := pb.GetTagListResponse{}
	err = json.Unmarshal(body, &tagList)
	if err != nil {
		return nil, errcode.TogRPCError(errcode.Fail)
	}

	return &tagList, nil
}

```
在pkg/errcode目录下新建errcode.go文件，其内容如下
```golang
package errcode

import "fmt"

type Error struct {
	code int
	msg  string
}

var _codes = map[int]string{}

func NewError(code int, msg string) *Error {
	if _, ok := _codes[code]; ok {
		panic(fmt.Sprintf("错误码 %d 已经存在，请更换一个", code))
	}
	_codes[code] = msg
	return &Error{code: code, msg: msg}
}

func (e *Error) Error() string {
	return fmt.Sprintf("错误码：%d, 错误信息:：%s", e.Code(), e.Msg())
}

func (e *Error) Code() int {
	return e.code
}

func (e *Error) Msg() string {
	return e.msg
}

```


在pkg/errcode目录下新建common_error.go文件，内容如下：
```golang
package errcode

var (
	Success          = NewError(0, "成功")
	Fail             = NewError(10000000, "内部错误")
	InvalidParams    = NewError(10000001, "无效参数")
	Unauthorized     = NewError(10000002, "认证错误")
	NotFound         = NewError(10000003, "没有找到")
	Unknown          = NewError(10000004, "未知")
	DeadlineExceeded = NewError(10000005, "超出最后截止期限")
	AccessDenied     = NewError(10000006, "访问被拒绝")
	LimitExceed      = NewError(10000007, "访问限制")
	MethodNotAllowed = NewError(10000008, "不支持该方法")
)
```
在pkg/errcode目录下新建rpc_error.go文件，其内容如下：
```golang
package errcode

func TogRPCError(err *Error) error {
	s := status.New(ToRPCCode(err.Code()), err.Msg())
	return s.Err()
}

func ToRPCCode(code int) codes.Code {
	var statusCode codes.Code
	switch code {
	case Fail.Code():
		statusCode = codes.Internal
	case InvalidParams.Code():
		statusCode = codes.InvalidArgument
	case Unauthorized.Code():
		statusCode = codes.Unauthenticated
	case AccessDenied.Code():
		statusCode = codes.PermissionDenied
	case DeadlineExceeded.Code():
		statusCode = codes.DeadlineExceeded
	case NotFound.Code():
		statusCode = codes.NotFound
	case LimitExceed.Code():
		statusCode = codes.ResourceExhausted
	case MethodNotAllowed.Code():
		statusCode = codes.Unimplemented
	default:
		statusCode = codes.Unknown
	}

	return statusCode
}
```


### 编写启动文件
main.go文件内容如下：
```golang
package main

import (
	"flag"
	"log"
	"net"

	pb "github.com/realjf/tag-service/proto"
	"google.golang.org/grpc"
	"github.com/realjf/tag-service/server"
)

var port string

func init() {
	flag.StringVar(&port, "p", "8000", "端口")
	flag.Parse()
}

func main() {
	s := grpc.NewServer()
	pb.RegisterTagServiceServer(s, server.NewTagServer())

	lis, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatalf("net.Listen err: %v", err)
	}

	err = s.Serve(lis)
	if err != nil {
		log.Fatalf("server.Serve err: %v", err)
	}
}

```

现在可以运行go run main.go，查看服务是否运行正常

### 调试gRPC接口
在服务启动后，我们除了要验证服务是否正常运行，还要调试或验证 RPC 方法是否运行正常，而 gRPC 是基于 HTTP/2 协议的，因此不像普通的 HTTP/1.1 接口可以直接通过 postman 或普通的 curl 进行调用。但目前开源社区也有一些方案，例如像 grpcurl，grpcurl 是一个命令行工具，可让你与 gRPC 服务器进行交互，安装命令如下：

```sh
go get github.com/fullstorydev/grpcurl
go install github.com/fullstorydev/grpcurl/cmd/grpcurl
```
windows下可以直接到github[https://github.com/fullstorydev/grpcurl/releases/download/v1.8.0/grpcurl_1.8.0_windows_x86_64.zip](https://github.com/fullstorydev/grpcurl/releases/download/v1.8.0/grpcurl_1.8.0_windows_x86_64.zip)上下载二进制版本


但使用该工具的前提是 gRPC Server 已经注册了反射服务，因此我们需要修改上述服务的启动文件
```golang
import (
    "google.golang.org/grpc/reflection"
    ...
)

func main() {
	s := grpc.NewServer()
	pb.RegisterTagServiceServer(s, server.NewTagServer())
	reflection.Register(s)
	...
}
```
reflection 包是 gRPC 官方所提供的反射服务，我们在启动文件新增了 reflection.Register 方法的调用后，我们需要重新启动服务，反射服务才可用。



接下来我们可以使用grpcurl工具进行调试，一般我们可以首先执行list命令：
```sh
grpcurl -plaintext localhost:8000 list

grpc.reflection.v1alpha.ServerReflection
proto.TagService

# list指令
grpcurl -plaintext localhost:8000 list proto.TagService

proto.TagService.GetTagList
```
- plaintext：grpcurl默认使用TLS认证（可通过-cert和-key设置），我们这里指定这个选项来忽略TLS认证
- localhost:8000 指定我们运行的服务host
- list：指定所执行的命令，list子命令可获取该服务的RPC方法列表信息

在了解了该服务具体有什么RPC方法后，我们可以执行下面的命令去调用RPC方法：

```sh
grpcurl -plaintext -d '{"name":"Go"}' localhost:8000 proto.TagService.GetTagList
```





