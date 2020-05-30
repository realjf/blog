---
title: "nasm汇编之基础语法 Basic Syntax"
date: 2020-05-31T00:20:08+08:00
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

一个汇编程序可以被分成三个sections：

- data section
- bss section
- text section

### data section
data 部分用于声明初始化的数据或常量。该数据在运行时不会更改。您可以在本节中声明各种常量值，文件名或缓冲区大小等
```asm
section .data
```

### bss section
bss部分用于声明变量。声明bss部分的语法是
```asm 
section .bss
```


### text section
text部分用于保留实际代码。此section必须以全局声明_start开头，该声明告诉内核程序从何处开始执行。
```asm
section .text
    global _start
_start:

```

### 注释
```asm
; this is a comment

mov a, b  ; move b to a
```

### statements
```asm
[label] mnemonic [operands] [;comment]
```

### hello world示例
```asm
section	.text
   global _start     ;must be declared for linker (ld)
	
_start:	            ;tells linker entry point
   mov	edx,len     ;message length
   mov	ecx,msg     ;message to write
   mov	ebx,1       ;file descriptor (stdout)
   mov	eax,4       ;system call number (sys_write)
   int	0x80        ;call kernel
	
   mov	eax,1       ;system call number (sys_exit)
   int	0x80        ;call kernel

section	.data
msg db 'Hello, world!', 0xa  ;string to be printed
len equ $ - msg     ;length of the string
```

