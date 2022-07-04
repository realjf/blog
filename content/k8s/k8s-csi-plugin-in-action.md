---
title: "K8s CSI插件开发实战 K8s CSI Plugin Development in Action"
date: 2022-07-04T11:08:22+08:00
keywords: ["k8s", "csi"]
categories: ["k8s"]
tags: ["k8s", "csi"]
series: ["csi"]
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

## 准备
- kubernetes集群（1.15.5以上版本）
- go开发环境

## 开始

### 项目构建
我们需要开发CSI spec中规定的两个插件程序：
- Node Plugin
  - 在每个节点上运行, 作为一个grpc端点服务于CSI的RPCs,执行具体的挂卷操作。
- Controller Plugin
  - 同样为CSI RPCs服务,可以在任何地方运行,一般执行全局性的操作,比如创建/删除网络卷。
  
按照规范应该是两独立的程序，但这里为了简单会在一个程序里实现spec规定的所有gRPC服务

CSI有三种RPC：
- 身份服务：Node Plugin和Controller Plugin都必须实现这些RPC
- 控制器服务：Controller Plugin必须实现这些RPC
- 节点服务：Node Plugin必须实现这些RPC

首先构建程序目录
```sh
mkdir fsd-plugin && cd fsd-plugin
mkdir -p {cmd,bin,pkg/fsd} deploy/{kubernetes,examples}
```

创建文件：
```sh
touch pkg/fsd/{controllerserver.go,identityserver.go,nodeserver.go}
```

创建程序主函数和初始化所需要用到的两个文件
```sh
touch cmd/main.go pkg/fsd/driver.go
```

创建go mod包管理
```
go mod init fsd-csi-driver
```

最后目录结构如下：
```sh
.
├── bin
│   ├── controllerplugin.go
│   └── nodeplugin.go
├── cmd
├── deploy
│   ├── examples
│   └── kubernetes
├── go.mod
└── pkg
    └── fsd
        ├── controllerserver.go
        ├── driver.go
        ├── identityserver.go
        └── nodeserver.go
```

### 编写代码逻辑

