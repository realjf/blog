---
title: "Kubernetes 的基本概念和术语 K8s Basic Concepts and Terminology"
date: 2022-07-09T10:38:36+08:00
keywords: ["k8s"]
categories: ["k8s"]
tags: ["k8s"]
series: ["k8s"]
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

kubernetes的基本概念和术语大部分是围绕资源对象来说的，主要分为以下两类：
- 某种资源的对象，如：节点（Node）、Pod、服务(Service)、存储卷（Volume）
- 与资源对象相关的事物与动作，如：标签（Label）、注解（Annotation）、命名空间（Namespace）、部署（Deployment）、HPA、PVC

这里主要按照功能或用途分类，将其分为集群类、应用类、存储类及安全类

### 集群类
集群类表示一个由Master和Node组成的kubernetes集群

#### Master
Master指集群的控制节点，在每个kubernetes集群中都需要一个或一组被称为master的节点，来负责整个集群的管理和控制。
Master通常独占一个服务器（在高可用部署中至少是3台服务器），如果宕机，整个集群内容器应用的管理都将失效

Master上运行着以下关键进程：
- kubernetes API Server(kube-apiserver)：提供HTTP Restful API接口的主要服务，是kubernetes里对所有资源进行增删改查等操作的唯一入口，也是集群控制的入口进程
- kubernetes Controller Manager(kube-controller-manager): kubernetes里所有资源对象的自动化控制中心
- kubernetes Scheduler(kube-scheduler): 负责资源调度（Pod调度）的进程
- etcd服务

#### Node
kubernetes集群中除了master外其他服务器都被称为Node,Node是kubernetes集群中的工作负载节点，每个Node都会被master分配一些工作负载。当某个node宕机时，其上的工作负载会被master转移到其他Node上。

每个Node上都运行着以下关键进程：
- kubelet: 负责Pod对应容器的创建、启停等任务，同时与Master密切协作，实现集群管理的基本功能
- kube-proxy: 实现kubernetes Service的通信与负载均衡机制的服务
- 容器运行时（如：Docker）:负责本机的容器创建和管理

kubelet进程会定时向Master汇报自身的情报，例如：操作系统、主机cpu和内存使用情况，以及当前有哪些Pod在运行等，这样Master就可以获知每个Node上的资源使用情况，并实现高效均衡的资源调度策略


#### 命名空间
在很多情况下用于实现多租户的资源隔离，典型的一种思路就是给每个租户都分配一个命名空间，每个命名空间都是相互独立的存在，属于不同命名空间的资源对象从逻辑上相互隔离。

### 应用类
#### Service与Pod

Service是指无状态服务，通常由多个程序副本提供服务，在特殊情况下，也可以是有状态的单实例服务，如mysql这种数据存储服务。

kubernetes的Service具有一个全局唯一的虚拟ClusterIP地址，Service一旦创建，kubernetes就会自动为其分配一个可用的ClusterIP地址，而且在Service的整个生命周期中，它的ClusterIP地址都不会改变，客户端可以通过这个虚拟IP地址+服务的端口直接访问该服务，再通过部署kubernetes集群的DNS服务，就可以实现Service Name(域名)到ClusterIP地址的DNS映射功能，我们只要使用服务的名称（DNS名称）即可完成到目标服务的访问请求。

Pod是最重要的基本概念之一，每个Pod都有一个特殊的被称为根容器的Pause容器，Pause容器对应的镜像属于kubernetes平台的一部分，除了Pause容器，每个Pod都还包含一个或多个紧密相关的用户业务容器。

Pod特殊结构原因：
- 为多进程之间的协作提供抽象模型，使用Pod作为基本调度、复制等管理工作的最小单位，让多个应用进程能一起有效地调度和伸缩
- Pod里的多个业务容器共享Pause容器的IP，共享pause容器挂接的volume，这样既简化了密切关联的业务容器之间的通信问题，也很好地解决了它们之间的文件共享问题


