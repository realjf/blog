---
title: "kubernetes 核心原理之 Kube-Proxy"
date: 2019-03-19T14:26:43+08:00
draft: false
---



service是一个抽象的概念，类似一个反向代理，将请求转发到后端的pod上。真正实现service作用的是kube-proxy服务进程。


在每个node上都会运行一个kube-proxy的服务进程，这个进程可以看做service的透明代理兼负载均衡器，其核心功能是将到某个service的访问请求转发到后端的多个pod实例上。

kube-proxy会在本地node上简历一个socketserver来负责接收请求，然后均匀发送到后端某个pod端口上，这个过程默认采用round robin负载均衡算法。

k8s也提供了通过修改service的service.spec.sessionAffinity参数的值来实现会话保持特性的定向转发，如果设置的值为“clientIp”，则将来自同一个clientip的请求都转发到同一个后端pod上。


> service的clusterIP与nodeport等概念是kube-proxy服务通过iptables的NAT转换实现的，kube-proxy在运行过程中动态创建与service相关的iptables规则

访问service的请求，不论是用cluster ip+target port的方式，还是用节点机ip+node port的方式，都被节点机的iptables规则重定向到kube-proxy监听的service服务代理端口。



> kube-proxy的负载均衡器只支持round robin算法。同时在此基础上还支持session保持。


kube-proxy内部创建了一个负载均衡器——loadbalancer，loadbalancer上保存了service到对应的后端endpoint列表的动态转发路由表，而具体的路由选择取决于round robin负载均衡算法及service的session会话保持（SessionAffinity）这两个特性
##### kube-porxy针对变化的service列表，处理流程
1. 如果service没有设置集群ip（ClusterIP），则不做处理，否则，获取该service的所有端口定义列表（spec.ports域）
2. 逐个读取服务端口定义列表中的端口信息，根据端口名称，service名称和namespace判断本地是否已经存在对应的服务代理对象，如不存在则新建，如存在且service端口被修改过，则先删除iptables中和srevice端口相关的规则，关闭服务代理对象，然后走新建流程。
3. 更新负载均衡器组件中对应service的转发地址列表，对于新建的service，确定转发时的会话保持策略。
4. 对于已经删除的service则进行清理

> 针对Endpoint的变化，kube-proxy会自动更新负载均衡器中对应service的转发地址列表。

##### 针对iptables所做的一些细节操作
- KUBE-PORTALS-CONTAINER：从容器中通过service cluster ip和端口号访问service的请求。（容器）
- KUBE-PORTALS-HOST：从主机中通过service cluster ip和端口号访问service的请求（主机）
- KUBE-NODEPORT-CONTAINER：从容器中通过service的nodeport端口号访问service的请求。（容器）
- KUBE-NODEPORT-HOST：从主机中通过service的nodeport端口号访问service请求（主机）


此外，kube-proxy在iptables中为每个service创建由cluster ip+service端口号到kube-proxy所在主机ip+service代理服务所监听的端口的转发规则。


##### service类型为NodePort
kube-proxy在iptables中除了添加上面提及的规则，还会为每个service创建由nodeport端口到kube-proxy所在主机ip+service代理服务所监听的端口的转发规则。