```sh
go get github.com/container-storage-interface/spec
go get k8s.io/klog
```
**identityserver.go实现**
```go
package fsd

import (
	"context"

	"github.com/container-storage-interface/spec/lib/go/csi"
	"k8s.io/klog"
)

type IdentityServer struct {
}

func NewIdentityServer() *IdentityServer {
	return &IdentityServer{}
}

// GetPluginInfo 返回插件信息
func (ids *IdentityServer) GetPluginInfo(ctx context.Context, req *csi.GetPluginInfoRequest) (*csi.GetPluginInfoResponse, error) {
	klog.V(4).Infof("GetPluginInfo: called with args %+v", *req)

	return &csi.GetPluginInfoResponse{
		Name:          driverName,
		VendorVersion: version,
	}, nil
}

// GetPluginCapabilities 返回插件支持的功能
func (ids *IdentityServer) GetPluginCapabilities(ctx context.Context, req *csi.GetPluginCapabilitiesRequest) (*csi.GetPluginCapabilitiesResponse, error) {
	klog.V(4).Infof("GetPluginCapabilities: called with args %+v", *req)

	resp := &csi.GetPluginCapabilitiesResponse{
		Capabilities: []*csi.PluginCapability{
			{
				Type: &csi.PluginCapability_Service_{
					Service: &csi.PluginCapability_Service{
						Type: csi.PluginCapability_Service_CONTROLLER_SERVICE,
					},
				},
			},
			{
				Type: &csi.PluginCapability_Service_{
					Service: &csi.PluginCapability_Service{
						Type: csi.PluginCapability_Service_VOLUME_ACCESSIBILITY_CONSTRAINTS,
					},
				},
			},
		},
	}

	return resp, nil
}

// Probe 插件健康检测
func (ids *IdentityServer) Probe(ctx context.Context, req *csi.ProbeRequest) (*csi.ProbeResponse, error) {
	klog.V(4).Infof("Probe: called with args %+v", *req)
	return &csi.ProbeResponse{}, nil
}

```
**controllerserver.go实现**
```sh
go get google.golang.org/grpc
```
代码如下：
```go
package fsd

import (
	"context"

	"github.com/container-storage-interface/spec/lib/go/csi"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"k8s.io/klog"
)

var (
	// controllerCaps 代表Controller Plugin支持的功能，可选类型见https://github.com/container-storage-interface/spec/blob/4731db0e0bc53238b93850f43ab05d9355df0fd9/lib/go/csi/csi.pb.go#L181:6
	// 这里只实现Volume的创建/删除，附加/卸载
	controllerCaps = []csi.ControllerServiceCapability_RPC_Type{
		csi.ControllerServiceCapability_RPC_CREATE_DELETE_VOLUME,
		csi.ControllerServiceCapability_RPC_PUBLISH_UNPUBLISH_VOLUME,
	}
)

type ControllerServer struct{}

func NewControllerServer() *ControllerServer {
	return &ControllerServer{}
}

// ControllerGetCapabilities 返回Controller Plugin支持的功能
func (cs *ControllerServer) ControllerGetCapabilities(ctx context.Context, req *csi.ControllerGetCapabilitiesRequest) (*csi.ControllerGetCapabilitiesResponse, error) {
	klog.V(4).Infof("ControllerGetCapabilities: called with args %+v", *req)

	var caps []*csi.ControllerServiceCapability
	for _, cap := range controllerCaps {
		c := &csi.ControllerServiceCapability{
			Type: &csi.ControllerServiceCapability_Rpc{
				Rpc: &csi.ControllerServiceCapability_RPC{
					Type: cap,
				},
			},
		}
		caps = append(caps, c)
	}
	return &csi.ControllerGetCapabilitiesResponse{Capabilities: caps}, nil
}

// CreateVolume 创建
func (cs *ControllerServer) CreateVolume(ctx context.Context, req *csi.CreateVolumeRequest) (*csi.CreateVolumeResponse, error) {
	klog.V(4).Infof("CreateVolume: called with args %+v", *req)

	// 这里先返回一个假数据，模拟我们创建出了一块id为"qcow-1234567"容量为20G的云盘
	return &csi.CreateVolumeResponse{
		Volume: &csi.Volume{
			VolumeId:      "qcow-1234567",
			CapacityBytes: 20 * (1 << 30),
			VolumeContext: req.GetParameters(),
		},
	}, nil
}

// DeleteVolume 删除
func (cs *ControllerServer) DeleteVolume(ctx context.Context, req *csi.DeleteVolumeRequest) (*csi.DeleteVolumeResponse, error) {
	klog.V(4).Infof("DeleteVolume: called with args: %+v", *req)
	return &csi.DeleteVolumeResponse{}, nil
}

// ControllerGetVolume 获取
func (cs *ControllerServer) ControllerGetVolume(ctx context.Context, req *csi.ControllerGetVolumeRequest) (*csi.ControllerGetVolumeResponse, error) {
	klog.V(4).Infof("ControllerGetVolume: called with args: %+v", *req)
	return &csi.ControllerGetVolumeResponse{}, nil
}

// ControllerPublishVolume 附加
func (cs *ControllerServer) ControllerPublishVolume(ctx context.Context, req *csi.ControllerPublishVolumeRequest) (*csi.ControllerPublishVolumeResponse, error) {
	klog.V(4).Infof("ControllerPublishVolume: called with args %+v", *req)
	pvInfo := map[string]string{DevicePathKey: "/dev/sdb"}
	return &csi.ControllerPublishVolumeResponse{PublishContext: pvInfo}, nil
}

// ControllerUnpublishVolume 卸载
func (cs *ControllerServer) ControllerUnpublishVolume(ctx context.Context, req *csi.ControllerUnpublishVolumeRequest) (*csi.ControllerUnpublishVolumeResponse, error) {
	klog.V(4).Infof("ControllerUnpublishVolume: called with args %+v", *req)
	return &csi.ControllerUnpublishVolumeResponse{}, nil
}

// TODO(xnile): implement this
func (cs *ControllerServer) ValidateVolumeCapabilities(ctx context.Context, req *csi.ValidateVolumeCapabilitiesRequest) (*csi.ValidateVolumeCapabilitiesResponse, error) {
	return nil, status.Error(codes.Unimplemented, "")
}

func (cs *ControllerServer) ListVolumes(ctx context.Context, req *csi.ListVolumesRequest) (*csi.ListVolumesResponse, error) {
	return nil, status.Error(codes.Unimplemented, "")
}

func (cs *ControllerServer) GetCapacity(ctx context.Context, req *csi.GetCapacityRequest) (*csi.GetCapacityResponse, error) {
	return nil, status.Error(codes.Unimplemented, "")
}

func (cs *ControllerServer) CreateSnapshot(ctx context.Context, req *csi.CreateSnapshotRequest) (*csi.CreateSnapshotResponse, error) {
	return nil, status.Error(codes.Unimplemented, "")
}

func (cs *ControllerServer) DeleteSnapshot(ctx context.Context, req *csi.DeleteSnapshotRequest) (*csi.DeleteSnapshotResponse, error) {
	return nil, status.Error(codes.Unimplemented, "")
}

func (cs *ControllerServer) ListSnapshots(ctx context.Context, req *csi.ListSnapshotsRequest) (*csi.ListSnapshotsResponse, error) {
	return nil, status.Error(codes.Unimplemented, "")
}

func (cs *ControllerServer) ControllerExpandVolume(ctx context.Context, req *csi.ControllerExpandVolumeRequest) (*csi.ControllerExpandVolumeResponse, error) {
	return nil, status.Error(codes.Unimplemented, "")
}

```

