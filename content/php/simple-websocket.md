---
title: "php websocket简单使用 Simple Websocket"
date: 2020-06-13T18:14:12+08:00
keywords: ["php", "websocket"]
categories: ["php"]
tags: ["php", "websocket"]
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

### 环境准备
- php 7
- linux 系统

### 服务端 websocket.php 文件
```php
<?php

$address = '0.0.0.0';
$port = 8000;

// 创建socket
$server = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
socket_set_option($server, SOL_SOCKET, SO_REUSEADDR, 1);
socket_bind($server, $address, $port);
socket_listen($server);
$client = socket_accept($server);

//  发送websokcet握手 header
$request = socket_read($client, 5000); // 读取数据
preg_match('#Sec-WebSocket-Key: (.*)\r\n#', $request, $matches);
$key = base64_encode(pack(
    'H*',
    sha1($matches[1] . '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')
));

$headers = "HTTP/1.1 101 Switching Protocols\r\n";
$headers .= "Upgrade: websocket\r\n";
$headers .= "Connection: Upgrade\r\n";
$headers .= "Sec-WebSocket-Version: 13\r\n";
$headers .= "Sec-WebSocket-Accept: $key\r\n\r\n";
socket_write($client, $headers, strlen($headers));

// 循环发送websocket消息
while (true) {
    sleep(1);
    $content = '当前时间戳: ' . time();
    $response = chr(129) . chr(strlen($content)) . $content;
    socket_write($client, $response);
}
```

### 客户端 index.html 文件
```html
<html>
 <body>
     <div id="root"></div>
     <script>
         var host = 'ws://0.0.0.0:8000/websocket.php';
         var socket = new WebSocket(host);
         socket.onmessage = function(e) {
             document.getElementById('root').innerHTML = e.data;
         };
     </script>
 </body>
 </html>
```

### 启动
```shell script
# 启动websocket服务器
php -q websocket.php

# 在另一个terminal启动客户端
php -S 0.0.0.0:6000 index.html
```

### 测试
在web浏览器中打开http://0.0.0.0:6000可以查看到客户端接受到的数据

