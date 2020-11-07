---
title: "Vagrantfile"
date: 2020-10-11T04:48:38+08:00
keywords: ["devtools", "vagrantfile"]
categories: ["devtools"]
tags: ["devtools", "vagrantfile"]
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

### 配置版本
配置版本是一种机制，通过该机制，Vagrant 1.1+可以 与Vagrant 1.0.x Vagrantfiles保持向后兼容，同时引入了许多新功能和配置选项

现在运行vagrant init，其格式如下：
```vagrant
Vagrant.configure("2") do |config|
  # ...
end
```
其中的2代表配置的版本的号


可以同时使用版本1和版本2的特性，最终它们将合并在一起使用
```vagrant
Vagrant.configure("1") do |config|
  # v1 configs...
end

Vagrant.configure("2") do |config|
  # v2 configs...
end
```

### 最小版本
这个可以限制太新或者太旧的版本，但是此版本限制必须放在vagrantfile文件最前面，
并通过vagrant.require_version 指定
```vagrant
Vagrant.require_version ">= 1.3.5"
```
上述限制将让vagrantfile文件只在 大于等于vagrant 1.3.5版本时加载

也可以指定多版本限制
```vagrant
Vagrant.require_version ">= 1.3.5", "< 1.4.0"
```

### 循环vm定义
```vagrant
(1..3).each do |i|
  config.vm.define "node-#{i}" do |node|
    node.vm.provision "shell",
      inline: "echo hello from node #{i}"
  end
end
```
以上的each结构时使用副本进行迭代，所以不会出错，但是如果使用以下结构，将会使所有node的text相同
```vagrant

# THIS DOES NOT WORK!
for i in 1..3 do
  config.vm.define "node-#{i}" do |node|
    node.vm.provision "shell",
      inline: "echo hello from node #{i}"
  end
end
```

### 重写ssh会话中的host locale变量
通常，host locale环境变量传递给客户机，但是可能客户机不支持，所以可以使用以下解决方法
```vagrant
ENV["LC_ALL"] = "en_US.UTF-8"

Vagrant.configure("2") do |config|
  # ...
end

```
该变量只在Vagrantfile中可见

### 配置空间 config.vm
#### 可用配置
- config.vm.allow_fstab_modification (boolean) 

- config.vm.allow_hosts_modification (boolean)

- config.vm.base_mac (string)

- config.vm.base_address (string)

- config.vm.boot_timeout (integer)



