---
title: "grpc应用之一 使用protobuf Protobuf Quick Start"
date: 2021-04-25T10:59:04+08:00
keywords: ["golang", "grpc"]
categories: ["golang", "grpc"]
tags: ["golang", "grpc"]
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

protoc 是 Protobuf 的编译器，是用 C++ 所编写的，其主要功能是用于编译.proto 文件
### 下载安装protobuf编译器protoc
```sh
wget https://github.com/protocolbuffers/protobuf/releases/download/v3.15.8/protobuf-all-3.15.8.zip
unzip protobuf-all-3.15.8.zip && cd protobuf-3.15.8/
./configure
make
make install

# 检查是否安装成功
protoc --version

```
Protocol Buffers Libraries 的默认安装路径在 /usr/local/lib 下

### protoc插件安装
```sh
go get -u github.com/golang/protobuf/protoc-gen-go@latest

# 将所编译安装的 Protoc Plugin 的可执行文件中移动到相应的 bin 目录下，让其可以直接运行protoc-gen-go
export PATH=$PATH:$GOPATH/bin
```

### 初始化项目
```sh
mkdir -p $GOPATH/src/grpc-demo
cd $GOPATH/src/grpc-demo
go mod init github.com/realjf/grpc-demo
```
初始化后，新建server、client、proto目录，最终目录结构如下：
```sh
.
├── client
├── go.mod
├── proto
└── server
```
### 编译和生成proto文件

#### 创建proto文件
在项目的proto文件夹下新建helloworld.proto文件，其内容如下：
```proto
syntax = "proto3";

package helloworld;

service Greeter {
    rpc SayHello (HelloRequest) returns (HelloResponse) {}
}

message HelloRequest {
    string name = 1;
}

message HelloResponse {
    int64 code = 1;
    string message = 2;
}
```
#### 生成proto文件
在项目根目录下执行如下命令，生成对应.pb.go文件：
```sh
protoc --go_out=plugins=grpc:. ./proto/*.proto
```
- --go_out: 设置生成的go代码的输出目录，该指令通过加载protoc-gen-go插件达到生成go代码的目的，生成的文件以.pb.go为文件后缀，在这里冒号充当分隔符作用，后面跟命令所需的参数集，在这里代表要将所生成的go代码输出到所指向的protoc编译的当前目录
- plugins=plugin1+plugin2: 指定要加载的子插件列表，我们定义的 proto 文件是涉及了 RPC 服务的，而默认是不会生成 RPC 代码的，因此需要在 go_out 中给出 plugins 参数传递给 protoc-gen-go，告诉编译器，请支持 RPC

执行结束后，就会生成proto文件对应的.pb.go文件

#### 生成的.pb.go文件
查看生成的helloworld.pb.go文件，代码如下：
```golang
...
type HelloRequest struct {
	Name                 string   `protobuf:"bytes,1,opt,name=name,proto3" json:"name,omitempty"`
	XXX_NoUnkeyedLiteral struct{} `json:"-"`
	XXX_unrecognized     []byte   `json:"-"`
	XXX_sizecache        int32    `json:"-"`
}

func (m *HelloRequest) Reset()         { *m = HelloRequest{} }
func (m *HelloRequest) String() string { return proto.CompactTextString(m) }
func (*HelloRequest) ProtoMessage()    {}
func (*HelloRequest) Descriptor() ([]byte, []int) {
	return fileDescriptor_4d53fe9c48eadaad, []int{0}
}

func (m *HelloRequest) XXX_Unmarshal(b []byte) error {
	return xxx_messageInfo_HelloRequest.Unmarshal(m, b)
}
func (m *HelloRequest) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	return xxx_messageInfo_HelloRequest.Marshal(b, m, deterministic)
}
func (m *HelloRequest) XXX_Merge(src proto.Message) {
	xxx_messageInfo_HelloRequest.Merge(m, src)
}
func (m *HelloRequest) XXX_Size() int {
	return xxx_messageInfo_HelloRequest.Size(m)
}
func (m *HelloRequest) XXX_DiscardUnknown() {
	xxx_messageInfo_HelloRequest.DiscardUnknown(m)
}

var xxx_messageInfo_HelloRequest proto.InternalMessageInfo

func (m *HelloRequest) GetName() string {
	if m != nil {
		return m.Name
	}
	return ""
}
...
```
HelloRequest其包含了一组Getters方法，能提供取值的方式，并处理了一些空指针取值的情况，还能通过Reset方法重置该参数，而通过ProtoMessage方法，表示这是一个实现了proto.Message的接口，HelloResponse类型也类似。


