# 练习1：理解内核启动中的程序入口操作

## 1. 内核启动概述

在启动内核前，我们需要完成内核的内存布局和入口点设置，这需要：
- 把操作系统加载到内存里
- 规范各区域（.text, .data等）的内存地址范围  
- 明确内核的入口点，类似C程序里的main

## 2. 加载机制

把操作系统加载到内存里不可能由操作系统自己负责，需要由其它程序完成，这个程序在完成"把操作系统加载到内存"后便把CPU控制权交给操作系统。

在QEMU模拟的RISC-V计算机里：
- QEMU会把作为bootloader的OpenSBI.bin被加载到物理内存以物理地址 0x80000000 开头的区域上
- 同时内核镜像os.bin被加载到以物理地址 0x80200000 开头的区域上
- OpenSBI.bin在完成任务后需要把CPU转交给os.bin，即把pc跳转到os.bin的地址

> **注意**：os.bin如果采用随机地址的话，OpenSBI.bin则不知道把pc跳转到哪里；而OpenSBI.bin采用固定位置是因为RISC-V CPU上电后的第一条指令地址是 0x80000000 ，如果OpenSBI不在此地址，CPU无法启动执行。

需要解释的是由于这是QEMU模拟的RISC-V计算机不是真正的计算机，这里的OpenSBI.bin本身不直接加载os.bin，实际是QEMU同时将OpenSBI.bin和os.bin加载到各自固定地址，OpenSBI更像"中间人"而非加载器。

## 3. 文件格式与链接过程

上面提到的bin文件需要由内存布局合适的elf文件通过objcopy转化，可以理解为：
- elf是"压缩包"而bin是"解压文件"
- 两者都是可执行文件，但前者需要在完整的操作系统上执行，而后者可以在底层固件上直接运行

我们需要的是得到内存布局合适的elf文件后交由objcopy转化再加载。

通过编译原理我们知道，可执行文件需要由源代码编译为.o文件再通过链接器转化为可执行文件，链接器会根据链接脚本把.o文件里的section映射到elf文件的section同时规定入口点和内存布局。

## 4. 入口点设置

在实验代码给定的链接脚本里规定了入口点为 kern_entry 以及内存布局，以.text为例，规定入口点在最前，之后由合并的其它代码段组成，接下来我们还需要设置入口点。

首先在entry.S中，使用 .globl 将 kern_entry 声明为全局符号，其他文件（如链接脚本）可以引用它。

la sp, bootstacktop ：将 bootstacktop 这个符号所代表的内核栈顶部的位置加载到栈指针寄存器 sp 中。

entry.S中， bootstack 是一块内存区域的开始（低地址）， bootstacktop 是这块区域的结束（高地址）。将 sp 设置为 bootstacktop ，正好符合栈从高向低生长的约定以及为之后跳转到 kern_init 做准备。

tail kern_init ：跳转到 kern_init 所在的地址去执行，与标准的函数调用指令 jal 不同， tail 用于尾调用优化，是一个函数的最后一条指令，可以理解为"我去调用那个函数，但你不必返回到我这里来了"。

跳转之后操作系统便进入了C语言的环境下，标志将CPU的执行流正式交给了操作系统的C语言主程序。

整体来看la sp, bootstacktop负责搭建栈为C函数调用做准备，tail kern_init则负责转移cpu的操控权，使用tail表示在正常运行中这次转移是彻底的，不需要考虑返回。

# 练习2: 使用GDB验证启动流程
## 1. 调试过程及观察结果
首先打开lab1下的终端，输入命令make debug，启动qemu。之后新建一个终端，输入命令make gdb，但出现了报错。
```
lky-os@kai-VMware-Virtual-Platform:~/桌面/labcodes/lab1$ make gdb
riscv64-unknown-elf-gdb \
    -ex 'file bin/kernel' \
    -ex 'set arch riscv:rv64' \
    -ex 'target remote localhost:1234'
make: riscv64-unknown-elf-gdb: 没有那个文件或目录
make: *** [Makefile:177：gdb] 错误 127
```
查询得知，该错误是因为系统找不到 RISC-V 64 位的 GDB 调试器。riscv64-unknown-elf-gdb 没有安装或者不在系统的 PATH 环境变量中。而先前输入命令查找时是能找到gdb的bin文件的，说明是PATH环境变量的问题。但是将工具链路径添加到 PATH 后，仍然没有解决问题，因此选择直接修改Makefile文件，在开头设置 PATH。
```
export PATH := /mnt/hgfs/share/riscv-elf-toolchains/bin:$(PATH)
```
之后执行make gdb命令，并成功连接上qemu。得到以下输出。
```
The target architecture is set to "riscv:rv64".
Remote debugging using localhost:1234
0x0000000000001000 in ?? ()
```
对内核入口的kern_entry函数下断点。
```
(gdb) b* kern_entry
Breakpoint 1 at 0x80200000: file kern/init/entry.S, line 7.
```
随后输入continue继续运行，但发现长时间都没有输出，直接ctrl c终止进程，发现输出：
```
Program received signal SIGINT, Interrupt.
0x0000000080000428 in ?? ()
```
可以看出程序运行在 0x80000428，这是 QEMU 的 BIOS/引导代码区域，还未运行到预期的kern_entry函数，这可能意味着内核没有被正确加载到 0x80200000。

