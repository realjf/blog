---
title: "Kubernetes集群搭建三 之 docker镜像配置"
date: 2019-03-19T14:13:57+08:00
keywords: ["kubernetes", "k8s", "k8s集群搭建"]
categories: ["kubernetes"]
tags: ["kubernetes", "k8s", "k8s集群搭建"]
draft: false
---



#### 1. 使用docker提供的registry镜像创建一个私有镜像仓库
具体可以参考 [https://docs.docker.com/registry/deploying](https://docs.docker.com/registry/deploying)

##### 运行以下命令，启动一个本地镜像仓库
docker 1.6以上版本可以直接运行以下命令
```
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```
停止本地仓库
```
docker container stop registry && docker container rm -v registry
```

镜像仓库操作
```
docker pull ubuntu
docker image tag ubuntu localhost:5000/myfirstimage
docker push localhost:5000/myfirstimage
docker pull localhost:5000/myfirstimage
```

#### 2. kubelet配置
k8s中docker以pod启动，在kubelet创建pod时，还通过启动一个名为gcr.io/google_containers/pause的镜像来实现pod的概念。

需要从gcr.io中将该镜像下载，导出文件，再push到私有docker registry中。之后，可以给每台node的kubelet服务加上启动参数--pod-infra-container-image，指定为私有仓库中pause镜像的地址。
```
--pod-infra-container-image=gcr.io/google_containers/pause-amd64:3.0
```
如果镜像无法下载，可以从docker hub上进行下载：
```
docker pull kubeguide/pause-amd64:3.0
```
然后在kubelet启动参数加上该配置，重启kubelet服务即可
```
systemctl restart kubelet
```





