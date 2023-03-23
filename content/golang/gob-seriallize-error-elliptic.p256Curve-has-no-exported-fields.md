---
title: "Gob Seriallize Error Elliptic.p256Curve Has No Exported Fields(golang v1.20 在gob序列化elliptic.p256Curve结构时出现未导出字段问题)"
date: 2023-03-23T19:03:01+08:00
keywords: ["golang","elliptic","p256","ecdsa"]
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

### 环境

- golang v1.20

### 复现

```go

import (
 "bytes"
 "crypto/ecdsa"
 "crypto/elliptic"
 "crypto/rand"
 "encoding/gob"
 "errors"
 "io"
 "io/ioutil"
 "log"
 "os"
)

const walletFile = "Wallets.dat"

type Wallets struct {
 WalletsMap map[string]*Wallet
}

type Wallet struct {
 PrivateKey ecdsa.PrivateKey
 PublicKey  []byte
}

func (w *Wallets) SaveWallets() {
 var content bytes.Buffer

 gob.Register(elliptic.P256())

 encoder := gob.NewEncoder(&content)
 err := encoder.Encode(&w)
 if err != nil {
  log.Panic(err)
 }

 err = ioutil.WriteFile(walletFile, content.Bytes(), 0644)
 if err != nil {
  log.Panic(err)
 }

}

func NewWallets() (*Wallets, error) {
 if _, err := os.Stat(walletFile); os.IsNotExist(err) {
  wallets := &Wallets{}
  wallets.WalletsMap = make(map[string]*Wallet)
  return wallets, err
 }

 fileContent, err := ioutil.ReadFile(walletFile)
 if err != nil {
  if !errors.Is(err, io.EOF) {
   log.Panic(err)
  }
 }

 wallets := Wallets{
  WalletsMap: make(map[string]*Wallet),
 }
 gob.Register(elliptic.P256())
 decoder := gob.NewDecoder(bytes.NewReader(fileContent))
 err = decoder.Decode(&wallets)
 if err != nil {
  if !errors.Is(err, io.EOF) {
   log.Panic(err)
  }
 }

 return &wallets, nil
}

func NewKeyPair() (ecdsa.PrivateKey, []byte) {
 curve := elliptic.P256()

 private, err := ecdsa.GenerateKey(curve, rand.Reader)
 if err != nil {
  log.Panic(err)
 }

 pub := append(private.PublicKey.X.Bytes(), private.PublicKey.Y.Bytes()...)
 return *private, pub
}

func MakeWallet() *Wallet {
 private, public := NewKeyPair()
 wallet := Wallet{
  PrivateKey: private,
  PublicKey:  public,
 }

 return &wallet
}

func main() {
 wallets, err := NewWallets()
 if err != nil {
  log.Panic(err)
 }
 newWallet := MakeWallet()
 wallets.WalletsMap["1"] = newWallet
 wallets.SaveWallets()
}
```

运行结果如下：

```sh
2023/03/23 19:20:05 gob: type elliptic.p256Curve has no exported fields
panic: gob: type elliptic.p256Curve has no exported fields

```

原因：这个是因为gov1.20里的gob使用反射获取值，而未导出字段不能通过反射获取

### 解决方法

#### 第一种是通过修改go版本为1.18

#### 第二种是通过自定义序列化器进行处理

处理思路是：通过对ecdsa.PrivateKey进行编码处理成字符串后，再通过gob进行序列化，在反序列化时，先通过gob解码，然后再通过自定义解码器解码成ecdsa.PrivateKey结构

具体的编解码器可以参考pem文件的生成方法
