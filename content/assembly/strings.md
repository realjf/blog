---
title: "nasm汇编之字符串 Strings"
date: 2020-05-31T03:23:28+08:00
keywords: ["assembly"]
categories: ["assembly"]
tags: ["assembly"]
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

可变长度的字符串可以根据需要包含任意多个字符。通常，我们通过两种方式之一指定字符串的长度

- 显式存储字符串长度
- 使用前哨角色

我们可以使用表示位置计数器当前值的$位置计数器符号来显式存储字符串长度
```asm
msg  db  'Hello, world!',0xa ;our dear string
len  equ  $ - msg            ;length of our dear string
```
$指向字符串变量msg的最后一个字符之后的字节。因此，$-msg给出字符串的长度。我们也可以写
```asm
msg db 'Hello, world!',0xa ;our dear string
len equ 13                 ;length of our dear string
```
另外，您可以存储带有尾部定点字符的字符串来分隔字符串，而不必显式存储字符串长度。
前哨字符应为不出现在字符串中的特殊字符。

例如：
```asm
message DB 'I am loving it!', 0
```

### 字符串指令
每个字符串指令可能需要一个源操作数，一个目标操作数或两者。对于32位段，字符串指令使用ESI和EDI寄存器分别指向源和目标操作数

但是，对于16位段，SI和DI寄存器分别用于指向源和目标。

有五个用于处理字符串的基本说明

- MOVS 该指令将1字节，字或双字数据从存储器位置移到另一个位置。
- LODS 该指令从存储器加载。如果操作数是一个字节，则将其加载到AL寄存器中；如果操作数是一个字，则将其加载到AX寄存器中，并将双字加载到EAX寄存器中
- STOS 该指令将数据从寄存器（AL，AX或EAX）存储到存储器。
- CMPS 该指令比较存储器中的两个数据项。数据可以是字节大小，字或双字。
- SCAS 该指令将寄存器（AL，AX或EAX）的内容与存储器中项目的内容进行比较。

上面的每个指令都有字节，字和双字版本，并且可以通过使用重复前缀来重复字符串指令

这些指令使用ES：DI和DS：SI对寄存器，其中DI和SI寄存器包含有效的偏移地址，这些地址指向存储在存储器中的字节。
SI通常与DS（数据段）相关联，DI通常与ES（额外段）相关联。

DS：SI（或ESI）和ES：DI（或EDI）寄存器分别指向源和目标操作数。假定源操作数位于内存中的DS：SI（或ESI），目标操作数位于ES：DI（或EDI）。

对于16位地址，使用SI和DI寄存器，对于32位地址，使用ESI和EDI寄存器

下表提供了各种版本的字符串指令和假定的操作数空间

| 基础指令 | 操作 | 字节操作 | 字操作 | 双字操作 |
|:---:|:---:|:---:|:---:|:---:|
| MOVS | ES:DI, DS:SI|	MOVSB	|MOVSW|	MOVSD|
|LODS	|AX, DS:SI|	LODSB	|LODSW	|LODSD|
|STOS	|ES:DI, AX|	STOSB	|STOSW	|STOSD|
|CMPS	|DS:SI, ES: DI|	CMPSB|	CMPSW|	CMPSD|
|SCAS	|ES:DI, AX|	SCASB	|SCASW	|SCASD|

### 重复前缀
REP前缀在字符串指令（例如-REP MOVSB）之前设置时，会根据放置在CX寄存器中的计数器使该指令重复。
REP执行该指令，将CX减1，然后检查CX是否为零。重复指令处理，直到CX为零为止。

方向标志（DF）确定操作方向

- 使用CLD（清除方向标志，DF = 0）使操作从左到右。
- 使用STD（设置方向标志，DF = 1）使操作从右到左。

REP前缀也有以下变化

- REP：这是无条件的重复。重复该操作，直到CX为零为止。
- REPE或REPZ：这是有条件的重复。当零标志指示等于/零时，它将重复操作。当ZF表示不等于零或CX为零时，它将停止。
- REPNE或REPNZ：这也是有条件的重复。当零标志指示不等于/零时，它将重复操作。当ZF指示等于/零或CX减为零时，它将停止。













