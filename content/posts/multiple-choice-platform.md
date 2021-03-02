---
title: "mysql多选平台查询条件生成实现 Multiple Choice Platform"
date: 2021-03-02T21:55:35+08:00
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

### 多选平台数值之和查询语句优化


```php
/** 
 *  
 * mysql 数据库设计中，存在一个平台字段保存的是多个平台值相加的数值， 
 * 查询的时候需要使用如下方法生成平台查询字段值即可快速查出对应平台的数据， 
 * 而不必使用数据库按位与计算及or条件等降低查询速度的方式 
 * 
 */
class plat{    
    const PLAT_ALL = 0; // 全部 0b 0    
    const PLAT_ANDROID = 1; // 1b 1<<0    
    const PLAT_IOS = 2; // 10b 1<<1    
    const PLAT_PC = 4; // 100b 1<<2    
    const PLAT_WAP = 8; // 1000b 1<<3    
    const PLAT_BOX_A = 16; // 10000 1<<4 安卓1   
    const PLAT_BOX_I = 32; // 10 0000 1<<5 ios1   
    const PLAT_ADMIN = 64; //100 0000 1<<6 后台    
    const PLAT_OBS = 128; // 1000 0000 1<<7 obs    
    const PLAT_IOS_TOOLS = 256; // 1000 0000 1<<8 助手    
    
    static   $plats = [        
        self::PLAT_ALL       => '全部',        
        self::PLAT_ANDROID   => '安卓',        
        self::PLAT_IOS       => 'IOS',        
        self::PLAT_PC        => 'PC',        
        self::PLAT_WAP       => 'WAP',        
        self::PLAT_BOX_A     => '安卓1',        
        self::PLAT_BOX_I     => 'ios1',        
        self::PLAT_ADMIN     => "后台",        
        self::PLAT_OBS       => 'OBS',        
        self::PLAT_IOS_TOOLS => '助手'    
    ];    
    
    function getPlatformCond($platform, $extCond = []) {        
        $cond = "platform=0";        
        if (!$platform) {            
            return $cond;        
        }        
        $cond = "platform in (0,{$platform})";        
        if ($extCond) {            
            $cond .= " and " . implode(" and ", $extCond);        
        } 

        $platsNum = array_keys(self::$plats);        
        unset($platsNum[0]);        
            
        $platArray = [];        
        // 获取platform平台下的组合数        
        // C(9,1) = $platform        
        $platArray[] = $platform;        
        // C(9,2) = $platform + (1...9)        
        foreach($platsNum as $v){            
            if($platform != $v){                
                $platArray[] = $v+$platform;            
            }        
        }        
        // C(9,3) = $platform + (1...9) + (1...9)        
        foreach($platsNum as $v){            
            foreach($platsNum as $vv){                
                if(count(array_unique([$v, $vv, $platform])) == 3){                    
                    $platArray[] = $platform + $v + $vv;                
                }            
            }        
        }        
        // C(9,4) = $platform + (1...9) + (1...9) + (1...9)        
        foreach($platsNum as $v){            
            foreach($platsNum as $vv){                
                foreach($platsNum as $vvv){                    
                    if(count(array_unique([$v, $vv, $vvv, $platform])) == 4){                        
                        $platArray[] = $platform + $v + $vv + $vvv;                    
                    }                
                }            
            }        
        }        
        // C(9,5) = $platform + (1...9) + (1...9) + (1...9) + (1...9)        
        foreach($platsNum as $v){            
            foreach($platsNum as $vv){                
                foreach($platsNum as $vv){                    
                    foreach($platsNum as $vvvv){                        
                        if(count(array_unique([$v, $vv, $vvv, $vvvv, $platform])) == 5){                            
                            $platArray[] = $platform + $v + $vv + $vvv + $vvvv;                        
                        }                    
                    }                
                }           
            }        
        }               
        // C(9,9) = $platform + (1...9) + (1...9) + (1...9) + (1...9) + (1...9) + (1...9) + (1...9) + (1...9)        
        $C99 = 0;        
        foreach($platsNum as $v){            
            $C99 += $v;        
        }        
        $platArray[] = $C99;        
        // C(9,8) = $platform + (1...9) + (1...9) + (1...9) + (1...9) + (1...9) + (1...9) + (1...9)        
        foreach($platsNum as $v){            
            if(count(array_unique([$v, $platform])) == 2){                
                $platArray[] = $C99 - $v;            
            }        
        }        
        // C(9,7) = $platform + (1...9) + (1...9) + (1...9) + (1...9) + (1...9) + (1...9)        
        foreach($platsNum as $v){            
            foreach($platsNum as $vv){                
                if(count(array_unique([$v, $vv, $platform])) == 3){                    
                    $platArray[] = $C99 - $v - $vv;                
                }            
            }        
        }        
        // C(9,6) = $platform + (1...9) + (1...9) + (1...9) + (1...9) + (1...9)        
        foreach($platsNum as $v){            
            foreach($platsNum as $vv){                
                foreach($platsNum as $vvv){                    
                    if(count(array_unique([$v, $vv, $vvv, $platform])) == 4){                        
                        $platArray[] = $C99 - $v - $vv - $vvv;                    
                    }                
                }            
            }        
        }        
        $platArray = array_values(array_unique($platArray));        
        sort($platArray);
        
        
        return $platArray;    
    }
}

print_r((new plat)->getPlatformCond(64));
```