kubernetes为每个Pod都分配了唯一的IP地址，称为Pod IP，一个Pod里的多个容器共享Pod IP地址。
kubernetes要求底层网络支持集群内任意两个Pod之间的直接通信，这通常采用虚拟二层网络技术实现，如：flannel、open vSwitch等，因此，在kubernetes里，一个Pod里的容器与另外主机上的Pod容器能够直接通信。


Pod有两种：
- 普通的Pod，一旦创建，就会被放入etcd中存储，随后被master调度到某个具体的Node上并绑定
- 静态Pod，静态Pod并没有存放在kubernetes中etcd中，而是被存放在某个具体的Node上的一个具体文件中，并且只能在此Node上启动、运行。

```yaml
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
      ports:
      - containerPort: 8080
```

Pod的IP加上这里的容器端口组成了一个新的概念——Endpoint，代表此Pod里的一个服务进程的对外通信地址。一个Pod也存在具有多个Endpoint的情况

#### Label与标签选择器

一个Label是一个key=value的键值对，一个资源对象可以定义任意数量的Label

给某个资源对象定义一个Label，就相当于给它打上了一个标签，随后可以通过Label Selector查询和筛选拥有某些Label的资源对象


#### Pod与Deployment
Deployment可以看成是Pod的模板，用于实现对Pod的控制，其主要使用场景如下：
- 创建一个Deployment对象来完成相应Pod副本数量的创建
- 检查Deployment状态确认部署动作是否完成
- 更新Deployment以创建新的Pod
- 扩展Deployment以应对高负载
  
#### Service的ClusterIP地址
kubernetes内部在每个Node上都运行了一套全局的虚拟负载均衡器，自动注入并自动实时更新集群中所有Service的路由表，通过iptables或IPVS机制，把对Service的请求转发到其后端对应的某个Pod实例上，并在内部实现服务的负载均衡与会话保持机制。

ClusterIP是虚拟IP地址的原因：
- ClusterIP地址仅仅作用于kubernetes Service这个对象，并由kubernetes管理和分配IP地址，与Node和Master所在地屋里网络完全无关
- 因为没有一个实体网络对象来响应，所以ClusterIP地址无法被ping通，ClusterIP地址只能与Service Port组成一个具体的服务访问端点，单独的ClusterIP不具备TCP/IP通信的基础
- ClusterIP属于kubernetes集群这个封闭的空间，集群外的节点要访问这个通信端口，则需要做一些额外的工作

除了正常的Service，还有一种特殊Service——Headless Service，只要在Service的定义中设置了clusterIP: None，就定义了一个Headless Service，它与普通Service的关键区别在于它没有ClusterIP地址，如果解析Headless Service的DNS域名，则返回的是该Service对应的全部Pod的Endpoint列表，这意味着客户端是直接跟后端的Pod建立TCP/IP连接进行通信的，没有通过虚拟ClusterIP地址进行转发，因此通信性能最高，等同于原生网络通信

#### Service的外网访问问题

如何在kubernetes集群外访问应用服务呢？
首先弄明白kubernetes的三种IP，分别是：
- Node IP: Node的IP地址
- Pod IP: Pod的IP地址
- Service IP: Service的IP地址

Node IP是kubernetes集群中每个节点的物理网卡的IP地址，是一个真实存在的物理网络，所有属于这个网络的服务器都能通过这个网络直接通信，说明kubernetes集群外地节点访问kubernetes集群内的某个节点或者TCP/IP服务时，都必须通过Node IP通信

Pod IP是每个Pod的IP地址，在使用docker作为容器支持引擎下，它是Docker Engine根据docker0网桥的IP地址段进行分配的，通常是一个虚拟二层网络。kubernetes中一个Pod里的容器访问另外一个Pod里的容器时，就是通过Pod IP所在地虚拟二层网络进行通信的，而真实的TCP/IP流量是通过Node IP所在的物理网卡流出的

Service的ClusterIP地址属于集群内的地址，无法在集群外直接使用，为了解决这个问题，kubernetes引入了NodePort这个概念，NodePort也是解决集群外的应用访问集群内服务的直接、有效的常见做法。

设置了nodePort后，集群外就可以直接通过<nodePortIP>:<nodePort>进行访问了


