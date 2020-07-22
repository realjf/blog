---
title: "Protobuf  数据类型"
date: 2019-10-28T15:31:06+08:00
keywords: ["微服务", "rpc", "protobuf"]
categories: ["微服务"]
tags: ["微服务", "microservice", "protobuf", "rpc"]
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

### 基础类型
| .proto类型 | java类型 | c++类型 | 备注 |
| --------| ------| ------| -------|
| double | double | double | |
|float | float | float |
| int32 | int | int32 | 使用可变长编码方式。编码负数时不够高效，如果你的字段可能包含负数，请使用sint32 |
| int64 | long | int64 | 使用可变长编码方式。编码负数时不够高效，如果你的字段可能包含负数，请使用sint64 |
| uint32 | int[1] | uint32 | 总是4个字节，如果数值总是比228大的话，这个类型会比uint32高效 |
| uint64 | long[1] | uint64 | 总是8个字节，如果数值总是比256大的话，这个类型会比uint64高效 |
| sint32 | int | int32 | 使用可变编码方式，有符号的整型值，编码时比通常的int32高效 |
| sint64 | long | int64 | 使用可变长编码方式，有符号的整型值，编码时比通常的int64高效 |
| fixed32 | int[1] | uint32 | 总是4个字节。如果数值总是比总是比228大的话，这个类型会比uint32高效。 |
| fixed64 | long[1] | unit64 | 总是8个字节。如果数值总是比256大的话，这个类型会比uint64高效 |
| sfixed32 | int |int32 | 总是4个字节 |
| sfixed64 | long | int64 | 总是8个字节 |
| bool | boolean | bool | |
| string | String | string | 一个字符串必须是utf-8编码或者7-bit ascii编码的文本 |
| bytes | ByteString | string | 可能包含任意顺序的字节数据 |

### 特殊字段
| 英文 | 中文 | 备注 |
| ----| ----| -----|
| enum | 枚举(数字从零开始) 作用是为字段指定某”预定义值序列” | enum Type {MAN = 0;WOMAN = 1; OTHER= 3;} |
| message | 消息体 | message User{} |
| repeated | 数组/集合 | repeated User users = 1 |
| import | 导入定义 | import "protos/other_protos.proto" |
| // | 注释 | |
| extend | 扩展 | extend User {} |
| package | 包名 | 相当于命名空间，用来防止不同消息类型的命名冲突 |


> protobuf 还建议把经常要传递的值把其字段编码设置为1-15之间的值。

```proto
package tutorial;

option java_package = "com.example.tutorial";
option java_outer_classname = "AddressBookProtos";

message Person {
required string name = 1;
required int32 id = 2;        // Unique ID number for this person.
optional string email = 3;

enum PhoneType {
  MOBILE = 0;
  HOME = 1;
  WORK = 2;
}

message PhoneNumber {
  required string number = 1;
  optional PhoneType type = 2 [default = HOME];
}

repeated PhoneNumber phone = 4;

}

// Our address book file is just one of these.
message AddressBook {
repeated Person person = 1;
}
```

#### 定义message
- Message的嵌套使用可以嵌套定义，也可以采用先定义再使用的方式。
- Message的定义末尾可以采用java方式在不加“;”，也可以采用C++定义方式在末尾加上“;”，这两种方式都兼容，建议采用java定义方式。
- 向.proto文件添加注释，可以使用C/C++/java风格的双斜杠（//） 语法格式。


#### 定义属性
属性定义分为四个部分：标注+类型+属性名+属性顺序号+[默认值]

| 标注 | 类型 | 属性名 | 属性顺序号 | [默认值] |
| ---- | ---| ----| ----| ----|
| required | string | name | =1 | [default=""]; |

##### 标注
标注包括“required”、“optional”、“repeated”三种，其中

- required表示该属性为必选属性，否则对应的message“未初始化”，debug模式下导致断言，release模式下解析失败；
- optional表示该属性为可选属性，不指定，使用默认值（int或者char数据类型默认为0,string默认为空，bool默认为false，嵌套message默认为构造，枚举则为第一个）
- repeated表示该属性为重复字段，可看作是动态数组，类似于C++中的vector。

如果为optional属性，发送端没有包含该属性，则接收端在解析式采用默认值。对于默认值，如果已设置默认值，则采用默认值，如果未设置，则类型特定的默认值为使用，例如string的默认值为””。


## 编译.proto文件
可以通过定义好的.proto文件来生成Java、Python、C++代码，需要基于.proto文件运行protocol buffer编译器protoc。运行的命令如下所示：
```bash
protoc --proto_path=IMPORT_PATH --cpp_out=DST_DIR --java_out=DST_DIR --go_out=DST_DIR path/to/file.proto

```
> MPORT_PATH声明了一个.proto文件所在的具体目录。如果忽略该值，则使用当前目录。如果有多个目录则可以 对--proto_path 写多次，它们将会顺序的被访问并执行导入。-I=IMPORT_PATH是它的简化形式。
  
### 使用技巧
#### 使用bytes而不是string 表示字符串
protobuf的bytes和string都能表示字符串，但是string类型会对字符串做utf8格式校验，而bytes不会，因此使用bytes的编解码效率更高

#### 使用optional而不是required
protobuf的可选字段optional是一个很巧妙的设计，optional字段是可选的，一个optional字段存在与否都不影响proto对象的序列化和反序列化，利用它可以实现数据协议的向后兼容和向前兼容，即以后增加新的字段，或弃用（注意这里是弃用而不是删除）旧字段都不需要修改代码。 

相比optional字段，requried字段要求字段必须存在，否则会导致proto解析失败。一旦某个字段被设计为requried类型，将来随着业务的快速发展可能会成为负担，因此在使用requried类型时一定要慎重。 




