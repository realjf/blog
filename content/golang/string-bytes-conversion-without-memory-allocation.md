---
title: "String Bytes Conversion Without Memory Allocation 字符串和[]byte无内存拷贝转换方法"
date: 2023-03-29T18:54:41+08:00
keywords: ["golang"]
categories: ["golang"]
tags: ["golang"]
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

内存拷贝即把一个内存的东西拷贝到另一个内存中。

### []byte to string (no-copy conversion)

```go
func Bytes2String(bytes []byte) (s string) {
 slice := (*reflect.SliceHeader)(unsafe.Pointer(&bytes))
 str := (*reflect.StringHeader)(unsafe.Pointer(&s))
 str.Data = slice.Data
 str.Len = slice.Len
 runtime.KeepAlive(&bytes) // this line is essential.
 return s
}

# 更有效的方式
func Bytes2String(bytes []byte) string {
  return *(*string)(unsafe.Pointer(&bytes))
}

```

### string to []byte

```go
func String2Bytes(s string) (bytes []byte) {
 slice := (*reflect.SliceHeader)(unsafe.Pointer(&bytes))
 str := (*reflect.StringHeader)(unsafe.Pointer(&s))
 slice.Data = str.Data
 slice.Len = str.Len
 runtime.KeepAlive(&s) // this line is essential.
 return bytes
}
```

### 测试

```go

func main() {
 str := "hello world"
 data := String2Bytes(str)
 fmt.Println(data, string(data))

 slices := []byte{'g', 'o', 'p', 'h', 'e', 'r'}
 data2 := Bytes2String(slices)
 fmt.Printf("%s %d", data2, []byte(data2))

}
```
