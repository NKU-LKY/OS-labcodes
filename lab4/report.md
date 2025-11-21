# 扩展练习
## 1.说明语句local_intr_save(intr_flag);....local_intr_restore(intr_flag);是如何实现开关中断的？
首先概括来说，在进程切换时，需要记住切换前的中断状态。所以通过 flag 参数记住进入临界区前的中断状态，来保证之后能恢复初始的中断状态。当初次进入时中断是开启的，才会重新开启中断，否则仍然保持中断关闭状态。

而为什么一定要保证中断状态为关闭？在进程切换等关键操作中，这是为了确保进程指针更新、页表切换和上下文寄存器恢复这三个关联操作能够原子性地完成，防止在操作执行过程中被中断打断而导致系统状态不一致，比如出现当前进程指针指向新进程但页表仍是旧进程的危险情况，从而保障内核的稳定性和数据一致性。

函数定义在/kern/sync/sync.h中：
```
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}
```

```
static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}
```
读取中断状态：

- read_csr(sstatus) 读取 RISC-V 的 sstatus 控制状态寄存器

- SSTATUS_SIE 是 Supervisor Interrupt Enable 位，表示当前是否允许中断

保存和恢复逻辑：

- __intr_save() 检查当前中断是否启用，如果启用则关闭中断并返回 true

- __intr_restore() 根据保存的状态决定是否重新启用中断

初始状态有两种可能：

```
// 初始状态：中断开启 (SSTATUS_SIE = 1)

bool intr_flag;
local_intr_save(intr_flag);  
// → __intr_save() 检测到中断开启
// → 调用 intr_disable() 关闭中断
// → 返回 true，intr_flag = true

// 执行临界区代码...

local_intr_restore(intr_flag);
// → __intr_restore(true) 
// → 调用 intr_enable() 重新开启中断
```
```
// 初始状态：中断关闭 (SSTATUS_SIE = 0)

bool intr_flag;
local_intr_save(intr_flag);
// → __intr_save() 检测到中断已关闭
// → 直接返回 false，intr_flag = false

// 执行临界区代码...

local_intr_restore(intr_flag);
// → __intr_restore(false)
// → 什么也不做，中断保持关闭状态
```

两函数内调用的intr_disable();和intr_enable;定义在kern/driver/intr.c中
```
// 设置 CSR 的特定位（启用中断）
set_csr(sstatus, SSTATUS_SIE);

// 清除 CSR 的特定位（禁用中断）  
clear_csr(sstatus, SSTATUS_SIE);
```

它们在 proc.c中的proc_run() 函数中被使用:
```
void proc_run(struct proc_struct *proc)
{
    if (proc != current)
    {
        bool intr_flag;
        struct proc_struct *prev = current;

        local_intr_save(intr_flag);  // 关中断
        {
            current = proc;
            lsatp(proc->pgdir);      // 修改页表
            switch_to(&(prev->context), &(proc->context));  // 上下文切换
        }
        local_intr_restore(intr_flag);  // 恢复中断状态
    }
}
```
开关中断的过程如下。

关中断过程：
- local_intr_save(intr_flag) 调用 __intr_save()

- 检查 sstatus 寄存器的 SIE 位：如果为 1（中断开启）：调用 intr_disable() 关闭中断，返回 1；如果为 0（中断已关闭）：直接返回 0

- 将返回值保存到 intr_flag 变量中

开中断过程：
- local_intr_restore(intr_flag) 调用 __intr_restore(intr_flag)

- 如果 intr_flag 为 1（原来中断是开启的）：调用 intr_enable() 重新开启中断

- 如果 intr_flag 为 0（原来中断就是关闭的）：什么也不做

## 2.深入理解不同分页模式的工作原理（思考题）
get_pte()函数（位于kern/mm/pmm.c）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。
### （1）get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
首先概括起来，原因是RISC-V的分页机制采用统一的多级页表设计理念，无论sv32、sv39还是sv48方案，每一级页表的处理逻辑都遵循相同的模式：检查页表项有效性、必要时分配新页表页面、初始化内存并设置权限标志。

而get_pte()函数在干什么？get_pte 函数的主要功能是在页表层次结构中查找或创建指定线性地址对应的页表项(PTE)，并返回该页表项的内核虚拟地址。

(a)查找第一级页目录项 (PDE1)
```
pde_t *pdep1 = &pgdir[PDX1(la)];
    if (!(*pdep1 & PTE_V))
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
```
- 使用 PDX1(la) 从线性地址中提取第一级索引

- 检查该页目录项是否有效(PTE_V)

如果不存在且需要创建：

- 分配物理页面作为第一级页表

- 初始化页面内容为0

- 设置页目录项指向新页表，标记为有效和用户可访问

(b)查找第二级页目录项 (PDE0)
```
pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V))
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
```
- 将第一级页目录项中的物理地址转换为内核虚拟地址

- 使用 PDX0(la) 提取第二级索引

- 检查该页目录项是否有效

如果不存在且需要创建：

- 分配物理页面作为第二级页表

- 初始化页面内容为0

- 设置页目录项指向新页表，标记为有效和用户可访问

(c)返回最终的页表项地址
```
return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
```
- 将第二级页目录项中的物理地址转换为内核虚拟地址

- 使用 PTX(la) 提取页表索引

- 返回最终页表项的内核虚拟地址

