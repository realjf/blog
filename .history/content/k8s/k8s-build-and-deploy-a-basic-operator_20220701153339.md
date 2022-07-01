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

	mydomainv1alpha1 "hello-operator2/api/v1alpha1"
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
