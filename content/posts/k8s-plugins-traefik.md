---
title: "Kubernetes集群下 Traefik安装和使用"
date: 2019-03-19T14:35:31+08:00
keywords: ["kubernetes", "k8s", "traefik", "ingress controller"]
categories: ["kubernetes"]
tags: ["kubernetes", "k8s", "traefik", "ingress controller"]
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

> 前提：安装好kubernetes集群情况下

![https://github.com/containous/traefik/raw/master/docs/img/architecture.png](https://github.com/containous/traefik/raw/master/docs/img/architecture.png)

>run traefik and let it do the work for you!

traefik官方地址：[http://traefik.cn/](http://traefik.cn/)

### 方法一：使用k8s安装
#### 准备
```sh

# 创建目录
mkdir traefik 
cd traefik

# 拉取traefik官方docker镜像
docker pull docker.io/traefik
# docker hub地址：https://store.docker.com/images/traefik

# 拉取traefik相关配置
git clone https://github.com/containous/traefik.git

# 检查traefik配置 
ll traefik/example/k8s/

-rw-r--r-- 1 root root  140 Sep 11 16:53 cheese-default-ingress.yaml
-rw-r--r-- 1 root root 1805 Sep 11 16:53 cheese-deployments.yaml
-rw-r--r-- 1 root root  519 Sep 11 16:53 cheese-ingress.yaml
-rw-r--r-- 1 root root  509 Sep 11 16:53 cheese-services.yaml
-rw-r--r-- 1 root root  504 Sep 11 16:53 cheeses-ingress.yaml
-rw-r--r-- 1 root root 1120 Sep 11 16:53 traefik-deployment.yaml
-rw-r--r-- 1 root root 1206 Sep 11 16:53 traefik-ds.yaml
-rw-r--r-- 1 root root  694 Sep 11 16:53 traefik-rbac.yaml
-rw-r--r-- 1 root root  471 Sep 11 16:53 ui.yaml
```

#### 创建traefik pod
```sh
# 创建traefik
kubectl create -f traefik/example/k8s/traefik-rbac.yaml
# 

clusterrole.rbac.authorization.k8s.io "traefik-ingress-controller" created
clusterrolebinding.rbac.authorization.k8s.io "traefik-ingress-controller" created


# 创建traefik deployment
kubectl create -f traefik/example/k8s/traefik-deploment.yaml

serviceaccount "traefik-ingress-controller" created
deployment.extensions "traefik-ingress-controller" created
service "traefik-ingress-service" created



# 检查启动情况
kubectl get pods --all-namespaces -o wide

NAMESPACE     NAME                                         READY     STATUS              RESTARTS   AGE       IP        NODE
kube-system   traefik-ingress-controller-7dcd6f447-sdbsw   0/1       ContainerCreating   0          1m        <none>    192.168.37.152
myapp         test-v2-vmhqm                                0/1       Pending             0          67d       <none>    <none>



```
> 如果使用非安全端口，kubectl命令需要加上--server=192.168.37.150:8080

#### 检查traefik服务端口
```sh
kubectl get service --all-namespaces


NAMESPACE     NAME                      TYPE           CLUSTER-IP        EXTERNAL-IP   PORT(S)                       AGE
default       kubernetes                ClusterIP      169.169.0.1       <none>        443/TCP                       109d
default       service-example           LoadBalancer   169.169.150.45    <pending>     80:45981/TCP                  95d
kube-system   traefik-ingress-service   NodePort       169.169.126.249   <none>        80:32039/TCP,8080:57048/TCP   1m
```

#### traefik提供了kubernetes下暴露服务来提供web ui
```sh
# 创建ingress
kubectl apply -f ui.yaml

service "traefik-web-ui" created
ingress.extensions "traefik-web-ui" created


# 检查是否创建成功
kubectl describe ing traefik-web-ui -n kube-system

Name:             traefik-web-ui
Namespace:        kube-system
Address:          
Default backend:  default-http-backend:80 (<none>)
Rules:
  Host                 Path  Backends
  ----                 ----  --------
  traefik-ui.minikube  
                       /   traefik-web-ui:web (<none>)
Annotations:
  kubectl.kubernetes.io/last-applied-configuration:  {"apiVersion":"extensions/v1beta1","kind":"Ingress","metadata":{"annotations":{},"name":"traefik-web-ui","namespace":"kube-system"},"spec":{"rules":[{"host":"traefik-ui.minikube","http":{"paths":[{"backend":{"serviceName":"traefik-web-ui","servicePort":"web"},"path":"/"}]}}]}}

Events:  <none>
```
我们刚刚创建了一个traefik-web-ui的Ingress，接下来就可以通过域名访问了，



#### 访问traefik
在traefik启动成功后，它同时启动了80和8080端口，80对应的服务端端口，8080对应的ui端口，我们可以通过查看服务暴露端口号浏览器访问下提供的ui界面。


访问：http://<node_ip>:<node_port>/dashboard/#/，这里<node_ip>可以为master或者node节点的ip均可


### 方法二：使用下载二进制包方式
#### 下载
```
wget https://github.com/containous/traefik/releases/download/v1.6.2/traefik

# 安装
yum install httpd-tools -y

# 使用htpasswd生成密码
htpasswd -bn admin 123456

```
#### 添加配置文件
```
vim /etc/traefik.toml

# Global configuration
################################################################
defaultEntryPoints = ["http"]



[backends]
  [backends.error]
    [backends.error.servers.error]
    url = "http://172.16.233.214:3003"
################################################################
# Entrypoints configuration
################################################################

# Entrypoints definition
#
# Optional
# Default:
[entryPoints]
    [entryPoints.http]
    address = ":80"

################################################################
# Traefik logs configuration
################################################################

[traefikLog]
filePath = "/var/log/traefik.log"

[accessLog]

filePath = "/tmp/traefik.log"

################################################################
# API and dashboard configuration
################################################################

[api]
entryPoint = "traefik"
[entryPoints.traefik]
  address=":81"
  [entryPoints.traefik.auth]
    [entryPoints.traefik.auth.basic]
      users = [
        "admin:$apr1$GJjq8j8J$vLuIlaon0vpg4b.Iao1S80" # 使用上面htpasswd生成的密码
      ]


################################################################
# Ping configuration
################################################################

# Enable ping
[ping]
# Enable Docker configuration backend
[kubernetes]
endpoint = "http://192.168.37.150:8080"
namespaces = []
```

#### 启动方式
```
chmod +x traefik

./traefik -c /etc/traefik.toml

```


参考文献
- [https://www.kubernetes.org.cn/4408.html](https://www.kubernetes.org.cn/4408.html)
- [http://www.mamicode.com/info-detail-2109270.html](http://www.mamicode.com/info-detail-2109270.html)


