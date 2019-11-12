---
title: "kubernetes 基本概念和术语"
date: 2019-03-19T14:21:00+08:00
keywords: ["kubernetes", "k8s", "k8s基本概念"]
categories: ["kubernetes"]
tags: ["kubernetes", "k8s", "k8s基本概念"]
draft: false
---


> kubernetes中大部分概念，如node、pod、replication、controller、service等都可以看作是一种“资源对象”，几乎所有的资源对象都可以通过kubernetes提供的kubectl工具执行增、删、改、查等操作并保存在etcd中持久化存储。

>k8s里所有资源对象都可以采用yaml或者json格式的文件来定义或描述

#### 1. Master（主节点、集群控制节点）
- 每个kubernets集群里需要有一个master节点来负责整个集群管理和控制
- 所有控制命令都发给它
- 占据一个独立的服务器
- 如果宕机或不可用，整个集群内容器应用的管理都将失效

##### master节点运行一组以下关键进程
- kubernetes api server(kube-apiserver)：提供http rest接口，是k8s所有资源增删改查等操作的唯一入口，也是集群控制入口进程
- kubernetes controller manager(kube-controller-manager)：k8s所有资源对象的自动化控制中心
- kubernetes scheduler(kube-scheduler)：负责资源调度（pod调度）的进程
- etcd服务：保存k8s所有资源对象的数据

##### 相关命令
- kubectl get nodes：查看集群有多少个node
- kubectl describe node <node_name>：查看某个node详细信息


#### 2. Node（较早版本也叫minion）
- 节点既可以是物理机，也可以是私有云或者公有云中的一个虚拟机，通常在一个节点上运行几百个pod
- kubernetes集群中的工作负载节点，当某个node宕机，其上的工作负载会被master自动转移到其他节点上

##### 每个node节点运行一组以下关键进程
- kubelet：负责pod对应的容器的创建、启停等，同时与master节点密切协作，实现集群管理的基本功能
- kube-proxy：实现kubernetes service的通信与负载均衡机制
- docker engine：docker引擎，负责本机的容器创建和管理工作


#### 3. Pod
是k8s最重要也是最基本概念
- 每个Pod都有一个特殊的被称为“根容器”的Pause容器，Pause容器对应的镜像属于k8s平台的一部分（gcr.io/google_containers/pause-amd64）
- pod对象将每个服务进程包装到相应的pod中，使其成为pod中运行的一个容器
- 根容器不易死亡
- pod里的多个业务容器共享pause容器的ip，共享pause容器挂接的volume（解决Pod直接拿文件共享问题）
- k8s为每个pod都分配唯一的ip地址，称之为pod ip，一个Pod里的多个容器共享pod ip地址
- 集群内任意两个pod之间的tcp/ip可以直接通信，通常采用虚拟二层网络技术实现，如：flannel、open vSwitch等。


##### pod的两种类型
- 普通的pod（存放在k8s的etcd中）
- 静态pod（存放在某个具体的node上的一个具体文件中，且只在此Node上启动运行）


> 默认情况下：当pod里的某个容器停止时，k8s会自动检测到这个问题并重新启动这个pod（重启pod里的所有容器），如果pod所在node宕机，则会将这个Node上的所有pod重新调度到其他节点上。


```yaml
# pod资源定义文件
apiVersion: v1
kind: Pod
metadata:
    name: myweb
    labels: 
        name: myweb
spec:
    containers:
    - name: myweb
      image: kubeguide/tomcat-app:v1
      resources:
        requests:
         memory: "64Mi"
         cpu: "250m"
        limits:
         memory: "128Mi"
         cpu: "500m"
      ports:
      - containerPort: 8080
      env:
      - name: MYSQL_SERVICE_HOST
        value: 'mysql'
      - name: MYSQL_SERVICE_PORT
        value: '3306'
```
- metadata.name：pod的名字
- metadata.labels：标签对象
- spec：pod所包含的容器组
- spec.containers.name 容器名称
- spec.containers.resources 资源


> Pod的ip加上这里的容器端口（containerPort），就组成了一个新的概念——endpoint，它代表此pod里的一个服务进程的对外通信地址。一个pod可以有多个endpoint


#### 4. Label（标签）
label是k8s系统中另外一个核心概念
> 为了建立service和pod间的关联关系，kubernetes为每个pod贴上一个标签，然后给相应的service定义标签选择器。
- 一个label是一个key=value的键值对（key和value由用户自定义）
- Label可以附加到各种资源上，如pod、node、service、rc等
- 一个资源对象可以定义任意数量的Label
- 同一个Label可以被添加到任意数量的资源对象上
- Label可以在资源定义时确定，也可以在对象创建后动态添加或删除

##### label select
label和label select共同构成了kubernetes系统中最核心的应用模型。label select可以类比为sql语句中的where查询条件
##### 两种label表达式
- 基于等式的（=，!=等）
- 基于集合的（in， not in）