**nodeserver.go实现**
```sh
go get -u k8s.io/kubernetes
```
代码如下：
```go
package fsd

import (
	// "fmt"
	// "os"

	"github.com/container-storage-interface/spec/lib/go/csi"
	"context"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"k8s.io/klog"
	"k8s.io/kubernetes/pkg/util/mount"
)

type nodeServer struct {
	nodeID  string
	mounter mount.SafeFormatAndMount
}

func NewNodeServer(nodeid string) *nodeServer {
	return &nodeServer{
		nodeID: nodeid,
		mounter: mount.SafeFormatAndMount{
			Interface: mount.New(""),
			Exec:      mount.NewOsExec(),
		},
	}
}

// NodeStageVolume 格式化硬盘，Mount到全局目录
func (ns *nodeServer) NodeStageVolume(ctx context.Context, req *csi.NodeStageVolumeRequest) (*csi.NodeStageVolumeResponse, error) {
	klog.V(4).Infof("NodeStageVolume: called with args %+v", *req)

	return &csi.NodeStageVolumeResponse{}, nil
}

func (ns *nodeServer) NodeUnstageVolume(ctx context.Context, req *csi.NodeUnstageVolumeRequest) (*csi.NodeUnstageVolumeResponse, error) {
	klog.V(4).Infof("NodeUnstageVolume: called with args %+v", *req)

	return &csi.NodeUnstageVolumeResponse{}, nil
}

//NodePublishVolume 从全局目录mount到目标目录(后续将映射到Pod中)
func (ns *nodeServer) NodePublishVolume(ctx context.Context, req *csi.NodePublishVolumeRequest) (*csi.NodePublishVolumeResponse, error) {
	klog.V(4).Infof("NodePublishVolume: called with args %+v", *req)

	return &csi.NodePublishVolumeResponse{}, nil
}

func (ns *nodeServer) NodeUnpublishVolume(ctx context.Context, req *csi.NodeUnpublishVolumeRequest) (*csi.NodeUnpublishVolumeResponse, error) {
	klog.V(4).Infof("NodeUnpublishVolume: called with args %+v", *req)

	return &csi.NodeUnpublishVolumeResponse{}, nil
}

// NodeGetInfo 返回节点信息
func (ns *nodeServer) NodeGetInfo(ctx context.Context, req *csi.NodeGetInfoRequest) (*csi.NodeGetInfoResponse, error) {
	klog.V(4).Infof("NodeGetInfo: called with args %+v", *req)

	return &csi.NodeGetInfoResponse{
		NodeId: ns.nodeID,
	}, nil
}

// NodeGetCapabilities 返回节点支持的功能
func (ns *nodeServer) NodeGetCapabilities(ctx context.Context, req *csi.NodeGetCapabilitiesRequest) (*csi.NodeGetCapabilitiesResponse, error) {
	klog.V(4).Infof("NodeGetCapabilities: called with args %+v", *req)

	return &csi.NodeGetCapabilitiesResponse{
		Capabilities: []*csi.NodeServiceCapability{
			{
				Type: &csi.NodeServiceCapability_Rpc{
					Rpc: &csi.NodeServiceCapability_RPC{
						Type: csi.NodeServiceCapability_RPC_STAGE_UNSTAGE_VOLUME,
					},
				},
			},
		},
	}, nil
}

func (ns *nodeServer) NodeGetVolumeStats(ctx context.Context, in *csi.NodeGetVolumeStatsRequest) (*csi.NodeGetVolumeStatsResponse, error) {
	return nil, status.Error(codes.Unimplemented, "")
}

func (ns *nodeServer) NodeExpandVolume(ctx context.Context, req *csi.NodeExpandVolumeRequest) (*csi.NodeExpandVolumeResponse, error) {
	return nil, status.Error(codes.Unimplemented, "")
}

```


