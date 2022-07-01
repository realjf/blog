---
title: "K8s Build and Deploy a Basic Operator"
date: 2022-07-01T15:00:11+08:00
keywords: ["k8s", "operator"]
categories: ["k8s"]
tags: ["k8s"]
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

## 准备
- linux系统
- go开发环境
- operator sdk 包括：
  - operator-sdk 命令行界面（CLI）工具和SDK方便了算子的开发。
  - operator lifecycle manager 这有助于集群内操作员的安装、升级和基于角色的访问控制 (RBAC)
- kubernetes 集群，可以使用minikube之类的工具在本地安装一个单机集群
- 镜像仓库

### golang开发环境安装
[golang下载](https://go.dev/dl/)

### kubernetes集群安装
你需要的配置
- 2核以上cpu
- 2GB以上内存
- 20GB以上的磁盘空间
- docker

#### 下载安装
需要提前关闭swap分区
```sh
# 关闭swap分区
swapoff -a

# 修改/etc/fstab挂载的swap，注释swap挂载即可
reboot
# 检查swap状态
free -h
# 如果swap一行全部为0则为关闭
```


```sh
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

#### 运行集群
```sh
minikube start
```

参考[minikube安装](https://minikube.sigs.k8s.io/docs/start/)

### operator sdk 安装
```golang
git clone https://github.com/operator-framework/operator-sdk
cd operator-sdk
git checkout master
make install
```
可以参考[operator sdk安装](https://sdk.operatorframework.io/docs/installation/)
### 构建kubernetes operator
#### 第一步：生成样板代码
首先，运行minikube start运行本地集群
```sh
mkdir -p $GOPATH/src/operators && cd $GOPATH/src/operators
minikube start init
```
然后运行operator-sdk init生成我们示例应用的样板代码
```sh
operator-sdk init
```
#### 第二步：创建API和自定义资源
在 Kubernetes 中，为您要提供的每个服务公开的功能都组合在一个资源中。因此，当我们为应用程序创建 API 时，我们还通过 CustomResourceDefinition (CRD) 创建它们的资源。
以下命令创建一个 API 并通过 --kind 选项将其标记为 Traveler。在该命令创建的 YAML 配置文件中，您可以找到一个标签为 kind 的字段，其值为 Traveller。
该字段表示在整个开发过程中使用 Traveler 来引用我们的 API：
```sh
operator-sdk create api --version=v1alpha1 --kind=Traveller

Create Resource [y/n]
y
Create Controller [y/n]
y
...
```
我们还要求该命令创建一个控制器来处理与我们的种类相对应的所有操作。定义控制器的文件名为 traveller_controller.go。

--version 选项可以采用任何字符串，您可以将其设置为跟踪项目的开发。在这里，我们从一个适度的值开始，表明我们的应用程序处于 alpha 阶段。

#### 第三步：下载依赖
我们的应用程序使用 tidy 模块来删除我们不需要的依赖项，并使用 vendor 模块来整合包。按如下方式安装这些模块：
```sh
go mod tidy
go mod vendor
```
#### 第四步：创建deployment
现在我们将在我们的 Kubernetes Operator 保护伞下创建构成容器化应用程序的标准资源
因为 Kubernetes Operator 会反复运行以协调应用程序的状态，所以将控制器编写为幂等非常重要
换句话说，控制器可以多次运行代码，而无需创建资源的多个实例
以下 repo 在文件 controllers/deployment.go 中包含一个用于部署资源的控制器
```golang
package controllers

import (
	"context"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"

	mydomainv1alpha1 "operators/api/v1alpha1"
)

func labels(v *mydomainv1alpha1.Traveller, tier string) map[string]string {
	// Fetches and sets labels

	return map[string]string{
		"app":             "visitors",
		"visitorssite_cr": v.Name,
		"tier":            tier,
	}
}

// ensureDeployment ensures Deployment resource presence in given namespace.
func (r *TravellerReconciler) ensureDeployment(request reconcile.Request,
	instance *mydomainv1alpha1.Traveller,
	dep *appsv1.Deployment,
) (*reconcile.Result, error) {

	// See if deployment already exists and create if it doesn't
	found := &appsv1.Deployment{}
	err := r.Get(context.TODO(), types.NamespacedName{
		Name:      dep.Name,
		Namespace: instance.Namespace,
	}, found)
	if err != nil && errors.IsNotFound(err) {

		// Create the deployment
		err = r.Create(context.TODO(), dep)

		if err != nil {
			// Deployment failed
			return &reconcile.Result{}, err
		} else {
			// Deployment was successful
			return nil, nil
		}
	} else if err != nil {
		// Error that isn't due to the deployment not existing
		return &reconcile.Result{}, err
	}

	return nil, nil
}

// backendDeployment is a code for Creating Deployment
func (r *TravellerReconciler) backendDeployment(v *mydomainv1alpha1.Traveller) *appsv1.Deployment {

	labels := labels(v, "backend")
	size := int32(1)
	dep := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "hello-pod",
			Namespace: v.Namespace,
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &size,
			Selector: &metav1.LabelSelector{
				MatchLabels: labels,
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: labels,
				},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{{
						Image:           "paulbouwer/hello-kubernetes:1.10",
						ImagePullPolicy: corev1.PullAlways,
						Name:            "hello-pod",
						Ports: []corev1.ContainerPort{{
							ContainerPort: 8080,
							Name:          "hello",
						}},
					}},
				},
			},
		},
	}

	controllerutil.SetControllerReference(v, dep, r.Scheme)
	return dep
}
```
#### 第五步：创建service
因为我们希望我们的部署创建的 pod 可以在我们的系统之外访问，所以我们将一个服务附加到我们刚刚创建的部署。代码在文件 controllers/service.go 中
```golang
package controllers