多个表达式之间用“,”进行分隔，它们之间是“AND”关系

##### matchLabels和matchExpressions
- 用于定义一组Label
- 可用的条件运算符包括：In、NotIn、Exists和DoesNotExist
- 同时设置matchLabels和matchExpressions，则两组之间为“AND”关系


##### label select 使用场景
- kube-controller通过资源对象rc上定义的label selector来筛选要监控的pod副本的数量
- kube-proxy通过service的label selector来选择对应pod，自动建立起每个service到对应pod的请求转发路由表，从而实现service的智能负载均衡机制
- 通过对某些node的定义特定label，并在pod定义文件中使用nodeSelector这种标签调度策略，kube-scheduler进程可以实现pod定向调度特性


#### 5. Replication Controller(简称RC)
RC用于管理service关联pod，RC包含以下3个关键信息
- 目标pod的定义
- 目标pod需要运行的副本数量（Replicas）
- 用于筛选目标pod的标签（label selector）

创建好RC后，kubernetes会通过RC中定义的label筛选出对应的pod实例并实时监控其状态和数量，如果实例数量少于定义的副本数量（replicas），则会根据RC中定义的pod目标来创建一个新的pod，然后将此pod调度到合适的node上启动运行，直到pod的数量达到replicas定义的数量。


##### 扩容RC命令：
```shell
kubectl scale rc <LABEL_NAME> --replicas=NUM

```

##### 补充
- 删除RC并不会影响通过该RC已创建好的Pod。
- 为了删除所有的Pod，可以设置replicas的值为0，然后更新RC。

##### Replica Set
与RC唯一的区别是Replica Set支持基于集合的Label selector，而RC只支持基于等式的Label Selector

> Replica Set主要被Deployment这个更高层的资源对象所使用，从而形成一整套Pod创建、删除、更新的编排机制。但我们使用Deployment时，无需关心它是如何创建和维护Replica Set的，而这一切是自动发生的。

Replica Set和Deployment将逐步替换之前的RC作用。


##### Replica Set的一些特性与作用
- 通过定义一个RC实现Pod的创建过程及副本数量的自动控制
- RC里包括完整的Pod定义模板
- RC通过Label Selector机制实现对Pod副本的自动控制
- 通过改变RC里的Pod副本数量，可以实现Pod的扩容或缩容管理
- 通过改变RC里Pod模板中的镜像版本，可以实现Pod的滚动升级功能


#### 6. Deplyment
Deployment在内部使用了Replica Set来实现目的。

Deployment相对于RC的一个最大升级是我们可以随时知道当前Pod部署的进度。实际上由于一个Pod的创建、调度、绑定节点及目标Node上启动对应的容器这一完整过程实际上是一个连续变化的部署过程导致的最终状态


##### 使用场景
- Deployment完成Replica Set生成并创建Pod副本
- 检查Deployment状态确认部署动作是否完成（Pod副本数量是否达到预期值）
- 更新Deployment以创建新的Pod
- 可以回滚之前版本的Deployment
- 暂停Deployment一遍一次性修改多个PodTemplateSpec的配置项，之后恢复重新发布
- 扩展Deployment以应对高负载
- 清理不需要的旧版ReplicaSets


> Deployment的定义与Replica Set的定义很类似，除了API声明和Kind类型有所区别
```yaml
# Deployment
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
```
```yaml
# Replica Set
apiVersion: v1
kind: ReplicaSet
metadata:
  name: nginx-repset
```


#### 7. Horizontal Pod Autoscaler

#### 8. StatefulSet
在K8s中，Pod的管理对象RC、Deployment、DaemonSet和Job都是面向无状态的服务。

#### Service（服务）
service是分布式集群架构的核心，一个service对象拥有如下关键特征:
- 拥有一个唯一指定的名字
- 拥有一个虚拟ip（cluster ip、service ip或vip）和端口号
- 能够提供某种远程服务能力
- 被映射到了提供这种服务能力的一组容器应用上

service的服务进程都是基于socket通信方式对外提供服务，或者是实现了某个具体业务的一个特定的tcp server进程。

每个服务进程都有一个独立的Endpoint（ip+port）访问点，kubernetes能够让我们通过service(cluster ip+service port)连接到指定的service上。


##### kubernetes服务发现机制
- 每个kubernetes中的service都有一个唯一的cluster ip及唯一的名字，而名字是由开发者自己定义的，部署时也没必要改变，所以完全可以固定在配置中
- 通过add-on增值包的方式引入了dns系统，把服务名作为dns域名，程序直接通过服务名来简历连接。


##### 外部系统访问service问题
三种ip:
- Node IP：node节点的IP地址（每个节点的物理网卡的Ip地址）
- Pod IP: pod的IP地址
- Cluster IP：service的IP地址

