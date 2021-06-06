---
title: "服务发现实战之一 consul服务发现构建 Discover Consul in Action"
date: 2021-06-06T10:23:01+08:00
keywords: ["golang", "consul"]
categories: ["golang"]
tags: ["golang", "consul"]
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
### 准备
- ubuntu v20.04
- git
- go v1.16

### 项目结构
```sh
.
├── config
├── discover
├── endpoint
├── go.mod
├── go.sum
├── main.go
├── service
└── transport
```

- transport层 项目提供的服务方式
- endpoint层 用于接收请求并返回响应
- service层 业务代码实现层
- discover 服务发现实现


### 什么是consul？
Consul 是一种服务网格解决方案，提供具有服务发现、配置和分段功能的全功能控制平面。这些功能中的每一个都可以根据需要单独使用，也可以一起使用以构建完整的服务网格。 Consul 需要一个数据平面并支持代理和本地集成模型。 Consul 附带一个简单的内置代理，因此一切都可以开箱即用，而且还支持 第三方方代理集成，例如 Envoy。

Consul 的主要特点是：
- 服务发现：Consul 的客户端可以注册一个服务，例如 api 或 mysql，其他客户端可以使用 Consul 来发现给定服务的提供者。使用 DNS 或 HTTP，应用程序可以轻松找到它们所依赖的服务。
- 健康检查：Consul 客户端可以提供任意数量的健康检查，要么与给定的服务相关（“网络服务器是否返回 200 OK”），要么与本地节点（“内存利用率是否低于 90%”）相关联。操作员可以使用此信息来监控集群健康状况，并且服务发现组件可以使用它来将流量路由到不健康的主机之外。
- KV 存储：应用程序可以将 Consul 的分层键/值存储用于多种目的，包括动态配置、功能标记、协调、领导选举等。简单的 HTTP API 使其易于使用。
- 安全的服务通信：Consul 可以为服务生成和分发 TLS 证书，以建立相互的 TLS 连接。意图可用于定义允许哪些服务进行通信。可以通过实时更改意图轻松管理服务分段，而不是使用复杂的网络拓扑和静态防火墙规则。
- 多数据中心：Consul 支持开箱即用的多个数据中心。这意味着 Consul 的用户不必担心构建额外的抽象层以扩展到多个区域。

### consul的安装和启动

