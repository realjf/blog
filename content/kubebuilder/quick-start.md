---
title: "kubebuilder快速开始 Kubebuilder Quick Start"
date: 2021-04-04T10:47:04+08:00
keywords: ["kubebuilder"]
categories: ["kubebuilder"]
tags: ["kubebuilder"]
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
- go v1.15.9
- docker v20.10.5
- kubectl v
- kubernetes cluster v1.20.2

### 安装
安装kubebuilder，运行如下脚本
```sh
os=$(go env GOOS)
arch=$(go env GOARCH)

# 下载并解压
curl -L https://go.kubebuilder.io/dl/2.3.2/${os}/${arch} | tar -xz -C /tmp/

# 加入PATH
sudo mv /tmp/kubebuilder_2.3.2_${os}_${arch} /usr/local/kubebuilder
echo "export PATH=$PATH:/usr/local/kubebuilder/bin" >> /etc/profile && source /etc/profile

```

### 创建一个项目
创建一个目录，并运行初始化命令来初始化新项目
```sh
mkdir $GOPATH/src/exmaple
cd $GOPATH/src/exmaple
kubebuilder init --domain my.domain
```

### 创建一个API
创建一个新的API（group/version）为 webapp/v1 且是新资源CRD Guestbook
```sh
kubebuilder create api --group webapp --version v1 --kind Guestbook

Create Resource [y/n]
y
Create Controller [y/n]
y
Writing scaffold for you to edit...
api/v1/guestbook_types.go
controllers/guestbook_controller.go
Running make:
$ make
/mnt/hgfs/shared/go/bin/controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."
go fmt ./...
go vet ./...
go build -o bin/manager main.go
```
然后就可以编辑API定义和业务逻辑了
例如：
```golang
// GuestbookSpec defines the desired state of Guestbook
type GuestbookSpec struct {
    // INSERT ADDITIONAL SPEC FIELDS - desired state of cluster
    // Important: Run "make" to regenerate code after modifying this file

    // Quantity of instances
    // +kubebuilder:validation:Minimum=1
    // +kubebuilder:validation:Maximum=10
    Size int32 `json:"size"`

    // Name of the ConfigMap for GuestbookSpec's configuration
    // +kubebuilder:validation:MaxLength=15
    // +kubebuilder:validation:MinLength=1
    ConfigMapName string `json:"configMapName"`

    // +kubebuilder:validation:Enum=Phone;Address;Name
    Type string `json:"alias,omitempty"`
}

// GuestbookStatus defines the observed state of Guestbook
type GuestbookStatus struct {
    // INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
    // Important: Run "make" to regenerate code after modifying this file

    // PodName of the active Guestbook node.
    Active string `json:"active"`

    // PodNames of the standby Guestbook nodes.
    Standby []string `json:"standby"`
}

type Guestbook struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`

    Spec   GuestbookSpec   `json:"spec,omitempty"`
    Status GuestbookStatus `json:"status,omitempty"`
}

```
### 测试

您将需要一个Kubernetes集群来运行。您可以使用KIND获取本地集群进行测试，也可以针对远程集群运行。

将CRD安装到群集中
```sh
make install
```
运行您的控制器（它将在前台运行，因此，如果要使其继续运行，请切换到新的终端）
```sh
make run
```
#### 安装自定义资源CRD的实例
如果您在创建资源[y / n]中按y，则在示例中为（CRD）自定义资源定义创建了（CR）自定义资源（如果更改了API定义，请务必先对其进行编辑）
```sh
kubectl apply -f config/samples/
```
#### 在集群中运行

构建镜像并将其推送到IMG指定的位置
```sh
make docker-build docker-push IMG=<some-registry>/<project-name>:tag

```
使用IMG指定的映像将控制器部署到集群
```sh
make deploy IMG=<some-registry>/<project-name>:tag
```
#### 卸载CRD资源
```sh
make uninstall
```