接下来我们看到.pb.go 文件的初始化方法，其中比较特殊的就是 fileDescriptor 的相关语句，如下：
```golang
func init() {
	proto.RegisterType((*HelloRequest)(nil), "helloworld.HelloRequest")
	proto.RegisterType((*HelloResponse)(nil), "helloworld.HelloResponse")
}

func init() { proto.RegisterFile("proto/helloworld.proto", fileDescriptor_4d53fe9c48eadaad) }

var fileDescriptor_4d53fe9c48eadaad = []byte{
	// 160 bytes of a gzipped FileDescriptorProto
	0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff, 0xe2, 0x12, 0x2b, 0x28, 0xca, 0x2f,
	0xc9, 0xd7, 0xcf, 0x48, 0xcd, 0xc9, 0xc9, 0x2f, 0xcf, 0x2f, 0xca, 0x49, 0xd1, 0x03, 0x0b, 0x08,
	0x71, 0x21, 0x44, 0x94, 0x94, 0xb8, 0x78, 0x3c, 0x40, 0xbc, 0xa0, 0xd4, 0xc2, 0xd2, 0xd4, 0xe2,
	0x12, 0x21, 0x21, 0x2e, 0x96, 0xbc, 0xc4, 0xdc, 0x54, 0x09, 0x46, 0x05, 0x46, 0x0d, 0xce, 0x20,
	0x30, 0x5b, 0xc9, 0x96, 0x8b, 0x17, 0xaa, 0xa6, 0xb8, 0x20, 0x3f, 0xaf, 0x38, 0x15, 0xa4, 0x28,
	0x39, 0x3f, 0x05, 0xa2, 0x88, 0x39, 0x08, 0xcc, 0x16, 0x92, 0xe0, 0x62, 0xcf, 0x4d, 0x2d, 0x2e,
	0x4e, 0x4c, 0x4f, 0x95, 0x60, 0x02, 0xeb, 0x85, 0x71, 0x8d, 0x7c, 0xb8, 0xd8, 0xdd, 0x8b, 0x52,
	0x53, 0x4b, 0x52, 0x8b, 0x84, 0x1c, 0xb9, 0x38, 0x82, 0x13, 0x2b, 0xc1, 0x86, 0x09, 0x49, 0xe8,
	0x21, 0x39, 0x0c, 0xd9, 0x0d, 0x52, 0x92, 0x58, 0x64, 0x20, 0x36, 0x2b, 0x31, 0x24, 0xb1, 0x81,
	0xfd, 0x60, 0x0c, 0x08, 0x00, 0x00, 0xff, 0xff, 0xe6, 0x1d, 0xd3, 0xd5, 0xdd, 0x00, 0x00, 0x00,
}
```
实际上我们所看到的 fileDescriptor_4d53fe9c48eadaad 表示的是一个经过编译后的 proto 文件，是对 proto 文件的整体描述，其包含了 proto 文件名、引用（import）内容、包（package）名、选项设置、所有定义的消息体（message）、所有定义的枚举（enum）、所有定义的服务（ service）、所有定义的方法（rpc method）等等内容，可以认为就是整个 proto 文件的信息你都能够取到

