---
title: "汇编语言之linux系统调用接口"
date: 2020-05-31T08:13:52+08:00
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

### syscalls
Syscall是用户程序和Linux内核之间的接口。它们用于让内核执行各种系统任务，例如文件访问，进程管理和联网。
在C编程语言中，您通常会调用包装函数，该函数执行所有必需的步骤，甚至使用高级功能（例如标准IO库）。

在Linux上，有几种方法可以进行系统调用。该页面将重点介绍通过使用int $ 0x80或syscall调用软件中断来进行syscall。这是在仅汇编程序中进行系统调用的简单直观的方法

### 系统调用
为了使用中断进行系统调用，您必须通过将所有必需的信息复制到通用寄存器中来将其传递给内核

每个系统调用都有一个固定的数字（注意：数字在int $ 0x80和系统调用之间有所不同！）。您可以通过将数字写入eax / rax寄存器来指定系统调用。

大多数系统调用都使用参数来执行其任务。通过在进行实际调用之前将它们写入适当的寄存器中来传递这些参数。
每个参数索引都有一个特定的寄存器。请参阅小节中的表，因为int $ 0x80和syscall之间的映射不同。参数按照它们在相应C包装函数的函数签名中出现的顺序传递
您可以在每个Linux API文档中找到syscall函数及其签名，例如参考手册（键入man 2 open以查看打开的syscall的签名）。

一切设置正确后，您可以使用int $ 0x80或syscall调用中断，内核将执行任务

系统调用的返回/错误值被写入eax / rax。

> 内核使用自己的堆栈来执行操作。不会以任何方式触摸用户堆栈。

#### int 0x80
在Linux x86和Linux x86_64系统上，都可以使用int $ 0x80命令调用中断0x80进行系统调用。通过如下设置通用寄存器来传递参数：

|Syscall #	|Param 1|	Param 2|	Param 3|	Param 4|	Param 5|	Param 6|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|eax|	ebx|	ecx|	edx|	esi|	edi|	ebp|

|Return value|
|:---:|
|eax|

系统调用号在Linux生成的文件$ build / arch / x86 / include / generated / uapi / asm / unistd_32.h或$ build / usr / include / asm / unistd_32.h中进行了描述。
后者也可以出现在您的Linux系统上，只是省略$ build。

在系统调用期间，所有寄存器都将保留

#### syscall
x86_64体系结构引入了进行系统调用的专用指令。它不访问中断描述符表，并且速度更快。通过如下设置通用寄存器来传递参数：

|Syscall #	|Param 1	|Param 2	|Param 3	|Param 4	|Param 5	|Param 6|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|rax	|rdi	|rsi	|rdx	|r10	|r8	|r9|

|Return value|
|:---:|
|rax|

Linux生成的文件$ build / usr / include / asm / unistd_64.h中描述了系统调用号。该文件也可以出现在Linux系统上，只是省略$ build。

除rcx和r11（以及返回值rax）外，所有寄存器都在系统调用期间保留。

#### library call
在调用Linux的库函数时，将参数4传递给RCX，并将其他参数传递到堆栈上。

|Param 1	|Param 2	|Param 3	|Param 4	|Param 5	|Param 6|
|:---:|:---:|:---:|:---:|:---:|:---:|
|rdi	|rsi	|rdx	|rcx	|r8	|r9|

### 示例
一个简单的helloworld程序

开始都一样
```asm
.data
msg: .ascii "Hello World\n"

.text
.global _start
```
接下来不一样

##### int 0x80
```asm
_start:
    movl $4, %eax   ; use the write syscall
    movl $1, %ebx   ; write to stdout
    movl $msg, %ecx ; use string "Hello World"
    movl $12, %edx  ; write 12 characters
    int $0x80       ; make syscall
    
    movl $1, %eax   ; use the _exit syscall
    movl $0, %ebx   ; error code 0
    int $0x80       ; make syscall
```

##### syscall
```asm
_start:
    movq $1, %rax   ; use the write syscall
    movq $1, %rdi   ; write to stdout
    movq $msg, %rsi ; use string "Hello World"
    movq $12, %rdx  ; write 12 characters
    syscall         ; make syscall
    
    movq $60, %rax  ; use the _exit syscall
    movq $0, %rdi   ; error code 0
    syscall         ; make syscall
```

##### library call
这是示例库函数的C原型。
```c
Window XCreateWindow(display, parent, x, y, width, height, border_width, depth, 
                       class, visual, valuemask, attributes)
```
参数的传递与int $ 0x80示例中的传递相同，不同之处在于寄存器的顺序不同。

库函数在源文件的开始处声明（以及在编译链接时库的路径）。
```c
extern XCreateWindow
```

```asm
mov rdi, [xserver_pdisplay]
		mov rsi, [xwin_parent]
		mov rdx, [xwin_x]
		mov rcx, [xwin_y]
		mov r8, [xwin_width]
		mov r9, [xwin_height]
		mov rax, attributes
		push rax				; ARG 12
		sub rax, rax
		mov eax, [xwin_valuemask]
		push rax				; ARG 11
		mov rax, [xwin_visual]
		push rax				; ARG 10
		mov rax, [xwin_class]
		push rax				; ARG 9
		mov rax, [xwin_depth]
		push rax				; ARG 8
		mov rax, [xwin_border_width]
		push rax				; ARG 7
		call XCreateWindow
		mov [xwin_window], rax
```
请注意，将函数的最后一个参数压入堆栈是按相反的顺序进行的。

