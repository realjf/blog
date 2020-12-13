---
title: "grpc 安装 Set Up"
date: 2020-12-14T04:29:57+08:00
keywords: ["grpc"]
categories: ["grpc"]
tags: ["grpc"]
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

## C++语言grpc安装
### 安装必要软件
- cmake
```shell script
apt install -y cmake
```

安装基础工具
```shell script
apt install -y build-essential autoconf libtool pkg-config
```
 clone grpc仓库及其子模块代码
```shell script
git clone --recurse-submodules -b v1.34.0 https://github.com/grpc/grpc
```
如果期间子模块出错，可以通过如下命令更新
```shell script
cd grpc
git submodule update --init
```
现在开始本地构建和安装grpc及其所有工具
```shell script
$ mkdir -p cmake/build
$ pushd cmake/build
$ cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=/your/grpc/path \
      ../..
$ make -j
$ make install
$ popd
```

最后将grpc/bin目录添加到环境变量PATH中即可使用protoc了
```shell script
export PATH=$PATH:/your/grpc/path/bin
```

### 使用
在源码下载目录的grpc/examples/cpp/helloworld目录下运行如下命令
```shell script
cd grpc/examples/cpp/helloworld
$ mkdir -p cmake/build
$ pushd cmake/build
$ cmake -DCMAKE_PREFIX_PATH=/usr/local/grp ../..
$ make -j
```
构建完毕后，运行服务
```shell script
./greeter_server
```
在另外一个终端运行客户端服务
```shell script
./greeter_client

Greeter received: Hello world
```

到这里说明安装成功

当修改代码后，运行如下命令重新生成代码
```shell script
make -j
```