node ip是真实网络的ip，所有属于这个网络的服务器之间都能通过这个网络直接通信，不管它们中是否有部署不属于这个kubernetes集群。这表明，k8s集群之外的节点访问k8s集群之内的某个节点或者tcp/ip服务时，必须要通过node ip进行通信。


pod ip是每个pod的ip地址，他是docker engine根据docker0网桥的Ip地址段进行分配的，通常是一个虚拟的二层网络，如前所说，k8s要求位于不同node上的pod能够彼此直接通信，所以k8s里一个pod的容器访问另外一个pod里的容器，就是通过pod ip所在的虚拟二层网络进行通信的，而真实的tcp/ip流量则是通过node ip所在的物理网卡流出的。


cluster ip也是一个虚拟ip，更像是一个伪造的ip网络，原因如下：
- cluster ip仅仅作用于kubernetes service这个对象，并由kubernetes管理和分配Ip地址（来源于cluster ip地址池）
- cluster ip无法被ping，因为没有一个实体网络对象来响应
- cluster ip只能结合service port组成一个具体的通信端口 ，单独的cluster ip不具备tcp/ip通信的基础，并且他们属于kubernetes集群这样一个封闭的空间，集群之外的节点如果要访问这个通信端口，则需要做一些额外的工作。
- kubernetes集群之内，node ip网，pod ip网与cluster ip网之间的通信，采用的是kubernetes自己设计的一种编程方式的特殊的路由规则，与我们熟知的ip路由规则大不相同。


采用nodeport是解决外部访问集群内部服务的最直接、最有效和最常用方法。
> nodeport实现方式是在k8s集群里的每个node上为需要外部访问的service开启一个对应的tcp监听端口，外部系统只要任用任意一个node的ip地址+具体的nodeport端口号即可访问此服务。





#### 下一代的RC（Replica Set）的特性
- 通过定义一个RC实现Pod的创建过程及副本数量的自动控制
- RC包含完整的Pod定义模板
- 通过修改RC的replicas的数量，实现pod的扩容或缩容功能
- 通过修改pod定义模板的镜像版本，可以实现pod的滚动升级功能




#### Namespace（命名空间）
命名空间是kubernetes系统中的用于实现多租户的资源隔离。namespace通过将集群内部的资源对象“分配”到不同的namespace中，形成逻辑上的分组的不同项目、小组或用户组，便于不同的分组在共享使用整个集群的资源的同时还能被分别管理。

可以通过如下命令获取namespaces
```
kubectl get namespaces
```
可以使用以下命令获取某个命名空间的对象
```
kubectl get pods --namespace=development

```

#### Volume（存储卷）
用于pod中多个容器访问的共享目录，生命周期与pod相同。当容器终止或者重启时，volume中的数据也不会丢失。

kubernetes支持多种类型的volume，例如GlusterFS、Ceph等。


通常先在pod上声明一个volume，然后在容器里引用该volume并mount到容器里的某个目录上。


##### Volume类型
###### emptyDir
无需指定宿主机上对应的目录，是kubernetes自动分配的目录，当pod从node上移除时，emptyDir中的数据也会被永久删除。
- 临时空间
- 长时间任务的中间过程checkpoint的临时保存目录
- 一个容器需要从另外一个容器中获取数据的目录（多个容器共享目录）


###### hostPath
在pod上挂载宿主机上的文件或目录，应用于：
- 容器应用程序生成的日志文件需要永久保存时
- 需要访问宿主机上docker引擎内部数据结构的容器应用时，可以通过定义hostPath为宿主机/var/lib/docker目录，是容器内部应用可以直接访问docker的文件系统。

> 注意：
- 在不同的node上具有相同配置的pod可能会因为宿主机上的目录和文件不同而导致对volume上目录和文件的访问结果不同
- 如果使用资源配额管理，则kubernetes无法将hostPath在宿主机上使用的资源纳入管理


###### gcePersistentDisk
表示使用谷歌公有云提供的永久磁盘存放数据，pd上的内容会被永久保存，当pod被删除时，pd只是被卸载，但不会被删除。需要创建一个永久磁盘（PD），才能使用该类型


限制
- node需要时GCE虚拟机
- 这些虚拟机需要与PD存在于相同的GCE项目和zone中。
- 


###### awsElasticBlockStore
该类型使用亚马逊的公有云EBS Volume



###### NFS
使用NFS网络文件系统提供的共享目录存储数据，需要部署一个NFS Server。

示例如下：
```
volumes:
 - name: nfs
  nfs:
  server: nfs-server.localhost
  path: "/"
```

#### Persistent Volume
pv可以理解成kubernetes集群中的某个网络存储中对应的一块存储，他与volume类似，但有区别：

- pv只能是网络存储，不属于任何node，但可以在每个node上访问
- pv 并不是定义在pod上的，而是独立于pod之外定义的
- pv目前只有几种类型：GCE Persistent Disks、NFS、 RDB、 iSCSCI、 AWS ElasticBlockStore、 GlusterFS等。