sv32，sv39，sv48的异同：
|特性|	sv32	|sv39	|sv48	|说明|
|---------|---------|---------|---------|---------|
|虚拟地址宽度	|32 位	|39 位	|48 位	|sv39/48 是 64 位架构，但并非使用全部 64 位|
|物理地址宽度	|34 位	|56 位	|56 位	|PTE 中 PPN 字段的位数决定|
|页表级数	|2 级	|3 级	|4 级	|为了映射更大的地址空间|
|最大虚拟空间	|4 GiB	|512 GiB	|256 TiB	|由虚拟地址宽度决定|
|页表索引位数	|10 位	|9 位	|9 位	|每一级页表有 2^9 = 512 个表项|
|页内偏移位数	|12 位	|12 位	|12 位	|对应 4KB 页大小|

它们的设计理念和基本结构完全相同。比如：

- 多级页表结构：都使用树形结构的页表进行地址转换。

- 页表项格式：PTE 的格式是基本一致的，包含以下关键字段：

  - PTE_V：有效位，表示该 PTE 是否有效。

  - PTE_R/PTE_W/PTE_X：读/写/执行权限位。

  - PTE_U：用户模式位，用户模式是否可以访问。

  - PPN：物理页号，指向下一级页表或最终物理页的基地址。

- 4KB 页大小：最基本的页面大小都是 4KB。

- 虚拟地址转换流程：转换过程在逻辑上是完全一致的，都是通过多级索引逐级查找。

对于本题来说，所有 RISC-V 分页方案都采用多级页表结构，具有相似的遍历逻辑：

- 从根页表开始

- 逐级解析虚拟地址索引

- 检查有效性标志 (PTE_V)

- 如果不存在则分配新页表

- 最终到达叶子页表项

之所以有两段相似的代码，是因为虽然具体级数不同，但每一级的处理逻辑完全相同：

- 检查有效位

- 必要时分配新页表

- 初始化内存为零

- 设置页表项权限

此外，RISC-V 规范要求所有分页方案(1)使用相同的 PTE 格式(2)使用相同的有效位检查(3)相似的地址转换流程。

### （2）目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

我认为这种写法好，没有必要把两个功能拆开。

一是因为原子性操作。页表查找和分配本质是一个原子操作，拆分会引入竞态条件，万一在执行时中间被插入了一个中断，之后再分配时可能页表已经产生了变化。

二是性能优化。减少函数调用开销，页表操作是性能关键路径，合并设计只需遍历一次页表路径，拆分需要至少两次（查找+分配时重新遍历），更费时间。

三是逻辑完整。"获取页表项"的自然语义就包含"不存在时创建"，或者就是上文中所描述的，页表查找和分配本来就是要连续先后执行的操作。

四是合在一起可以统一错误处理。集中处理分配失败的情况，避免错误码传递。

最后是因为这样调用简洁，使用者无需关心页表是否存在，可以简化上层代码

# 本实验中重要的知识点
(1)进程控制块（PCB/struct proc_struct）

- 实验中的含义：在ucore中用于管理进程/线程的核心数据结构，存储进程的状态、上下文、内存管理信息等

- 对应OS原理知识点：进程控制块

- 关系与差异：实验中的proc_struct实现了原理中PCB的基本功能，但相比理论上的PCB，实现更加具体，包含了特定于RISC-V架构的上下文信息

(2)进程上下文切换

- 实验中的含义：通过switch.S中的switch_to函数保存和恢复寄存器状态，实现进程切换

- 对应OS原理知识点：上下文切换

- 关系与差异：实验通过汇编代码具体实现了原理中描述的上下文保存与恢复过程，体现了从理论到实践的转化

(3)进程创建与fork机制

- 实验中的含义：通过do_fork函数复制当前进程创建新进程

- 对应OS原理知识点：进程创建、fork操作

- 关系与差异：实验实现了简化的fork机制，主要复制栈和trapframe，而原理中的fork包含更完整的资源复制

(4)内核线程管理

- 实验中的含义：创建和管理内核级别的线程

- 对应OS原理知识点：线程概念、内核线程

- 关系与差异：实验中的内核线程相比用户线程具有更高的特权级，可以直接访问内核资源

(5)中断控制

- 实验中的含义：通过local_intr_save/restore实现临界区保护

- 对应OS原理知识点：中断屏蔽、临界区

- 关系与差异：实验提供了具体的中断控制实现，而原理主要关注概念和必要性

# OS原理中很重要但在实验中没有对应上的知识点
(1)用户进程与内核进程的区分

- 原理中强调用户态和内核态的隔离，但本实验主要涉及内核线程，缺少用户进程的创建和管理

(2)进程调度算法

- 原理中讨论了多种调度算法（如FCFS、SJF、优先级调度等），但实验中只有简单的进程切换，没有实现完整的调度策略

(3)进程间通信（IPC）

- 原理中重要的管道、消息队列、共享内存等IPC机制在实验中尚未涉及

(4)进程同步机制

- 虽然有关中断操作，但缺少信号量、互斥锁、条件变量等高级同步机制的具体实现

(5)进程状态模型

- 原理中完整的进程状态转换（就绪、运行、阻塞等）在实验中实现较为简化

(6)死锁处理

- 原理中重要的死预防、避免、检测和恢复机制在实验中没有体现