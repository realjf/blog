---
title: "Scan Qrcode"
date: 2019-09-04T09:28:23+08:00
keywords: ["wechat", "微信公众号", "微信JSSDK", "微信扫一扫"]
categories: ["微信开发者"]
tags: ["微信开发者", "wechat", "微信公众号", "微信JSSDK", "微信扫一扫"]
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

## 网页调用微信JSSDK实现扫一扫功能

### 设置公众号js接口安全域
在公众号后台的，公众号设置，功能设置里


### 配置ip白名单
在公众号后台基本配置里


### 页面引入微信sdkjs代码
[http://res.wx.qq.com/open/js/jweixin-1.2.0.js](http://res.wx.qq.com/open/js/jweixin-1.2.0.js)


### 页面js代码
```js
    // 点击扫一扫按钮事件
    $("#btn-scan").on("click", function () {
        //微信扫一扫 设置
        var _queryString = window.location.search;
        $.ajax({
            type: "post",
            url: "/mobile/user/scanSign",
            data: {query: _queryString},
            success: function (data) {
                var result = data.result;
                wx.config({
                    debug: false, // 调试接口用
                    appId: result.appId,                           //公众号的唯一标识
                    timestamp: "" + result.timestamp,    //生成签名的时间戳
                    nonceStr: result.nonceStr,                  //生成签名的随机串
                    signature: result.signature,              //签名
                    jsApiList: ['scanQRCode']   //需要使用的JS接口列表(我只需要调用扫一扫的接口，如有多个接口用逗号分隔)
                });
            }
        });
    });

    //微信扫一扫处理代码
    wx.ready(function () {
        $("body").off("click", ".j-btn_chat").on("click", ".j-btn_chat", function (e) {

            wx.scanQRCode({
                needResult: 0,   // 默认为0，扫描结果由微信处理，1则直接返回扫描结果，
                scanType: ["qrCode", "barCode"], // 可以指定扫二维码还是一维码，默认二者都有
                success: function (res) {
                    alert("扫描成功：");
                    // alert(res.resultStr);
                    // window.location.href = res.resultStr;
                    //res.resultStr可以获得扫描结果。这里写自己的业务操作代码}

                }
            });

        });
    });

    // 错误处理
    wx.error(function (res) {
        alert("出错了：" + res.errMsg);//这个地方的好处就是wx.config配置错误，会弹出窗口哪里错误，然后根据微信文档查询即可。
    });

```

### 后端生成签名信息接口实现
```php
$url = $_REQUEST[''];
$signPackage = (new JSSDK())->getSignPackage($url);

```
JSSDK实现
```php
class JSSDK
{
    /**
     * 公众号 appid
     * @var string
     */
    private $_appId = "";
    /**
     * 公众号秘钥
     * @var string
     */
    private $_appSecret = "";

    /**
     * accessToken获取地址
     * @var string
     */
    private $_access_token_url = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=%s&secret=%s";

    /**
     * 获取ticket
     * @var string
     */
    private $_api_ticket_url = "https://api.weixin.qq.com/cgi-bin/ticket/getticket?type=jsapi&access_token=%s";

    /**
     * JSSDK constructor.
     */
    public function __construct()
    {

    }

    /**
     * @param $queryString
     * @return array
     */
    public function getSignPackage($url = "")
    {
        $jsapiTicket = $this->_getJsApiTicket();

        // 注意 URL 一定要动态获取，不能 hardcode.
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' || $_SERVER['SERVER_PORT'] == 443) ? "https://" : "http://";
//        $url = "$protocol$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]";
        $_url = $protocol . $_SERVER['HTTP_HOST'] . "your url path ...";
        if(!$url){
            $url = $_url;
        }

        $timestamp = time();
        $nonceStr = $this->_createNonceStr();

        // 这里参数的顺序要按照 key 值ASCII 码升序排序
        $string = sprintf("jsapi_ticket=%s&noncestr=%s&timestamp=%s&url=%s", $jsapiTicket, $nonceStr, $timestamp, $url);

        $signature = sha1($string);

        $signPackage = array(
            "appId" => $this->_appId,
            "nonceStr" => $nonceStr,
            "timestamp" => $timestamp,
            "url" => $url,
            "signature" => $signature,
            "rawString" => $string,
        );

        return $signPackage;
    }

    /**
     * @param int $length
     * @return string
     */
    private function _createNonceStr($length = 16)
    {
        $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        $str = "";
        for ($i = 0; $i < $length; $i++) {
            $str .= substr($chars, mt_rand(0, strlen($chars) - 1), 1);
        }
        return $str;
    }

    /**
     * @return mixed
     */
    private function _getJsApiTicket()
    {
        $data = json_decode($this->_get_php_file("jsapi_ticket.php"));
        if($data->expire_time < time()){
            $accessToken = $this->_getAccessToken();
            $ticket = $this->_getTicket($accessToken);
            if($ticket){
                $data->expire_time = time() + 7000;
                $data->jsapi_ticket = $ticket;
                $this->_setRedisToken("jsapi_ticket.php", json_encode($data));
            }
        }else{
            $ticket = $data->jsapi_ticket;
        }

        return $ticket;
    }

    /**
     * @param $accessToken
     * @return mixed
     */
    private function _getTicket($accessToken)
    {
        $url = sprintf($this->_api_ticket_url, $accessToken);
        $res = \clsCurl::get($url, \clsCurl::RES_TYPE_JSON);
        $ticket = $res["ticket"];
        return $ticket;
    }

    private function _getAccessToken()
    {
        $data = json_decode($this->_getRedisToken("access_token.php"));
        if($data->expire_time < time()){
            $url = sprintf($this->_access_token_url, $this->_appId, $this->_appSecret);
            $res = \clsCurl::get($url, \clsCurl::RES_TYPE_JSON);
            $accessToken = $res["access_token"];
            if($accessToken){
                $data->expire_time = time() + 7000;
                $data->access_token = $accessToken;
                $this->_setRedisToken("access_token.php", json_encode($data));
            }
        }else{
            $accessToken = $data->access_token;
        }

        return $accessToken;
    }

    /**
     * 获取文件
     * @param $filename
     * @return string
     */
    private function _getRedisToken($filename)
    {
        return \Model\mdlBase::instance()->redis("online")->get($filename);
    }

    /**
     * @param $filename
     * @param $content
     */
    private function _setRedisToken($filename, $content)
    {
        return \Model\mdlBase::instance()->redis("online")->set($filename, $content);
    }

    private function _httpGet($url) {
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_TIMEOUT, 500);
        // 为保证第三方服务器与微信服务器之间数据传输的安全性，所有微信接口采用https方式调用，必须使用下面2行代码打开ssl安全校验。
        // 如果在部署过程中代码在此处验证失败，请到 http://curl.haxx.se/ca/cacert.pem 下载新的证书判别文件。
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, true);
        curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, true);
        curl_setopt($curl, CURLOPT_URL, $url);

        $res = curl_exec($curl);
        curl_close($curl);

        return $res;
    }
}
```

以上代码可根据自己实际情况进行调整