import (
	"context"
	mydomainv1alpha1 "operators/api/v1alpha1"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/apimachinery/pkg/util/intstr"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"
)

// ensureService ensures Service is Running in a namespace.
func (r *TravellerReconciler) ensureService(request reconcile.Request,
	instance *mydomainv1alpha1.Traveller,
	service *corev1.Service,
) (*reconcile.Result, error) {

	// See if service already exists and create if it doesn't
	found := &appsv1.Deployment{}
	err := r.Get(context.TODO(), types.NamespacedName{
		Name:      service.Name,
		Namespace: instance.Namespace,
	}, found)
	if err != nil && errors.IsNotFound(err) {

		// Create the service
		err = r.Create(context.TODO(), service)

		if err != nil {
			// Service creation failed
			return &reconcile.Result{}, err
		} else {
			// Service creation was successful
			return nil, nil
		}
	} else if err != nil {
		// Error that isn't due to the service not existing
		return &reconcile.Result{}, err
	}

	return nil, nil
}

// backendService is a code for creating a Service
func (r *TravellerReconciler) backendService(v *mydomainv1alpha1.Traveller) *corev1.Service {
	labels := labels(v, "backend")

	service := &corev1.Service{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "backend-service",
			Namespace: v.Namespace,
		},
		Spec: corev1.ServiceSpec{
			Selector: labels,
			Ports: []corev1.ServicePort{{
				Protocol:   corev1.ProtocolTCP,
				Port:       80,
				TargetPort: intstr.FromInt(8080),
				NodePort:   30685,
			}},
			Type: corev1.ServiceTypeNodePort,
		},
	}

	controllerutil.SetControllerReference(v, service, r.Scheme)
	return service
}
```

#### 第六步：在控制器中添加引用
这一步让我们的控制器知道部署和服务的存在。它通过编辑 traveller_controller.go 文件的协调循环函数来实现这一点
```golang
import (
	"context"

	appsv1 "k8s.io/api/apps/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"

	mydomainv1alpha1 "operators/api/v1alpha1"
)

// For more details, check Reconcile and its Result here:
// - https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.9.2/pkg/reconcile
func (r *TravellerReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := log.FromContext(ctx).WithValues("Traveller", req.NamespacedName)

	// Fetch the Traveller instance
	instance := &mydomainv1alpha1.Traveller{}
	err := r.Get(context.TODO(), req.NamespacedName, instance)
	if err != nil {
		if errors.IsNotFound(err) {
			// Request object not found, could have been deleted after reconcile request.
			// Owned objects are automatically garbage collected. For additional cleanup logic use finalizers.
			// Return and don't requeue
			return reconcile.Result{}, nil
		}
		// Error reading the object - requeue the request.
		return reconcile.Result{}, err
	}

	// Check if this Deployment already exists
	found := &appsv1.Deployment{}
	err = r.Get(context.TODO(), types.NamespacedName{Name: instance.Name, Namespace: instance.Namespace}, found)
	var result *reconcile.Result
	result, err = r.ensureDeployment(req, instance, r.backendDeployment(instance))
	if result != nil {
		log.Error(err, "Deployment Not ready")
		return *result, err
	}

	// Check if this Service already exists
	result, err = r.ensureService(req, instance, r.backendService(instance))
	if result != nil {
		log.Error(err, "Service Not ready")
		return *result, err
	}

	// Deployment and Service already exists - don't requeue
	log.Info("Skip reconcile: Deployment and service already exists",
		"Deployment.Namespace", found.Namespace, "Deployment.Name", found.Name)

	return ctrl.Result{}, nil
}
```

### 部署这个service
有三种方式部署：
- 本地运行服务器
- 在集群中运行服务器
- 通过一个Operator lifecycle Manager（OLM）部署这个服务
  
我们使用本地运行这个服务方式

#### 安装这个CRD
直接运行如下命令进行构建
```sh
make install
```