接下来我们再往下看可以看到 GreeterClient 接口，因为 Protobuf 是客户端和服务端可共用一份.proto 文件的，因此除了存在数据描述的信息以外，还会存在客户端和服务端的相关内部调用的接口约束和调用方式的实现，在后续我们在多服务内部调用的时候会经常用到，如下：
```golang
// 客户端接口
type GreeterClient interface {
	SayHello(ctx context.Context, in *HelloRequest, opts ...grpc.CallOption) (*HelloResponse, error)
}

type greeterClient struct {
	cc *grpc.ClientConn
}

func NewGreeterClient(cc *grpc.ClientConn) GreeterClient {
	return &greeterClient{cc}
}

func (c *greeterClient) SayHello(ctx context.Context, in *HelloRequest, opts ...grpc.CallOption) (*HelloResponse, error) {
	out := new(HelloResponse)
	err := c.cc.Invoke(ctx, "/helloworld.Greeter/SayHello", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}
// 服务端注册接口
type GreeterServer interface {
	SayHello(context.Context, *HelloRequest) (*HelloResponse, error)
}

func RegisterGreeterServer(s *grpc.Server, srv GreeterServer) {
	s.RegisterService(&_Greeter_serviceDesc, srv)
}

func _Greeter_SayHello_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(HelloRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(GreeterServer).SayHello(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/helloworld.Greeter/SayHello",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(GreeterServer).SayHello(ctx, req.(*HelloRequest))
	}
	return interceptor(ctx, in, info, handler)
}
```
### 更多数据类型支持
#### 通用类型
在 Protobuf 中一共支持 double、float、int32、int64、uint32、uint64、sint32、sint64、fixed32、fixed64、sfixed32、sfixed64、bool、string、bytes 类型

|.proto Type	|C++ Type	|Java Type	|Go Type	|PHP Type|
|:---:|:---:|:---:|:---:|:---:|
|double	|double	|double	|float64	|float|
|float	|float	|float	|float32	|float|
|int32	|int32	|int	|int32	|integer|
|int64	|int64	|long	|int64	|integer/string|
|uint32	|uint32	|int	|uint32	|integer|
|uint64	|uint64	|long	|uint64	|integer/string|
|sint32	|int32	|int	|int32	|integer|
|sint64	|int64	|long	|int64	|integer/string|
|fixed32	|uint32	|int	|uint32	|integer|
|fixed64	|uint64	|long	|uint64	|integer/string|
|sfixed32	|int32	|int	|int32	|integer|
|sfixed64	|int64	|long	|int64	|integer/string|
|bool	|bool	|boolean	|bool	|boolean|
|string	|string	|String	|string	|string|
|bytes	|string	|ByteString	|[]byte	|string|



常常会遇到需要传递动态数组的情况，在 protobuf 中，我们可以使用 repeated 关键字，如果一个字段被声明为 repeated，那么该字段可以重复任意次（包括零次），重复值的顺序将保留在 protobuf 中，将重复字段视为动态大小的数组，如下:
```proto
message HelloRequest {
  repeated string name = 1;
}
```
#### 嵌套类型
嵌套类型，一共有两种模式，如下：
```proto
message HelloRequest {
    message World {
        string name = 1;
    }
    
    repeated World worlds = 1;
}
```
- 第一种是将 World 消息体定义在 HelloRequest 消息体中，也就是其归属在消息体 HelloRequest 下，若要调用则需要使用 HelloRequest.World 的方式，外部才能引用成功。

- 第二种是将 World 消息体定义在外部，一般比较推荐使用这种方式，清晰、方便，如下：
```proto
message World {
    string name = 1;
}

message HelloRequest {
    repeated World worlds = 1;
}
```
#### oneof 类似union
如果你希望你的消息体可以包含多个字段，但前提条件是最多同时只允许设置一个字段，那么就可以使用 oneof 关键字来实现这个功能，如下：
```proto
message HelloRequest {
    oneof name {
        string nick_name = 1;
        string true_name = 2;
    }
}
```
#### Enum枚举类型
枚举类型，限定你所传入的字段值必须是预定义的值列表之一，如下：
```proto
enum NameType {
    NickName = 0;
    TrueName = 1;
}

message HelloRequest {
    string name = 1;
    NameType nameType = 2;
}
```
#### Map类型
map 类型，需要设置键和值的类型，格式为 map<key_type, value_type> map_field = N;，示例如下：
```proto
message HelloRequest {
    map<string, string> names = 2;
}
```


