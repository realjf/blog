---
title: "nasm汇编之系统调用 System Calls"
date: 2020-05-31T00:53:19+08:00
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

系统调用是用户空间和内核空间之间接口的API。我们已经使用了系统调用。 sys_write和sys_exit，分别用于写入屏幕和退出程序

### linux 系统调用
您可以在汇编程序中使用Linux系统调用。您需要按照以下步骤在程序中使用Linux系统调用

- 将系统调用编号放入EAX寄存器中
- 将系统调用的参数存放到EBX,ECX等寄存器
- 调用相关的中断
- 结果通常在EAX寄存器中返回

有六个寄存器，用于存储所用系统调用的参数。这些是EBX，ECX，EDX，ESI，EDI和EBP。
这些寄存器采用从EBX寄存器开始的连续参数。如果有六个以上的自变量，则第一个自变量的存储位置将存储在EBX寄存器中

以下代码段显示了系统调用sys_exit的使用
```asm
mov	eax,1		; system call number (sys_exit)
int	0x80		; call kernel
```
以下代码段显示了系统调用sys_write的使用
```asm
mov	edx,4		; message length
mov	ecx,msg		; message to write
mov	ebx,1		; file descriptor (stdout)
mov	eax,4		; system call number (sys_write)
int	0x80		; call kernel
```
所有系统调用及其编号（在调用int 80h之前放入EAX的值）都列在/usr/include/asm/unistd.h中

下表显示了使用的一些系统调用

| %eax | name | %ebx | %ecx | %edx | %esx | %edi |
| :---: | :---: | :---:| :---: | :---: | :---: | :---: |
| 1 | sys_exit | int | - | - | - | - |
| 2 | sys_fork | struct pt_regs | - | - | - | - |
| 3 | sys_read | unsigned int | char * | size_t | - | - |
| 4 | sys_write | unsigned int | const char * | size_t | - | - |


### 示例
```asm
section .data                           ;Data segment
   userMsg db 'Please enter a number: ' ;Ask the user to enter a number
   lenUserMsg equ $-userMsg             ;The length of the message
   dispMsg db 'You have entered: '
   lenDispMsg equ $-dispMsg                 

section .bss           ;Uninitialized data
   num resb 5
	
section .text          ;Code Segment
   global _start
	
_start:                ;User prompt
   mov eax, 4
   mov ebx, 1
   mov ecx, userMsg
   mov edx, lenUserMsg
   int 80h

   ;Read and store the user input
   mov eax, 3
   mov ebx, 2
   mov ecx, num  
   mov edx, 5          ;5 bytes (numeric, 1 for sign) of that information
   int 80h
	
   ;Output the message 'The entered number is: '
   mov eax, 4
   mov ebx, 1
   mov ecx, dispMsg
   mov edx, lenDispMsg
   int 80h  

   ;Output the number entered
   mov eax, 4
   mov ebx, 1
   mov ecx, num
   mov edx, 5
   int 80h  
    
   ; Exit code
   mov eax, 1
   mov ebx, 0
   int 80h
```




