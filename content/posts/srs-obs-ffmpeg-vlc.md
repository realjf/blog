---
title: "Srs Obs FFmpeg Vlc搭建rtmp直播服务，并实现推流拉流"
date: 2019-07-10T16:06:30+08:00
keywords: ["直播架构", "srs", "obs", "ffmpeg", "vlc", "rtmp"]
categories: ["streaming"]
tags: ["直播", "srs", "obs", "ffmpeg", "vlc", "rtmp"]
draft: false
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
## rtmp srs直播服务器搭建

### 准备
- srs 提供直播流服务器
- obs 提供推流服务
- ffmpeg 强大的软件，可作为推流端使用
- vlc 用于播放rtmp直播

### 1. 首先搭建rtmp srs服务器
```bash
git clone https://github.com/ossrs/srs
cd srs/trunk

# 构建srs
./configure && make

# 开启服务
./objs/srs -c conf/srs.conf

# 停止服务
./objs/srs stop

# 重启服务
./objs/srs restart

```

### 2. 安装obs
```bash
apt-get install obs-studio
```
关于obs推流设置[https://obsproject.com/wiki/OBS-Studio-Quickstart](https://obsproject.com/wiki/OBS-Studio-Quickstart)


### 3. 安装vlc
```bash
apt-get install vlc
```
在推流设置完成后，测试推流效果步骤如下：
1. 打开VLC，选择open media->network
2. 在网络协议中输入推流地址，点击play即可


### 4. 安装ffmpeg
```bash
git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
cd ffmpeg

# 编译ffmpeg
./configure && make

# 使用ffmpeg推流
./ffmpeg -re -i /path/to/media_file.mp4 -f flv -y rtmp://DOMAIN:PORT/yourpath

```
关于ffmpeg更多命令[http://ffmpeg.org/documentation.html](http://ffmpeg.org/documentation.html)



