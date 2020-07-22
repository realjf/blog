---
title: "安装flutter开发环境 Set Up flutter"
date: 2020-05-10T11:53:15+08:00
keywords: ["flutter"]
categories: ["flutter"]
tags: ["flutter"]
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

### 获取安装flutter sdk

```shell script
wget https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_1.17.0-stable.tar.xz

tar xf ~/Downloads/flutter_linux_1.17.0-stable.tar.xz
```
或者直接从github下载也可以
```shell script
git clone https://github.com/flutter/flutter.git -b stable
```

添加flutter到你的path环境变量
```shell script
export PATH="$PATH:`pwd`/flutter/bin"
```

最后提前预下载相关依赖包
```shell script
flutter precache
```

下载完成后，检查相关环境是否安装成功
```shell script
flutter doctor
```

检查过程中可能遇到的问题
```shell script
[-] Android toolchain - develop for Android devices
    • Android SDK at /Users/obiwan/Library/Android/sdk
    ✗ Android SDK is missing command line tools; download from https://goo.gl/XxQghQ
    • Try re-installing or updating your Android SDK,
      visit https://flutter.dev/setup/#android-setup for detailed instructions.
```
这是android sdk未安装，可以直接下载安装，然后通过以下命令更新
```shell script
flutter doctor --android-licenses
```

最后，如果你使用android studio或者vscode，需要提前下载相应的插件dart和flutter以及kotlin，
同时，android studio还需要在settings里配置flutter sdk路径，同时需要安装相应的安卓模拟器
