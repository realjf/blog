---
title: "订单号设计规则 How to Design Order Id"
date: 2020-12-14T15:50:18+08:00
keywords: ["posts"]
categories: ["posts"]
tags: ["posts"]
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

## 订单号的生成规则
订单号一般具有以下特性
- 唯一性（编码不重复）
- 安全性（可校验，不能随意仿造）
- 易读性（易于识别）
- 可扩展性（多业务混合使用，可对新增业务提供支持）
- 防止并发(分布式机器的时间不统一问题，针对编码中包含时间信息的)


## 编码规则一般设定在10~20位左右，常见编码规则
- 业务类型 + 时间戳 + 平台 + 渠道 + 随机码（或自增码）+ 用户id（看情况，可以加入部分）+ 校验码（可选）
- 年月日时分秒 + 用户id
- 年月日时分秒微妙 + 随机码 + 流水号 + 随机码
- 数据库主键自增的id
- 日期+自增长数字的订单号
- 产生随机的订单号
- 字母 + 数字字符串
- twitter的雪花算法，php第三方扩展库[php-snowflake](https://github.com/zh-ang/php-snowflake)（推荐）


## 以下是我自己的已订单生成规则

```php
const TABLE = "order_id"; // 订单id

    /**
     * 生成订单号 bigint最大支持19位
     * 业务号（2位）+ 日期（ymd 6位） + 毫秒（3位）+ 时间信息（His 6位）+ 用户uid（后1位）+ 校验位（1位）
     * @param $appId
     * @param $time
     * @param $uid4Suffix
     * @return string
     */
    private function _generateOrderId($appId, $ptUid)
    {
        if ($appId < 10) {
            // 取app加大到2位
            $appPre = $appId + 10;
        } else if ($appId <= 99) {
            $appPre = $appId;
        } else {
            // 取前2位
            $appPre = substr(strval($appId), 0, 2);
        }
        // uid后1位
        $uidSuffix = substr(strval($ptUid), -1);
        $micro = explode(" ", microtime());
        
        // 故意将年月日和时分秒错开，显得更无规律
        $orderId = sprintf("%02d%06d%03d%06d%01d", $appPre, date('ymd'), intval($micro[0] * 1000), date('His'), $uidSuffix);
        // 校验位（1位）
        $crcMod = crc32($orderId) % 10;
        return sprintf("%s%01d", $orderId, $crcMod);
    }

    public function createOrderId($appId, $ptUid)
    {
        $orderId = $this->_generateOrderId($appId, $ptUid);
        $res = $this->_insertDb($appId, $orderId);
        if(!$res){
            // 可能冲突重试一次
            $orderId = $this->_generateOrderId($appId, $ptUid);
            $res = $this->_insertDb($appId, $orderId);
            if(!$res){
                // @todo 抛出异常或直接返回错误，或者写错误日志
            }
        }
        return $orderId;
    }

    /**
     * 保存到数据库中，通过设置order_id唯一键，可以防止重复
     * @param $appId
     * @param $orderId
     * @return int
     */
    private function _insertDb($appId, $orderId)
    {
        // 入库
        if(!$appId || !$orderId){
            return 0;
        }
        $data = [
            'app_id' => intval($appId),
            'order_id' => intval($orderId),
        ];
        $res =  $this->dbUser()->insert(self::TABLE, $data);
        if($res === FALSE){
            // 订单id入库失败
            // @todo 抛出异常或直接返回错误，或者写错误日志
        }
        return $orderId;
    }

    public function writeLog($msg, $data = [], $uid = 0, $orderId = 0)
    {
        // @todo write log
    }
```