NodePort的实现方式是：在kubernetes集群的每个Node上都为需要外部访问的Service开启一个对应的TCP监听端口，外部系统只要用任意一个Node的IP地址+NodePort端口号即可访问此服务。

**NodePort还没有完全解决外部访问Service的所有问题**，比如负载均衡问题。

负载均衡器独立于kubernetes集群之外，可以用硬件或软件实现，如HAProxy或Nginx，对于每个Service，我们通常需要配置一个对应的负载均衡器实例来转发流量到后端的Node上，kubernetes提供了自动化解决方案。如GCE公有云上，只需要把Service的type=NodePort改为type=LoadBalancer，kubernetes就会自动创建一个对应的负载均衡器实例并返回它的IP地址供外部客户端使用。


由于端口是有限的物理资源，那能不能让多个Service共用一个对外端口呢？
Ingress就是解决该问题的。其实现机制可以理解为基于Nginx的支持虚拟主机的HTTP代理

#### 有状态的应用集群
Deployment对象用来实现无状态服务的多副本自动控制功能，那么有状态的服务呢？
这些一开始是依赖StatefulSet解决的，但后来发现StatefulSet还是不够通用和强大，所以后面又出现了kubernetes Operator。

有状态应用一般有如下特殊共性：
- 每个节点都有固定的身份ID，通过这个ID，集群中的成员可以相互发现并通信
- 集群的规模是比较固定的，集群规模不能随意变动
- 集群中的每个节点都是有状态的，通常会持久化数据到永久存储中，每个节点在重启后都需要使用原有的持久化数据
- 集群中成员节点的启动顺序通常也是确定的
- 如果磁盘损坏，则集群的某个节点无法正常运行，集群功能受损

为了解决有状态集群的这种复杂的特殊应用的建模，kubernetes引入了StatefulSet，其本质上是Deployment/RC的一个特殊变种，特性如下：
- StatefulSet里的每个Pod都有稳定、唯一的网络标识，可以用来发现集群内的其它成员
- StatefulSet控制的Pod副本的启停顺序是受控的
- StatefulSet里的Pod采用稳定的持久化存储卷，通过PV或PVC来实现，删除Pod时默认不会删除与StatefulSet相关的存储卷

StatefulSet除了要与PV卷捆绑使用，以存储Pod的状态数据，还要与Headless Service配合使用，即在每个StatefulSet定义中都要声明它属于哪个Headless Service。
StatefulSet在Headless Service的基础上又为StatefulSet控制的每个Pod实例都创建了一个DNS域名，这个域名格式如下:
```
$(podname).$(headless service name)
```

StatefulSet的建模能力有限，所以有了后来的kubernetes Operator框架和众多Operator实现，
kubernetes平台开发者利用kubernetes Operator框架提供的API,可以更方便地开发一个类似StatefulSet的控制器。



#### 批处理应用
批处理应用的特点是一个或多个进程处理一组数据，在这组数据都处理完成后，批处理任务自动结束，其对应的资源对象是Job。

除了Job，kubernetes还引入了CronJob，可以周期性地执行某个任务


#### 应用的配置问题
如何解决应用需要在不同的环境中修改配置的问题呢？这就需要ConfigMap和Secret两个对象。

ConfigMap就是保存配置项的一个Map，是分布式系统中配置中心的独特实现之一。

具体使用如下：
- 用户将配置文件的内容保存到ConfigMap中，文件名可作为key，value就是整个文件袋内容，多个配置文件都可被放入同一个ConfigMap
- 在建模用户应用时，在Pod里将ConfigMap定义为特殊的Volume进行挂载，在Pod被调度到某个具体Node上时，ConfigMap里的配置文件会被自动还原到本地目录下，然后映射到Pod里指定的配置目录下，这样用户的程序就可以无感知地读取配置了
- 在ConfigMap的内容发生修改后，kubernetes会自动重新获取ConfigMap的内容，并在目标节点上更新对应的文件


Secret是用来解决对敏感信息的配置问题，如密码等

#### 应用的运维问题

