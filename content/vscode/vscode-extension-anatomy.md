---
title: "VSCode扩展开发系列二 之 扩展解析 Vscode Extension Anatomy"
date: 2020-11-24T11:24:01+08:00
keywords: ["vscode", "extension"]
categories: ["vscode"]
tags: ["vscode"]
series: [""]
draft: false
toc: false
related:
  threshold: 80
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

在上一节中我们创建了一个hello world扩展，那么他的工作原理是什么呢？

- 注册onCommand激活事件：onCommand:extension.helloWorld，以便在用户运行Hello World命令时，扩展可激活
- 使用 contributes.commands Contribution Point使命令Hello World在命令调色板中可用，并且绑定一个命令id:extension.helloWorld
- 使用commands.registerCommand vscode api去绑定一个已经被extension.helloWorld的命令id注册的函数绑定

这里需要理解以下概念

- Activation Event：设置扩展激活的时机。位于 package.json 中。
- Contribution Point：设置在 VSCode 中哪些地方添加新功能，也就是这个扩展增强了哪些功能。位于 package.json 中。
- Register：在 extension.ts 中给要写的功能用 vscode.commands.register... 给 Activation Event 或 Contribution Point 中配置的事件绑定方法或者设置监听器。位于入口文件（默认是 extension.ts）的 activate() 函数中。
- [VS Code API](https://code.visualstudio.com/api/references/vscode-api)：你可以在扩展代码中调用的javascript api功能集合


## 扩展文件结构
```shell script
.
├── .vscode
│   ├── launch.json     // Config for launching and debugging the extension
│   └── tasks.json      // Config for build task that compiles TypeScript
├── .gitignore          // Ignore build output and node_modules
├── README.md           // Readable description of your extension's functionality
├── src
│   └── extension.ts    // Extension source code
├── package.json        // Extension manifest
├── tsconfig.json       // TypeScript configuration
```
- launch.json 用于配置vs code调试
- tasks.json 用于定义 vs code Tasks
- tsconfig.json 咨询TypeScript[手册](https://www.typescriptlang.org/docs/handbook/tsconfig-json.html)



## 扩展入口文件
扩展入口文件(extension.ts)导出两个函数：activate和deactivate(停用)

- activate 在你的注册Activation Event发生时执行
- deactivate 在你的扩展变成停用之前给你机会清理







