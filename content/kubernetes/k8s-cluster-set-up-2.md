---
title: "Kubernetes集群搭建二 之 k8s集群"
date: 2019-03-19T14:13:53+08:00
draft: false
---


#### 方式1：基于CA签名的双向数字证书认证方式
过程如下：
- 为kube-apiserver生成一个数字证书，并用CA证书进行签名
- 为kube-apiserver进程配置证书相关的启动参数，包括CA证书（用于验证客户端证书的签名真伪）、自己的经过CA签名后的证书及私钥
- 为每个访问K8S API server的客户端进程生成自己的数字证书，也都用CA证书进行签名，在相关程序的启动参数里增加CA证书、自己的证书等相关参数

##### 1). 设置kube-apiserver的CA证书相关的文件和启动参数
使用openssl工具在master服务器上创建CA证书和私钥相关的文件：
```
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -subj "/CN=k8s-master" -days 5000 -out ca.crt
openssl genrsa -out server.key 2048
```
注：生成ca.crt时，-subj参数中“/CN”的值为Master主机名

> 509是一种通用的证书格式

准备master_ssl.cnf文件，用于x509 v3版本的证书，示例如下：
```
[ req ]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
DNS.5 = k8s-master
IP.1 = 169.169.0.1
IP.2 = 192.168.37.150

### 更复杂的配置可以选用以下方式
[ req ]
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_ca ]
basicConstraints = critical, CA:TRUE
keyUsage = critical, digitalSignature, keyEncipherment, keyCertSign
[ v3_req_server ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
[ v3_req_client ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
[ v3_req_apiserver ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names_cluster
[ v3_req_etcd ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names_etcd
[ alt_names_cluster ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
DNS.5 = k8s-master
# DNS.6 = ${KUBERNETES_PUBLIC_ADDRESS}
IP.1 = 169.169.0.1
IP.2 = 192.168.37.150
# IP.3 = ${SERVICE_IP}
# IP.4 = ${KUBERNETES_PUBLIC_IP}
[ alt_names_etcd ]
DNS.1 = k8s-master
# DNS.2 = k8s-controller-2
IP.1 = 169.169.0.1
# IP.2 = ${CONTROLLER2_IP}
```
> 主要需要设置Master服务器的hostname（k8s-master）、ip地址（192.168.37.150），以及kubernetes master service的虚拟服务名称（kubernetes.default等）和该虚拟服务的ClusterIP地址（169.169.0.1）

接下来，基于master_ssl.cnf文件创建server.csr和server.crt文件。在生成server.csr时，-subj参数中“/CN”的值需要为master的主机名：
```sh
openssl req -new -key server.key -subj "/CN=k8s-master" -config master_ssl.cnf -out server.csr
# 如果运行上述命令，报错：Error Loading request extension section v3_req，则需要检查.cnf文件是否书写正确

openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 5000 -extensions v3_req -extfile master_ssl.cnf -out server.crt
```
全部执行完，生成6个文件：ca.crt、ca.key、ca.srl、server.crt、server.csr、server.key


将这些文件复制到一个目录(/etc/kubernetes/ssl_keys/)，然后设置kube-apiserver启动参数：
```
# ca根证书
--client-ca-file=/etc/kubernetes/ssl_keys/ca.crt
# 服务端私钥文件
--tls-private-key-file=/etc/kubernetes/ssl_keys/server.key
# 服务端证书文件
--tls-cert-file=/etc/kubernetes/ssl_keys/server.crt
```
同时，可以关闭非安全端口8080，设置安全端口为6443（默认值）：
```
--insecure-port=0
--secure-port=6443
```
最后重启kube-apiserver

##### 2) 设置kube-controller-manager的客户端证书、私钥和启动参数
```
openssl genrsa -out cs_client.key 2048
openssl req -new -key cs_client.key -subj "/CN=k8s-master" -out cs_client.csr
openssl x509 -req -in cs_client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out cs_client.crt -days 5000

```
复制这些文件到/etc/kubernetes/ssl_keys/
```
cp cs_client.* /etc/kubernetes/ssl_keys/
```

接下来创建/etc/kubernetes/kubeconfig文件（kube-controller-manager与kube-scheduler公用），配置如下：
```yaml
apiVersion: v1
kind: Config
users:
- name: controllermanager
  user:
    client-certificate: /etc/kubernetes/ssl_keys/cs_client.crt
    client-key: /etc/kubernetes/ssl_keys/cs_client.key
clusters:
- name: local
  cluster:
    server: https://192.168.37.150:6443
    certificate-authority: /etc/kubernetes/ssl_keys/ca.crt
contexts:
- context:
    cluster: local
    user: controllermanager
  name: my-context
current-context: my-context
```
然后，设置kube-controlller-manager服务的启动参数，注意，--master的地址为https安全服务地址，敷使用非安全地址http://192.168.37.150:8080：
```sh
--master=https://192.168.37.150:6443
--service-account-private-key-file=/etc/kubernetes/ssl_keys/server.key
--root-ca-file=/etc/kubernetes/ssl_keys/ca.crt
--kuberconfig=/etc/kubernetes/kubeconfig

```
重启kube-controller-manager服务


##### 3) 设置kube-scheduler启动参数
复用kube-controller-manager创建的客户端证书，配置启动参数：
```
--master=https://192.168.37.150:6443
--kuberconfig=/etc/kubernetes/kubeconfig
```
重启kube-scheduler服务

##### 4) 设置每台node上kubelet的客户端证书、私钥和启动参数
复制kube-apiserver的ca.crt和ca.key文件到node节点上
```sh
openssl genrsa -out kubelet_client.key 2048
openssl req -new -key kubelet_client.key -subj "/CN=192.168.37.152" -out kubelet_client.csr
openssl x509 -req -in kubelet_client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kubelet_client.crt -days 5000

```
将上面这些文件复制到一个目录中（如：/etc/）

接下来创建/etc/kubernetes/kubeconfig（kubelet和kube-proxy进程共用），配置如下：
```yaml
apiVersion: v1
kind: Config
users:
- name: controllermanager
  user:
    client-certificate: /etc/kubernetes/ssl_keys/kubelet_client.crt
    client-key: /etc/kubernetes/ssl_keys/kubelet_client.key
clusters:
- name: local
  cluster:
    server: https://192.168.37.150:6443
    certificate-authority: /etc/kubernetes/ssl_keys/ca.crt
contexts:
- context:
    cluster: local
    user: controllermanager
  name: my-context
current-context: my-context

```

设置kubelet启动参数：
```
--api-servers=https://192.168.37.150:6443
--kubeconfig=/etc/kubernetes/kubeconfig
```
重启kubelet服务

##### 5) 设置kube-proxy启动参数
复用上面创建的kubelet证书
```
--master=https://192.168.37.150:6443
--kubeconfig=/etc/kubernetes/kubeconfig
```
重启kube-proxy服务