HPA：Pod横向自动扩容，通过跟踪分析指定Deployment控制的所有目标Pod的负载变化情况，来确定是否需要有针对性地调整目标Pod的副本数量，这就是HPA的实现原理。

VPA：垂直Pod自动扩缩容，它根据容器资源使用率自动推测并设置Pod合理的CPU和内存的需求指标，从而更加精准地调度Pod，实现整体上节省集群资源的目标


### 存储类
存储类资源对象包括：Volume、Persistent Volume、PVC和StorageClass

Volume是Pod中能够被多个容器访问的共享目录。

kubernetes提供了丰富的Volume类型供容器使用，如临时目录，宿主机目录，共享存储等

#### emptyDir
一个emptyDir是在Pod分配到Node时创建的，它的初始内容为空，并且无需指定宿主机上对应的目录文件，因为这是kubernetes自动分配的一个目录，当Pod从Node上移除时，emptyDir中的数据也被**永久移出**。

emptyDir的一些用途：
- 临时空间
- 长时间任务执行过程中使用的临时目录
- 一个容器需要从另一个容器中获取数据的目录

默认情况下，emptyDir使用的是节点的存储介质，还可以使用内存


#### hostPath
hostPath为在Pod上挂载宿主机上的文件或目录，可以用于如下场景：
- 在容器应用程序生成的日志文件需要永久保存时
- 需要访问宿主机上docker引擎内部数据结构的容器应用时

#### 公有云Volume

#### 其他类型的Volume
- iscsi：将iSCSI存储设备上的目录挂载到Pod中
- nfs: 将NFS Server上的目录挂载到Pod中
- glusterfs: 将开源GlusterFS网络文件系统的目录挂载到Pod中
- rbd: 将Ceph块设备共享存储挂载到Pod中
- gitRepo: 通过挂载一个空目录，并从git库克隆一个git repository以供Pod使用
- configmap: 将配置数据挂载为容器内的文件
- secret: 将Secret数据挂载为容器内的文件

**动态存储管理**
Volume属于静态管理的存储，即我们需要事先定义每个Volume，然后将其挂载到Pod中去用，这种方式存在很多弊端。所以kubernetes发展了存储动态化新机制，其核心对象有三个：Persistent Volume(PV)、StorageClass、PVC。

PV表示由系统动态创建的一个存储卷，可以理解为kubernetes集群中某个网络存储对应的一块存储，它不是被定义在Pod上，而是独立于Pod之外定义的。

PV支持的存储系统很多种，那系统怎么知道从哪个存储系统中创建什么规格的PV存储卷呢?这就需要StorageClass和PVC。


StorageClass用来描述和定义某种存储系统的特征
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
reclaimPolicy: Retain
allowVolumeExpansion: true
mountOptions:
  - debug
volumeBindingMode: Immediate
```
- provisioner代表了创建PV的第三方存储插件
- parameters是创建PV时的必要参数
- reclaimPolicy是PV回收策略，回收策略包括删除或保留


典型的PVC定义如下：
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: claim1
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 30Gi
```

PVC表示应用希望申请的PV规格，其中重要的属性包括accessModes(存储访问模式)、StorageClassName及resources（存储的具体规格）

只要在Pod里引入PVC即可达到使用目的
```yaml
spec:
  containers:
  - name: myapp
    image: tomcat:8.5.38-jre8
    volumeMounts:
      - name: tomcatedata
        mountPath: "/data"
  volumes:
    - name: tomcatedata
      persistentVolumeClaim:
        claimName: claim1
```

### 安全类
基于角色的访问控制权限系统——RBAC（Role-Based Access Control）

默认情况下，kubernetes在每个命名空间中都会创建一个默认的名称为default的Service Account，因此Service Account是不能全局使用的，只能被它所在命名空间中的Pod使用。


Role作用于局限于某个命名空间的角色
ClusterRole作用于整个kubernetes集群范围内的角色

创建好了角色，就需要通过RoleBinding和ClusterRoleBinding来绑定某个具体用户了。

NetworkPolicy：它是网络安全相关的资源对象，用于解决用户应用之间的网络隔离和授权问题。


























