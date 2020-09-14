---
title: "Oatpp框架简单项目初次启动"
date: 2020-09-14T16:30:24+08:00
keywords: ["cpp", "oatpp"]
categories: ["cpp"]
tags: ["cpp", "oatpp"]
series: [""]
draft: false
toc: false
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

## 准备
- window10系统
- 已配置好c++开发环境的vscode
- visual studio 2019/2017

## 方法一
### 开始
```shell script
# 新建项目目录
mkdir oatpp_example
cd oatpp_example
mkdir src
type null > CMakeLists.txt
type null > src/main.cpp
```
### 写代码
src/main.cpp的内容如下：
```shell script
#include "oatpp/web/server/HttpConnectionHandler.hpp"

#include "oatpp/network/server/Server.hpp"
#include "oatpp/network/server/SimpleTCPConnectionProvider.hpp"

class Handler : public oatpp::web::server::HttpRequestHandler {
    public:
    /**
      * Handle incoming request and return outgoing response.
      */
    std::shared_ptr<OutgoingResponse> handle(const std::shared_ptr<IncomingRequest>& request) override {
    return ResponseFactory::createResponse(Status::CODE_200, "Hello World!");
  }

};


void run() {
    /* Create Router for HTTP requests routing */
    auto router = oatpp::web::server::HttpRouter::createShared();

    /* Route GET - "/hello" requests to Handler */
    router->route("GET", "/hello", std::make_shared<Handler>());

    /* Create HTTP connection handler with router */
    auto connectionHandler = oatpp::web::server::HttpConnectionHandler::createShared(router);

    /* Create TCP connection provider */
    auto connectionProvider = oatpp::network::server::SimpleTCPConnectionProvider::createShared(8000 /*port*/);

    /* Create server which takes provided TCP connection and passes them to HTTP connection handler */
    oatpp::network::server::Server server(connectionProvider, connectionHandler);

    /* Priny info about server port */
    OATPP_LOGI("MyApp", "Server running on port %s", connectionProvider->getProperty("port").getData());

    /* Run server */
    server.run();
}

int main() {
    /* Init oatpp Environment */
    oatpp::base::Environment::init();

    /* Run App */
    run();

    /* Destory oatpp Environment */
    oatpp::base::Environment::destroy();

    return 0;
}
```
接下来是CMakeLists.txt文件，其内容如下:
```shell script
cmake_minimum_required(VERSION 3.1)

set(project_name oatpp_example) ## rename your project here

project(${project_name})

set(CMAKE_CXX_STANDARD 11)

## add executables

add_executable(${project_name} src/main.cpp)

## link libs
find_package(oatpp 1.1.0 REQUIRED)

target_link_libraries(${project_name}
        PUBLIC oatpp::oatpp
        PUBLIC oatpp::oatpp-test
)

```

### 开始编译
```shell script
mkdir build
cd build
cmake ..
```
接下来需要使用visual studio 2019/2017打开build/xxxx.sln文件，然后右击ALL BUILD文件夹，选择生成
即可在build/Debug目录下生成可执行文件

## 方法二
直接使用官方的启动项目搭建
```shell script
# 首先clone下项目
git clone git@github.com:oatpp/oatpp-starter.git

# 然后进入项目根目录
mkdir build
cd build
cmake ..
```
接下来的步骤方法一，直接用visual studio 2019/2017打开build目录下的xxx.sln文件，
然后右击ALL BUILD文件夹，选择生成即可在build/Debug目录下生成可执行文件