**driver.go实现**
```sh
go get github.com/container-storage-interface/spec
go get github.com/kubernetes-csi/csi-lib-utils
```
代码如下：
```go
package fsd

import (
	"context"
	"fmt"
	"net"
	"os"
	"strings"

	"github.com/container-storage-interface/spec/lib/go/csi"
	"github.com/kubernetes-csi/csi-lib-utils/protosanitizer"
	"google.golang.org/grpc"
	"k8s.io/klog"
)

type Driver struct {
	nodeID   string
	endpoint string
}

const (
	version       = "1.0.0"
	driverName    = "fsd.csi.realjf.com"
	DevicePathKey = "devicePath"
)

func NewDriver(nodeID, endpoint string) *Driver {
	klog.V(4).Infof("Driver: %v version: %v", driverName, version)

	n := &Driver{
		nodeID:   nodeID,
		endpoint: endpoint,
	}

	return n
}

func (d *Driver) Run() {

	ctl := NewControllerServer()
	identity := NewIdentityServer()
	node := NewNodeServer(d.nodeID)

	opts := []grpc.ServerOption{
		grpc.UnaryInterceptor(logGRPC),
	}

	srv := grpc.NewServer(opts...)

	csi.RegisterControllerServer(srv, ctl)
	csi.RegisterIdentityServer(srv, identity)
	csi.RegisterNodeServer(srv, node)

	proto, addr, err := ParseEndpoint(d.endpoint)
	klog.V(4).Infof("protocol: %s,addr: %s", proto, addr)
	if err != nil {
		klog.Fatal(err.Error())
	}

	if proto == "unix" {
		addr = "/" + addr
		if err := os.Remove(addr); err != nil && !os.IsNotExist(err) {
			klog.Fatalf("Failed to remove %s, error: %s", addr, err.Error())
		}
	}

	listener, err := net.Listen(proto, addr)
	if err != nil {
		klog.Fatalf("Failed to listen: %v", err)
	}

	srv.Serve(listener)
}

func logGRPC(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
	klog.V(4).Infof("GRPC call: %s", info.FullMethod)
	klog.V(4).Infof("GRPC request: %s", protosanitizer.StripSecrets(req))
	resp, err := handler(ctx, req)
	if err != nil {
		klog.Errorf("GRPC error: %v", err)
	} else {
		klog.V(4).Infof("GRPC response: %s", protosanitizer.StripSecrets(resp))
	}
	return resp, err
}

func ParseEndpoint(ep string) (string, string, error) {
	if strings.HasPrefix(strings.ToLower(ep), "unix://") || strings.HasPrefix(strings.ToLower(ep), "tcp://") {
		s := strings.SplitN(ep, "://", 2)
		if s[1] != "" {
			return s[0], s[1], nil
		}
	}
	return "", "", fmt.Errorf("Invalid endpoint: %v", ep)
}

```
**main.go实现**
```go
package main

import (
	"flag"
	"fsd-csi-driver/pkg/fsd"

	"k8s.io/klog"
)

var (
	endpoint string
	nodeID   string
)

func main() {
	flag.StringVar(&endpoint, "endpoint", "", "CSI Endpoint")
	flag.StringVar(&nodeID, "nodeid", "", "node id")

	klog.InitFlags(nil)
	flag.Parse()

	d := fsd.NewDriver(nodeID, endpoint)
	d.Run()
}

```