安装方式
- 二进制包[下载](https://www.consul.io/downloads)
- 源码编译

#### 源码编译
```sh
# 将 Consul 存储库从 GitHub 克隆到您的 GOPATH
$ mkdir -p $GOPATH/src/github.com/hashicorp && cd !$
$ git clone https://github.com/hashicorp/consul.git
$ cd consul

# 引导项目。这将下载和编译编译 Consul 所需的库和工具
make tools

# 为您当前的系统构建 Consul 并将二进制文件放入 ./bin/ （相对于 git checkout）。 make dev 目标只是为本地构建环境（没有交叉编译的目标）构建 consul 的快捷方式。
make dev

# 验证安装
consul -v
```

#### 启动consul
```sh
# 启动consul, -dev表示以开发模式启动，该模式下会快速部署一个单节点的consul服务，部署好的节点既是server也是Leader，开发模式启动的consul不会持久化任何数据，数据仅存在内存中。在生产环境中建议使用-server模式启动
consul agent -dev -data-dir=/tmp/consul
```

### 服务注册与发现接口
定义与consul交互的discovery_client接口，/discover/discover_client.go

```go
package discover

import "log"

type DiscoveryClient interface {
	/**
	 * 服务注册接口
	 * @param serviceName 服务名
	 * @param instanceId 服务实例Id
	 * @param instancePort 服务实例端口
	 * @param healthCheckUrl 健康检查地址
	 * @param instanceHost 服务实例地址
	 * @param meta 服务实例元数据
	 */
	Register(serviceName, instanceId, healthCheckUrl string, instanceHost string, instancePort int, meta map[string]string, logger *log.Logger) bool

	/**
	 * 服务注销接口
	 * @param instanceId 服务实例Id
	 */
	DeRegister(instanceId string, logger *log.Logger) bool

	/**
	 * 发现服务实例接口
	 * @param serviceName 服务名
	 */
	DiscoverServices(serviceName string, logger *log.Logger) []interface{}
}

```
利用go-kit实现服务注册与发现接口，/discover/kit_discover_client.go，
先执行go get -u github.com/go-kit/kit/sd/consul github.com/hashicorp/consul/api github.com/hashicorp/consul/api/watch
```go
package discover

import (
	"log"
	"strconv"
	"sync"

	"github.com/go-kit/kit/sd/consul"
	"github.com/hashicorp/consul/api"
	"github.com/hashicorp/consul/api/watch"
)

type KitDiscoverClient struct {
	Addr         string // Consul Host Address
	Port         int    // Consul port
	client       consul.Client
	config       *api.Config // 连接consul的配置
	mutex        sync.Mutex
	instancesMap sync.Map // 服务实例缓存字段
}

func NewKitDiscoverClient(consulAddress string, consulPort int) (DiscoveryClient, error) {
	// 通过consul host和consul port创建一个consul.Client
	consulConfig := api.DefaultConfig()
	consulConfig.Address = consulAddress + ":" + strconv.Itoa(consulPort)
	apiClient, err := api.NewClient(consulConfig)
	if err != nil {
		return nil, err
	}
	client := consul.NewClient(apiClient)
	return &KitDiscoverClient{
		Addr:   consulAddress,
		Port:   consulPort,
		config: consulConfig,
		client: client,
	}, err
}

func (k *KitDiscoverClient) Register(
	serviceName, instanceId, healthCheckUrl string,
	instanceAddress string,
	instancePort int,
	meta map[string]string,
	logger *log.Logger) bool {
	// 构建服务实例元数据
	serviceRegisteration := &api.AgentServiceRegistration{
		ID:      instanceId,
		Name:    serviceName,
		Address: instanceAddress,
		Port:    instancePort,
		Meta:    meta,
		Check: &api.AgentServiceCheck{
			DeregisterCriticalServiceAfter: "30s",
			HTTP:                           "http://" + instanceAddress + ":" + strconv.Itoa(instancePort) + healthCheckUrl,
			Interval:                       "15s",
		},
	}

	// 发送服务注册到consul 中
	err := k.client.Register(serviceRegisteration)
	if err != nil {
		log.Println("Register Service Error!")
		return false
	}
	log.Println("Register Service Success!")
	return true
}

func (k *KitDiscoverClient) DeRegister(instanceId string, logger *log.Logger) bool {
	// 构建包含服务实例 ID 的元数据结构体
	serviceRegisteration := &api.AgentServiceRegistration{
		ID: instanceId,
	}
	// 发送服务注销请求
	err := k.client.Deregister(serviceRegisteration)
	if err != nil {
		logger.Println("DeRegister Service Error!")
		return false
	}
	log.Println("Register Service Success!")
	return true
}

func (k *KitDiscoverClient) DiscoverServices(serviceName string, logger *log.Logger) []interface{} {
	// 该服务已监控并缓存
	instanceList, ok := k.instancesMap.Load(serviceName)
	if ok {
		return instanceList.([]interface{})
	}
	// 申请锁
	k.mutex.Lock()
	defer k.mutex.Unlock()
	// 再次检查是否监控
	instanceList, ok = k.instancesMap.Load(serviceName)
	if ok {
		return instanceList.([]interface{})
	} else {
		// 注册监控
		go func() {
			// 使用consul服务实例监控来监控某个服务名的服务实例列表变化
			params := make(map[string]interface{})
			params["type"] = "service"
			params["service"] = serviceName
			plan, _ := watch.Parse(params)
			plan.Handler = func(u uint64, i interface{}) {
				if i == nil {
					return
				}
				v, ok := i.([]*api.ServiceEntry)
				if !ok {
					return // 数据异常，忽略
				}
				// 没有服务实例在线
				if len(v) == 0 {
					k.instancesMap.Store(serviceName, []interface{}{})
				}
				var healthServices []interface{}
				for _, service := range v {
					if service.Checks.AggregatedStatus() == api.HealthPassing {
						healthServices = append(healthServices, service.Service)
					}
				}
				k.instancesMap.Store(serviceName, healthServices)
			}
			defer plan.Stop()
			plan.Run(k.config.Address)
		}()
	}

	// 根据服务名请求服务实例列表
	entries, _, err := k.client.Service(serviceName, "", false, nil)
	if err != nil {
		k.instancesMap.Store(serviceName, []interface{}{})
		logger.Println("Discover Service Error!")
		return nil
	}
	instances := make([]interface{}, len(entries))
	for i := 0; i < len(instances); i++ {
		instances[i] = entries[i].Service
	}
	k.instancesMap.Store(serviceName, instances)
	return instances
}

```
### 配置信息代码实现
定义日志信息，/config/config.go

先执行go get -u github.com/go-kit/kit/log
```go
package config

import (
	kitlog "github.com/go-kit/kit/log"
	"log"
	"os"
)


var Logger *log.Logger
var KitLogger kitlog.Logger


func init() {
	Logger = log.New(os.Stderr, "", log.LstdFlags)

	KitLogger = kitlog.NewLogfmtLogger(os.Stderr)
	KitLogger = kitlog.With(KitLogger, "ts", kitlog.DefaultTimestampUTC)
	KitLogger = kitlog.With(KitLogger, "caller", kitlog.DefaultCaller)

}

```


### 代码实现
定义项目提供的服务接口，/service/service.go

```go
package service

import (
	"context"
	"errors"

	"github.com/realjf/consul-in-action/config"
	"github.com/realjf/consul-in-action/discover"
)


type Service interface {
	// 健康检查接口
	HealthCheck() bool

	// 打招呼接口
	SayHello() string

	// 服务发现接口
	DiscoveryService(ctx context.Context, serviceName string) ([]interface{}, error)
}
```
接口实现
```go
var ErrNotDiscoveryService = errors.New("discovery service not found")

type discoveryService struct {
	discoveryClient discover.DiscoveryClient
}

func NewDiscoveryService(discoveryClient discover.DiscoveryClient) DiscoveryService {
	return &discoveryService{
		discoveryClient: discoveryClient,
	}
}

func (s *discoveryService) SayHello() string {
	return "Hello World"
}

// 从consul中根据服务名获取对应的服务实例信息列表并返回
func (s *discoveryService) DiscoveryService(ctx context.Context, serviceName string) ([]interface{}, error) {
	ins := s.discoveryClient.DiscoverServices(serviceName, config.Logger)

	if ins == nil || len(ins) == 0 {
		return nil, ErrNotDiscoveryService
	}
	return ins, nil
}

func (s *discoveryService) HealthCheck() bool {
	return true
}

```
endpoint层 将请求转化为服务接口可以处理的参数，并将结果封装为response返回给transport层。
首先执行go get -u github.com/go-kit/kit/endpoint，然后实现
endpoint层代码/endpoint/endpoints.go，
```go
package endpoint

import (
	"context"

	"github.com/go-kit/kit/endpoint"
	"github.com/realjf/consul-in-action/service"
)

// 定义服务发现endpoint结构
type DiscoveryEndpoints struct {
	SayHelloEndpoint    endpoint.Endpoint
	DiscoveryEndpoint   endpoint.Endpoint
	HealthCheckEndpoint endpoint.Endpoint
}
// 然后实现sayHello请求：包括请求结构体、响应结构体和创建方法
type SayHelloRequest struct {
}

type SayHelloResponse struct {
	Message string `json"message"`
}

func NewSayHelloEndpoint(svc service.DiscoveryService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (response interface{}, err error) {
		message := svc.SayHello()
		return SayHelloResponse{
			Message: message,
		}, nil
	}
}

// 实现服务发现请求：请求结构体、响应结构体和创建方法
type DiscoveryRequest struct {
	ServiceName string
}

type DiscoveryResponse struct {
	Instances []interface{} `json:"instances"`
	Error     string        `json:"error"`
}

func NewDiscoveryEndpoint(svc service.DiscoveryService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (response interface{}, err error) {
		req := request.(DiscoveryRequest)
		instances, err := svc.DiscoveryService(ctx, req.ServiceName)
		var errString = ""
		if err != nil {
			errString = err.Error()
		}
		return &DiscoveryResponse{
			Instances: instances,
			Error:     errString,
		}, nil
	}
}

// 实现健康检查请求：请求结构体、响应结构体和创建方法
type HealthCheckRequest struct {
}

type HealthCheckResponse struct {
	Status bool `json:"status"`
}

func NewHealthCheckEndpoint(svc service.DiscoveryService) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (response interface{}, err error) {
		status := svc.HealthCheck()
		return HealthCheckResponse{
			Status: status,
		}, nil
	}
}
```
transport层 对外暴露http服务，将endpoint包中的Endpoint与对应http路径进行绑定。
先执行go get -u github.com/gorilla/mux github.com/go-kit/kit/transport/http github.com/go-kit/kit/transport github.com/go-kit/kit/log，
然后代码实现/transport/http.go
```go
package transport

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"

	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/transport"
	kithttp "github.com/go-kit/kit/transport/http"
	"github.com/gorilla/mux"
	"github.com/realjf/consul-in-action/endpoint"
)

var (
	ErrBadRequest = errors.New("invalid parameters")
)

func errorEncoder(ctx context.Context, err error, w http.ResponseWriter) {
	w.WriteHeader(http.StatusInternalServerError)
	fmt.Fprintf(w, `{"error":"%s"}\n`, err.Error()) // or whatever
}

func NewHttpHandler(ctx context.Context, endpoints endpoint.DiscoveryEndpoints, logger log.Logger) http.Handler {
	r := mux.NewRouter()

	options := []kithttp.ServerOption{
		kithttp.ServerErrorHandler(transport.NewLogErrorHandler(logger)),
		kithttp.ServerErrorEncoder(errorEncoder),
	}

	r.Methods("GET").Path("/say-hello").Handler(kithttp.NewServer(
		endpoints.SayHelloEndpoint,
		decodeSayHelloRequest,
		encodeJsonResponse,
		options...,
	))

	r.Methods("GET").Path("/discovery").Handler(kithttp.NewServer(
		endpoints.DiscoveryEndpoint,
		decodeDiscoveryRequest,
		encodeJsonResponse,
		options...,
	))

	r.Methods("GET").Path("/health").Handler(kithttp.NewServer(
		endpoints.HealthCheckEndpoint,
		decodeHealthCheckRequest,
		encodeJsonResponse,
		options...,
	))

	return r
}

// decodeXXXRequest将http请求转化为endpoint可处理的request请求体
func decodeSayHelloRequest(_ context.Context, r *http.Request) (interface{}, error) {
	return endpoint.SayHelloRequest{}, nil
}

func decodeDiscoveryRequest(_ context.Context, r *http.Request) (interface{}, error) {
	serviceName := r.URL.Query().Get("serviceName")
	if serviceName == "" {
		return nil, ErrBadRequest
	}
	return endpoint.DiscoveryRequest{
		ServiceName: serviceName,
	}, nil
}

func decodeHealthCheckRequest(_ context.Context, r *http.Request) (interface{}, error) {
	return endpoint.HealthCheckRequest{}, nil
}

// encodeJsonResponse将返回的response转化为json格式
func encodeJsonResponse(ctx context.Context, w http.ResponseWriter, response interface{}) error {
	w.Header().Set("Content-Type", "application/json;charset=utf-8")
	return json.NewEncoder(w).Encode(response)
}

```
最后实现main函数，先执行go get -u github.com/satori/go.uuid
```go
package main

import (
	"context"
	"flag"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"

	"github.com/realjf/consul-in-action/config"
	"github.com/realjf/consul-in-action/discover"
	"github.com/realjf/consul-in-action/endpoint"
	"github.com/realjf/consul-in-action/service"
	"github.com/realjf/consul-in-action/transport"

	uuid "github.com/satori/go.uuid"
)

func main() {
	var (
		// 服务地址和服务名
		servicePort = flag.Int("service.port", 12000, "service port")
		serviceHost = flag.String("service.host", "127.0.0.1", "service host")
		serviceName = flag.String("service.name", "SayHello", "service name")
		// consul 地址
		consulPort    = flag.Int("consul.port", 8500, "consul port")
		consulAddress = flag.String("consul.host", "127.0.0.1", "consul host address")
	)
	flag.Parse()

	ctx := context.Background()
	errChan := make(chan error)

	// 声明服务发现客户端
	var discoveryClient discover.DiscoveryClient

	discoveryClient, err := discover.NewKitDiscoverClient(*consulAddress, *consulPort)
	// 获取服务发现客户端失败，直接关闭服务
	if err != nil {
		config.Logger.Println("Get Consul Client failed")
		os.Exit(-1)
	}

	// 声明并初始化 Service
	var svc = service.NewDiscoveryService(discoveryClient)

	// 创建Endpoint
	sayHelloEndpoint := endpoint.NewSayHelloEndpoint(svc)
	discoveryEndpoint := endpoint.NewDiscoveryEndpoint(svc)
	healthCheckEndpoint := endpoint.NewHealthCheckEndpoint(svc)

	endpoints := endpoint.DiscoveryEndpoints{
		SayHelloEndpoint:    sayHelloEndpoint,
		DiscoveryEndpoint:   discoveryEndpoint,
		HealthCheckEndpoint: healthCheckEndpoint,
	}

	// 创建http.Handler
	r := transport.NewHttpHandler(ctx, endpoints, config.KitLogger)
	// 定义服务实例ID
	instanceId := *serviceName + "-" + uuid.NewV4().String()
	// 启动http server
	go func() {
		config.Logger.Println("Http Server start at port:" + strconv.Itoa(*servicePort))
		// 启动前执行注册
		if !discoveryClient.Register(*serviceName, instanceId, "/health", *serviceHost, *servicePort, nil, config.Logger) {
			config.Logger.Printf("string-service for service %s failed.", serviceName)
			// 注册失败，服务启动失败
			os.Exit(-1)
		}
		handler := r
		errChan <- http.ListenAndServe(":"+strconv.Itoa(*servicePort), handler)
	}()

	go func() {
		// 监控系统信号，等待ctrl + c 系统信号通知服务关闭
		c := make(chan os.Signal, 1)
		signal.Notify(c, syscall.SIGINT, syscall.SIGTERM)
		errChan <- fmt.Errorf("%s", <-c)
	}()

	error := <-errChan
	// 服务退出取消注册
	discoveryClient.DeRegister(instanceId, config.Logger)
	config.Logger.Println(error)
}

```
之后启动consul，然后，运行服务go run main.go，打开浏览器：http://localhost:8500查看consul服务信息，
服务发现地址：http://localhost:12000/discovery?serviceName=SayHello