直接强制跳转到kern_entry函数地址，遇到断点停止，看似得到了预期输出，但输入i r查询各个寄存器值时发现，所有的寄存器显示的都是0x0，表明 CPU 还没有开始执行任何代码。

之后连续多次执行continue，并ctrl c终止，发现显示的地址始终都位于BIOS 代码区域，而执行 x/10x 0x80200000，能看到内核已经正确加载到内存中，那么就说明应该是QEMU 的 BIOS 引导代码没有自动跳转到内核入口点，可能是进入了死循环。

根据大模型的建议，将Makefile中的设置进行修改，qemu目标和debug目标都需要修改：
```
# 原本的加载方式
-device loader,file=$(UCOREIMG),addr=0x80200000
# 修改后的加载方式
-kernel $(UCOREIMG) \  # 改为 -kernel 参数
```
之后重新操作实验指导书中的步骤，可以得到预期的输出。

关于这么修改的原因，可能是-kernel 参数的工作方式是QEMU 加载 OpenSBI 到 0x80000000，并告诉 OpenSBI："内核在 bin/kernel，入口点是 0x80200000"，OpenSBI 初始化后，主动跳转到 0x80200000。而-device loader 参数的工作方式是QEMU 加载 OpenSBI 到 0x80000000，并静默地把内核二进制数据拷贝到 0x80200000，OpenSBI 不知道这个操作，继续执行自己的代码，在它初始化完成后，不知道要跳转到哪里。

在continue后，成功在断点处停止：
```
(gdb) c
Continuing.

Breakpoint 1, kern_entry () at kern/init/entry.S:7
7           la sp, bootstacktop
```
执行i r，也能看到各个寄存器都有了数值，而不是清一色的0x0，比如pc寄存器：
```
pc             0x80200000       0x80200000 <kern_entry>
```
以及ra (返回地址): 0x8000ae9a；sp (栈指针): 0x80046eb0 （已有初始栈）等等。同时可见RISC-V拥有大量的通用寄存器（t0-t6, a0-a7, s1-s11等）。

接着多次si单步执行，得到以下输出，可以发现开始执行的两条正是练习一中要求分析的两条指令，在这之后会进入内核初始化函数，开始清除BSS段：
```
(gdb) si
0x0000000080200004 in kern_entry () at kern/init/entry.S:7
7           la sp, bootstacktop
(gdb) si
9           tail kern_init
(gdb) si
kern_init () at kern/init/init.c:8
8           memset(edata, 0, end - edata);
(gdb) si
0x000000008020000e      8           memset(edata, 0, end - edata);
(gdb) si
0x0000000080200012      8           memset(edata, 0, end - edata);
```

## 2. RISC-V 硬件加电后最初执行的几条指令的地址
### 1. CPU复位初始化 (0x1000)
```
0x0000000000001000 in ?? ()
```
0x1000是RISC-V标准的复位向量地址，这里储存着OpenSBI固件的汇编启动代码，它们负责设置最基础的CPU状态，初始化关键硬件（如中断控制器、定时器），并建立最小可用的执行环境。
### 2. SBI固件主初始化
SBI固件的主要工作有：内存控制器初始化，设备树解析，将内核镜像从存储设备加载到 0x80200000，设置内核启动参数等等。
```
(gdb) print/x *0x80200000
$1 = 0x3117
```
执行到断点处时，使用以上命令输出0x80200000的值，可以看到加载了0x3117这么一个RISC-V指令，查询得知，它是一个 auipc (Add Upper Immediate to PC) 指令的编码，这是RISC-V内核启动代码的典型第一条指令。
### 3. 控制权移交内核 (0x80200000)
内核入口点的初始任务是：设置栈指针 (la sp, bootstacktop)，为C代码执行准备运行环境，尾调用跳转到kern_init。

使用以下命令，可以得到从0x80200000开始的五条命令：
```
(gdb) x/5i 0x80200000
=> 0x80200000 <kern_entry>:     auipc   sp,0x3
   0x80200004 <kern_entry+4>:   mv      sp,sp
   0x80200008 <kern_entry+8>:   j       0x8020000a <kern_init>
   0x8020000a <kern_init>:      auipc   a0,0x3
   0x8020000e <kern_init+4>:    addi    a0,a0,-2
```
例如第一条指令Add Upper Immediate to PC，它会将立即数0x3左移12位后加到PC值，结果存入sp寄存器，计算sp = PC + (0x3 << 12) = 0x80200000 + 0x3000 = 0x80203000，这么做的目的是设置初始栈指针，指向栈区域的顶部。

以及第三条指令会无条件直接跳转到kern_init函数（C语言入口点），0x8020000a就是下一条指令的位置。

总之，根据GDB调试输出的信息，RISC-V硬件加电后最初执行的几条指令位于地址0x0000000000001000处，这个地址是RISC-V架构定义的固定复位向量地址。当CPU加电启动时，程序计数器(PC)首先指向0x1000位置，从这里开始执行初始化固件（通常是OpenSBI）的汇编代码，进行最基础的硬件初始化工作，包括设置CPU状态、初始化中断控制器和定时器等关键硬件组件，为后续加载操作系统内核建立基本的运行环境。