### 编译
```sh
CGO_ENABLED=0 GOOS=linux go build -o ./bin/fsd-csi-driver ./cmd
```

### 构建docker镜像
bin/Dockerfile
```dockerfile
FROM alpine

LABEL maintainers="realjf"
LABEL description="FSD CSI Driver"

RUN apk add util-linux e2fsprogs
COPY fsd-csi-driver /fsd-csi-driver 

ENTRYPOINT ["/fsd-csi-driver"]
```

构建
```sh
docker build -t realjf/fsd-csi-driver:v0.1 .
docker push realjf/fsd-csi-driver:v0.1
```

### 部署
#### RBAC
授权驱动程序操作相关api的权限
deploy/kubernetes/rbac.yaml
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fsd-csi-driver
  namespace: csi-dev

---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: fsd-csi-driver
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "update", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["csinodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "watch", "list", "delete", "update", "create"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "watch", "list", "delete", "update", "create"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["csi.storage.k8s.io"]
    resources: ["csinodeinfos"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["volumeattachments"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshotclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshotcontents"]
    verbs: ["create", "get", "list", "watch", "update", "delete"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshots"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["apiextensions.k8s.io"]
    resources: ["customresourcedefinitions"]
    verbs: ["create", "list", "watch", "delete"]

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: fsd-csi-driver
subjects:
  - kind: ServiceAccount
    name: fsd-csi-driver
    namespace: csi-dev
roleRef:
  kind: ClusterRole
  name: fsd-csi-driver
  apiGroup: rbac.authorization.k8s.io
```
```sh
kubectl apply -f deploy/kubernetes/rbac.yaml
```
#### 部署驱动
deploy/kubernetes/fsd-csi-driver.yaml
```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: fsd-csi-driver
  namespace: csi-dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fsd-csi-driver
  template:
    metadata:
      labels:
        app: fsd-csi-driver
    spec:
      nodeSelector:
        kubernetes.io/hostname: knode02
      serviceAccount: fsd-csi-driver
      containers:
        #plugin
        - name: fsd-csi-driver
          image: realjf/fsd-csi-driver:v0.1
          args:
            - --endpoint=$(CSI_ENDPOINT)
            - --nodeid=$(KUBE_NODE_NAME)
            - --logtostderr
            - --v=5
          env:
            - name: CSI_ENDPOINT
              value: unix:///csi/csi.sock
            - name: KUBE_NODE_NAME
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: spec.nodeName
          securityContext:
            privileged: true
          volumeMounts:
            - name: kubelet-dir
              mountPath: /var/lib/kubelet
              mountPropagation: "Bidirectional"
            - name: plugin-dir
              mountPath: /csi
            - name: device-dir
              mountPath: /dev
        #Sidecar:node-driver-registrar
        - name: node-driver-registrar
          image: quay.io/k8scsi/csi-node-driver-registrar:v1.2.0
          args:
            - --csi-address=$(ADDRESS)
            - --kubelet-registration-path=$(DRIVER_REG_SOCK_PATH)
            - --v=5
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sh", "-c", "rm -rf /registration/fsd.csi.realjf.com-reg.sock /csi/csi.sock"]
          env:
            - name: ADDRESS
              value: /csi/csi.sock
            - name: DRIVER_REG_SOCK_PATH
              value: /var/lib/kubelet/plugins/fsd.csi.realjf.com/csi.sock
          volumeMounts:
            - name: plugin-dir
              mountPath: /csi
            - name: registration-dir
              mountPath: /registration
        #Sidecar: livenessprobe
        - name: liveness-probe
          image: quay.io/k8scsi/livenessprobe:v1.1.0
          args:
            - "--csi-address=/csi/csi.sock"
            - "--v=5"
          volumeMounts:
            - name: plugin-dir
              mountPath: /csi
        #Sidecar: csi-provisione
        - name: csi-provisioner
          image: quay.io/k8scsi/csi-provisioner:v1.3.1
          args:
            - "--csi-address=$(ADDRESS)"
            - "--v=5"
            - "--feature-gates=Topology=True"
          env:
            - name: ADDRESS
              value: unix:///csi/csi.sock
          imagePullPolicy: "IfNotPresent"
          volumeMounts:
            - name: plugin-dir
              mountPath: /csi
        #Sidecar: csi-attacher
        - name: csi-attacher
          image: quay.io/k8scsi/csi-attacher:v1.2.1
          args:
            - "--v=5"
            - "--csi-address=$(ADDRESS)"
          env:
            - name: ADDRESS
              value: /csi/csi.sock
          imagePullPolicy: "Always"
          volumeMounts:
            - name: plugin-dir
              mountPath: /csi
      volumes:
        - name: kubelet-dir
          hostPath:
            path: /var/lib/kubelet
            type: Directory
        - name: plugin-dir
          hostPath:
            path: /var/lib/kubelet/plugins/fsd.csi.realjf.com/
            type: DirectoryOrCreate
        - name: registration-dir
          hostPath:
            path: /var/lib/kubelet/plugins_registry/
            type: Directory
        - name: device-dir
          hostPath:
            path: /dev
            type: Directory
```

```sh
kubectl apply -f deploy/kubernetes/fsd-csi-driver.yaml
```
#### 验证插件运行状态
查看pod状态
```sh
kubectl get pods -L app=fsd-csi-driver
```
查看插件log
```sh
kubectl logs -f fsd-csi-driver-xxxxxxxxxx -c fsd-csi-driver
```
查看CSINode信息
```sh
kubectl get csinodes knode02 -o yaml
```

### 测试
接下来我们来创建一个测试Pod来验证下驱动程序能否为Pod完成Volume的创建、附加、挂载等操作。当然这里Volume的创建、附加、挂载都只是模拟，其实可以把这些操作做成一个webhook供csi驱动调用，类似公有云提供的相关api一样，这样就可以模拟真实的创建、附加、挂载等操作，有兴趣的朋友可以自己实现。

**StorageClass**
deploy/examples/storageclass.yaml
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: fsd-csi
provisioner: fsd.csi.realjf.com
```
```sh
kubectl apply -f deploy/examples/storageclass.yaml
```
```sh
kubectl get sc
```
**PVC**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fsd-csi-pvc-01
  namespace: csi-dev
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: fsd-csi
```
```sh
kubectl apply -f deploy/examples/pvc.yaml
```
验证
```sh
kubectl get pv
kubectl get pvc
```
查看程序log
```sh

```
测试使用pvc
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test-csi-pvc
  namespace: csi-dev
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      nodeSelector:
        kubernetes.io/hostname: knode02
      containers:
      - name: nginx
        image: nginx:1.17
        ports:
        - containerPort: 80
        volumeMounts:
          - name: data
            mountPath: "/data"
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: fsd-csi-pvc-01
```
```sh
kubectl apply -f deploy/examples/nginx.yaml
```
查看pod状态
```sh
kubectl get pod -l app=nginx
```
查看pod信息
```sh
kubectl describe pod nginx-test-csi-pvc-xxxxxxxxxxxxx
```
查看节点信息
```sh
kubectl get no knode02 -o yaml
```

查看插件log
```sh

```

### 调试工具
**CSC**

安装
```sh
GO111MODULE=off go get -u github.com/rexray/gocsi/csc
```




