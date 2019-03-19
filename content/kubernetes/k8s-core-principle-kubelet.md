---
title: "kubernetes 核心原理之 Kubelet"
date: 2019-03-19T14:26:28+08:00
draft: false
---


在每个Node节点上都会启动一个kubelet服务进程，该进程负责处理master节点下发到本节点的任务，管理Pod和pod中的容器。

每个kubelet进程会在api server上注册节点自身信息，定期向master节点汇报节点资源的使用情况，并通过cAdvisor监控容器和节点资源。

#### 节点管理
节点通过设置kubelet的启动参数“--register-node”，来决定是否向api server注册自己，如果该参数为true，则会向api server注册自己。

其他参数包括：
- --api-servers：api server的位置
- --kubeconfig：kubeconfig文件，用于访问api server的安全配置文件
- --cloud-provider：云服务商地址，仅用于公有云环境


通过kubelet的启动参数“--node-status-update-frequency”设置kubelet每隔多长时间想api server报告节点状态，默认是10s。

#### Pod管理
kubelet通过以下几种方式获取自身node上所要运行的pod清单：
- 文件：同过启动参数“--config”指定的配置文件目录下的文件（默认/etc/kubernetes/manifests/）
- http断电：通过“--manifest-url”参数设置
- api server：通过api server监听etcd目录，同步pod列表

##### kubelet去读监听到的信息，如果是创建和修改pod任务，则
1. 为该pod创建一个数据目录
2. 从api server读取该pod清单
3. 为该pod挂载外部卷
4. 下载pod用到的secret
5. 检查已经运行在节点中的pod，如果该pod没有容器或pause容器（kubernetes/pause镜像创建的容器）没有启动，则先停止pod里所有容器的进程。如果在pod中有需要删除的容器，则删除这些容器。
6. 用"kubernetes/pause"镜像为每个pod创建一个容器，该pause容器用于接管pod中所有其他容器的网络。每创建一个新的pod，kubelet都会先创建一个pause容器，然后创建其他容器。
7. 为pod中的每个容器做如下处理：
- 为容器计算一个hash值，然后用容器的名字去查询对应docker容器的hash值。若找到容器，且两者的hash值不同，则停止docker中容器的进程，并停止与之关联的pause容器的进程，若两者相同，则不做任何处理。
- 如果容器被终止了，且容器没有指定的restartPolicy（重启策略），则不做任何处理。
- 调用docker client下载容器镜像，调用docker client运行容器。

##### 容器健康检查
检查容器健康状态的两种探针
- LivenessProbe探针：判断容器是否健康，如果不健康，则删除Pod，根据其重启策略做相应处理。
- ReadinessProbe探针：判断容器是否完成启动，且准备接受请求。如果失败，pod的状态将被修改，Endpoint Controller将从Service的Endpoint中删除包含该容器所在pod的ip地址的endpoint条目。


##### LivenessProbe实现方式
- ExecAction：在容器内部执行一个命令，如果该命令的退出状态码为0，则表明容器健康
- TCPSocketAction：通过容器的ip地址和端口号执行TCP检查，如果端口能被访问，则表明容器健康
- HTTPGetAction：通过容器的ip地址和端口号即路径调用http get方法，如果响应的状态码大于等于200且小于400，则认为容器状态健康

LivenessProbe探针包含在pod定义的spec.containers.{某个容器}中
```yaml
# 容器命令检查
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/health
  initialDelaySeconds: 15
  timeoutSeconds: 1
```

```yaml  
# http检查
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 15
  timeoutSeconds: 1
```

##### cAdvisor资源监控
监控级别包括：容器、pod、service和整个集群

当前支持的后端包括InfluxDB（with Grafana for Visualization）和Google Cloud Monitoring

在大部分kubernetes集群中，cAdvisor通过他所在节点机的4194端口暴露一个简单的ui。




