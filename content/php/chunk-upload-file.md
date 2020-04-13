---
title: "大文件分片上传 之 基于webuploader组件（Chunk Upload File）"
date: 2020-04-13T14:00:07+08:00
keywords: ["webuploader"]
categories: ["php"]
tags: ["chunk file", "upload file", "webuploader"]
series: ["chunk file"]
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

针对大文件（上百兆或者好几个G的大文件上传，总是比较麻烦的，这里将介绍一个比较方便的解决方案

## 准备
- 百度的webuploader组件
- lnmp或lamp开发环境


本次使用的是百度分享的分片js组件[webuploader](http://fex.baidu.com/webuploader/)

同时后端使用php接收分片文件，并进行最后的组装。


### 第一步，首先下载webuploader插件

下载地址：https://github.com/fex-team/webuploader/releases

解压后文件结构如下：
```text
├── Uploader.swf                      // SWF文件，当使用Flash运行时需要引入。

├── webuploader.js                    // 完全版本。
├── webuploader.min.js                // min版本

├── webuploader.custom.js                    
├── webuploader.nolog.js                

├── webuploader.flashonly.js          // 只有Flash实现的版本。
├── webuploader.flashonly.min.js      // min版本

├── webuploader.html5only.js          // 只有Html5实现的版本。
├── webuploader.html5only.min.js      // min版本

├── webuploader.withoutimage.js       // 去除图片处理的版本，包括HTML5和FLASH.
└── webuploader.withoutimage.min.js   // min版本
下载
```

### 第二步，创建一个html页面，引入一下文件

```html
<link href="/resource/webuploader/webuploader.css" rel="stylesheet" />
<script src="/resource/webuploader/webuploader.js"></script>

```
页面内容如下：

```html
<div id="uploader" class="wu-example">
                    <div id="uploader" class="wu-example">
                        <!--用来存放文件信息-->
                        <div class="filename"></div>
                        <div class="state"></div>
                        <div class="progress">
                            <div id="progress_bar" class="progress-bar progress-bar-info progress-striped active" role="progressbar" style="width: 0%">
                            </div>
                        </div>
                        <div class="btns">
                            <div id="picker">选择文件</div>
                            <button id="ctlBtn" class="btn btn-default">开始上传</button>
                            <button id="pause" class="btn btn-danger">暂停上传</button>
                        </div>
                    </div>
                </div>
```

### 第三步，js逻辑如下

```js
<script type="text/javascript">
        $(function () {
            var GUID = WebUploader.Base.guid();//一个GUID
            var uploader = WebUploader.create({
                swf: '/resource/webuploader/Uploader.swf',
                server: '<{$save_url}>', // 服务端上传地址
                pick: '#picker',
                chunked: true,//开始分片上传
                chunkSize: 2 *1024 * 1024,   //2M
                fileNumLimit:1,  // 最大上传的文件数量
                fileSizeLimit:1000 * 1024 * 1024, // 总文件大小 1G
                fileSingleSizeLimit:1000 * 1024 * 1024,  // 单个文件大小 1G
                // 不压缩image
                resize: false,
                //只允许选择图片
                accept: {
                    title: 'Video',
                    extensions: 'mp4',
                    mimeTypes: 'video/mp4'
                },
                duplicate :false, //防止多次上传
                formData: {
                    guid: GUID //自定义参数，待会儿解释
                }
            });
            uploader.on('fileQueued', function (file) {
                $("#uploader .filename").html("文件名：" + file.name);
                $("#uploader .state").html('等待上传');
                
                uploader.md5File( file )
                        // 及时显示进度
                        .progress(function(percentage) {
                            console.log('Percentage:', percentage);
                        })
                
                        // 完成
                        .then(function(val) {
                            console.log('md5 result:', val);
                        });
            });
            uploader.on('uploadSuccess', function (file, response) {
                $.post('<{$merge_url}>',  // 服务端最后合并文件地址
                { guid: GUID, fileName: file.name, chunks: response.result.chunks }, function (data) {
                    console.log('已上传');
                });
            });
            uploader.on('uploadProgress', function (file, percentage) {
                $("#progress_bar").css("width", percentage * 100 + '%');
                console.log(percentage);
            });
            uploader.on('uploadSuccess', function () {
                $("#progress_bar").attr("class", "progress-bar progress-bar-success");
                $("#uploader .state").html("上传成功...");
            });
            uploader.on('uploadError', function () {
                $("#progress_bar").attr("class", "progress-bar progress-bar-danger");
                $("#uploader .state").html("上传失败...");
            });

            $("#ctlBtn").click(function () {
                uploader.upload();
                $("#ctlBtn").text("上传");
                $('#ctlBtn').attr('disabled', 'disabled');
                $("#progress_bar").addClass('progress-bar-striped').addClass('active');
                $("#uploader .state").html("上传中...");
            });
            $('#pause').click(function () {
                uploader.stop(true);
                $('#ctlBtn').removeAttr('disabled');
                $("#ctlBtn").text("继续上传");
                $("#uploader .state").html("暂停中...");
                $("#progress_bar").removeClass('progress-bar-striped').removeClass('active');
            });
        });

    </script>

```

### 第四步，服务端php代码

```php
class libChunkUpload
{
    // 上传目录
    const UPLOAD_PATH = "/tmp/upload";

    private $_codeMsg = "100:success";
    private $_result = [];

    public function __construct()
    {

    }

    private function _output($codeMsg = "100:success", $result = [])
    {
        $this->_codeMsg = $codeMsg;
        $this->_result = $result;
        return $this;
    }

    public function response()
    {
        return ["codeMsg" => $this->_codeMsg, "result" => $this->_result];
    }

    /**
     * 上传
     * @return $this
     */
    public function upload()
    {
        // Get 或 file 方式获取文件名
        if (isset($_REQUEST["name"])) {
            $fileName = $_REQUEST["name"];
        } elseif (!empty($_FILES)) {
            $fileName = $_FILES["file"]["name"];
        } else {
            $fileName = uniqid("file_");
        }
        $chunk = isset($_REQUEST["chunk"]) ? intval($_REQUEST["chunk"]) : 0; // 分片序号
        $guid = $_REQUEST["guid"]; // guid
        $uploadDir = self::UPLOAD_PATH;
        $cacheDir = $uploadDir . "/" . $guid; // 临时保存分块目录
        $chunks = isset($_REQUEST["chunks"]) ? intval($_REQUEST["chunks"]) : 1;

        // 验证上传目录是否存在不存在创建
        if (!file_exists($uploadDir)) {
            @mkdir($uploadDir);
        }

        // 验证缓存目录是否存在不存在创建
        if (!file_exists($cacheDir)) {
            @mkdir($cacheDir);
        }

        // 分片文件名
        $filePath = $cacheDir ."/" . $fileName;
        if(file_exists($filePath)){
            return $this->_output("101:文件已存在");
        }

        $data = $_FILES["file"];
        // 保存数据
        if(!($out = @fopen($filePath . "_" . $chunk . ".parttmp", "wb"))){
            return $this->_output("99:打开文件失败");
        }
        if($data){
            if ($data["error"] || !is_uploaded_file($data["tmp_name"])) {
                return $this->_output("101:移动上传文件失败");
            }

            if (!$in = @fopen($data["tmp_name"], "rb")) {
                return $this->_output("101:打开上传文件失败");
            }
        }else{
            if (!$in = @fopen("php://input", "rb")) {
                return $this->_output("101:打开上传文件失败");
            }
        }


        while ($buff = fread($in, 4096)) {
            $res = fwrite($out, $buff);
            if(!$res){
                @fclose($out);
                @fclose($in);
                return $this->_output("98:写入文件失败");
            }
        }
        @fclose($out);
        @fclose($in);

        if(!rename("{$filePath}_{$chunk}.parttmp", "{$filePath}_{$chunk}.part")){
            return $this->_output("99:重命名失败");
        }
        return $this->_output("100:上传成功", ["chunks" => $chunks]);
    }

    /**
     * 合并
     * @return $this
     */
    public function merge()
    {
        $fileName = $_REQUEST["fileName"] ?: "";
        $guid = $_REQUEST["guid"] ?: "";
        $chunks = intval($_REQUEST["chunks"]);
        if(!$fileName || !$guid){
            return $this->_output("101:缺少参数");
        }
        $uploadDir = self::UPLOAD_PATH;
        $cacheDir = $uploadDir . "/" . $guid; // 缓存目录
        $filePath = $cacheDir ."/" . $fileName;

        $pathInfo = pathinfo($fileName);
        $hashStr = substr(md5($pathInfo['basename']),8,16);
        $hashName = time() . $hashStr . '.' .$pathInfo['extension'];
        $uploadPath = $uploadDir . "/" . $hashName;
        if (!$out = @fopen($uploadPath, "wb")) {
            return $this->_output("101:打开写入文件失败");
        }
        if ( flock($out, LOCK_EX) ) {
            for( $index = 0; $index < $chunks ; $index++ ) {
                if (!$in = @fopen("{$filePath}_{$index}.part", "rb")) {
                    break;
                }
                while ($buff = fread($in, 4096)) {
                    fwrite($out, $buff);
                }
                @fclose($in);
                @unlink("{$filePath}_{$index}.part");
            }
            flock($out, LOCK_UN);
        }else{
            @fclose($out);
            @rmdir($cacheDir);
            return $this->_output("99:文件加锁失败");
        }
        @fclose($out);
        @rmdir($cacheDir);

        return $this->_output("100:合并完成", ["tmp_name" => $uploadFile, "name" => $fileName, "type" => "video/mp4"]);
    }
}
```

### FAQ

进度条显示问题：进度条无法显示，一般是样式加载异常问题，可添加如下代码解决
```css
<style>
                .progress {
                    height: 20px;
                    margin-bottom: 20px;
                    overflow: hidden;
                    background-color: #f5f5f5;
                    border-radius: 4px;
                    -webkit-box-shadow: inset 0 1px 2px rgba(0,0,0,0.1);
                    box-shadow: inset 0 1px 2px rgba(0,0,0,0.1);
                }
                .progress.active .progress-bar {
                    -webkit-animation: progress-bar-stripes 2s linear infinite;
                    animation: progress-bar-stripes 2s linear infinite;
                }

                .progress-striped .progress-bar {
                    background-image: linear-gradient(45deg,rgba(255,255,255,0.15) 25%,transparent 25%,transparent 50%,rgba(255,255,255,0.15) 50%,rgba(255,255,255,0.15) 75%,transparent 75%,transparent);
                    background-size: 40px 40px;
                }
                .progress-bar {
                    background-image: -webkit-linear-gradient(top,#428bca 0,#3071a9 100%);
                    background-image: linear-gradient(to bottom,#428bca 0,#3071a9 100%);
                    background-repeat: repeat-x;
                    filter: progid:DXImageTransform.Microsoft.gradient(startColorstr=’#ff428bca’,endColorstr=’#ff3071a9’,GradientType=0);
                }
                .progress-bar {
                    float: left;
                    height: 100%;
                    font-size: 12px;
                    line-height: 20px;
                    color: #fff;
                    text-align: center;
                    background-color: #428bca;
                    box-shadow: inset 0 -1px 0 rgba(0,0,0,0.15);
                    transition: width .6s ease;
                }
            </style>

```


