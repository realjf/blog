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


## 附录
### 主要配置和APIs
#### Activation Events
Activation Events
这个项目定义的是插件打开的时机，可以在以下情况时打开：

- onLanguage： 在打开对应语言文件时
- onCommand： 在执行对应命令时
- onDebug： 在 debug 会话开始前
- onDebugInitialConfigurations： 在初始化 debug 设置前
- onDebugResolve： 在 debug 设置处理完之前
- workspaceContains： 在打开一个文件夹后，如果文件夹内包含设置的文件名模式时
- onFileSystem： 打开的文件或文件夹，是来自于设置的类型或协议时
- onView： 侧边栏中设置的 id 项目展开时
- onUri： 在基于 vscode 或 vscode-insiders 协议的 url 打开时
- onWebviewPanel： 在打开设置的 webview 时
- *： 在打开 vscode 的时候，如果不是必须一般不建议这么设置

官方文档：[activation-events](https://code.visualstudio.com/api/references/activation-events)


#### Contribution Points
官方文档：[contribution-points](https://code.visualstudio.com/api/references/contribution-points)

这个是用来用来描述你所写的插件在哪些地方添加了功能，是什么样的功能，添加的内容会显示到界面上，
前面的 hello world 示例就是在 commands 中添加了相应的 hello world 命令，
然后这个命令就可以在命令窗口执行了




#### APIs
所有的API定义在[vscode.d.ts](https://github.com/Microsoft/vscode/blob/master/src/vs/vscode.d.ts)中

主要有以下各类API:

- [commands](https://code.visualstudio.com/api/references/vscode-api%23commands)
- [comments](https://code.visualstudio.com/api/references/vscode-api%23comments)
- [debug](https://code.visualstudio.com/api/references/vscode-api%23debug)
- [env](https://code.visualstudio.com/api/references/vscode-api%23env)
- [extensions](https://code.visualstudio.com/api/references/vscode-api%23extensions)
- [languages](https://code.visualstudio.com/api/references/vscode-api%23languages)
- [scm](https://code.visualstudio.com/api/references/vscode-api%23scm)
- [tasks](https://code.visualstudio.com/api/references/vscode-api%23tasks)
- [window](https://code.visualstudio.com/api/references/vscode-api%23window)
- [workspace](https://code.visualstudio.com/api/references/vscode-api%23workspace)


#### Unit Test
具体文档可以参考[testing-extension](https://code.visualstudio.com/api/working-with-extensions/testing-extension)

测试插件可以使用 vscode-test API 来做测试。需要给它的 runTests 提供 extensionDevelopmentPath, 
extensionTestsPath 即开发目录和测试文件目录。测试则使用习惯的单元测试框架即可
```javascript
import * as path from "path";

import { runTests } from "vscode-test";

async function main() {
  try {
    // The folder containing the Extension Manifest package.json
    // Passed to `--extensionDevelopmentPath`
    const extensionDevelopmentPath = path.resolve(__dirname, "../../");

    // The path to the extension test script
    // Passed to --extensionTestsPath
    const extensionTestsPath = path.resolve(__dirname, "./suite/index");

    // Download VS Code, unzip it and run the integration test
    await runTests({ extensionDevelopmentPath, extensionTestsPath });
  } catch (err) {
    console.error("Failed to run tests");
    process.exit(1);
  }
}

main();
```






