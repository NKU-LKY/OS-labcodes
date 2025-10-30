
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00007517          	auipc	a0,0x7
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0207028 <free_area>
ffffffffc020005c:	00007617          	auipc	a2,0x7
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02074a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16 # ffffffffc0205ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	73f010ef          	jal	ffffffffc0201faa <memset>
    dtb_init();
ffffffffc0200070:	410000ef          	jal	ffffffffc0200480 <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	3fe000ef          	jal	ffffffffc0200472 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	f4850513          	addi	a0,a0,-184 # ffffffffc0201fc0 <etext+0x4>
ffffffffc0200080:	094000ef          	jal	ffffffffc0200114 <cputs>

    print_kerninfo();
ffffffffc0200084:	0ee000ef          	jal	ffffffffc0200172 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	780000ef          	jal	ffffffffc0200808 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	768010ef          	jal	ffffffffc02017f4 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	778000ef          	jal	ffffffffc0200808 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	39c000ef          	jal	ffffffffc0200430 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	764000ef          	jal	ffffffffc02007fc <intr_enable>

    asm("mret");
ffffffffc020009c:	30200073          	mret
    asm("ebreak");
ffffffffc02000a0:	9002                	ebreak

    /* do nothing */
    while (1)
ffffffffc02000a2:	a001                	j	ffffffffc02000a2 <kern_init+0x4e>

ffffffffc02000a4 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000a4:	1141                	addi	sp,sp,-16
ffffffffc02000a6:	e022                	sd	s0,0(sp)
ffffffffc02000a8:	e406                	sd	ra,8(sp)
ffffffffc02000aa:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000ac:	3c8000ef          	jal	ffffffffc0200474 <cons_putc>
    (*cnt) ++;
ffffffffc02000b0:	401c                	lw	a5,0(s0)
}
ffffffffc02000b2:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000b4:	2785                	addiw	a5,a5,1
ffffffffc02000b6:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b8:	6402                	ld	s0,0(sp)
ffffffffc02000ba:	0141                	addi	sp,sp,16
ffffffffc02000bc:	8082                	ret

ffffffffc02000be <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000be:	1101                	addi	sp,sp,-32
ffffffffc02000c0:	862a                	mv	a2,a0
ffffffffc02000c2:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c4:	00000517          	auipc	a0,0x0
ffffffffc02000c8:	fe050513          	addi	a0,a0,-32 # ffffffffc02000a4 <cputch>
ffffffffc02000cc:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ce:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000d0:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000d2:	195010ef          	jal	ffffffffc0201a66 <vprintfmt>
    return cnt;
}
ffffffffc02000d6:	60e2                	ld	ra,24(sp)
ffffffffc02000d8:	4532                	lw	a0,12(sp)
ffffffffc02000da:	6105                	addi	sp,sp,32
ffffffffc02000dc:	8082                	ret

ffffffffc02000de <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000de:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000e0:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc02000e4:	f42e                	sd	a1,40(sp)
ffffffffc02000e6:	f832                	sd	a2,48(sp)
ffffffffc02000e8:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ea:	862a                	mv	a2,a0
ffffffffc02000ec:	004c                	addi	a1,sp,4
ffffffffc02000ee:	00000517          	auipc	a0,0x0
ffffffffc02000f2:	fb650513          	addi	a0,a0,-74 # ffffffffc02000a4 <cputch>
ffffffffc02000f6:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000f8:	ec06                	sd	ra,24(sp)
ffffffffc02000fa:	e0ba                	sd	a4,64(sp)
ffffffffc02000fc:	e4be                	sd	a5,72(sp)
ffffffffc02000fe:	e8c2                	sd	a6,80(sp)
ffffffffc0200100:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200102:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200104:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200106:	161010ef          	jal	ffffffffc0201a66 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020010a:	60e2                	ld	ra,24(sp)
ffffffffc020010c:	4512                	lw	a0,4(sp)
ffffffffc020010e:	6125                	addi	sp,sp,96
ffffffffc0200110:	8082                	ret

ffffffffc0200112 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200112:	a68d                	j	ffffffffc0200474 <cons_putc>

ffffffffc0200114 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200114:	1101                	addi	sp,sp,-32
ffffffffc0200116:	ec06                	sd	ra,24(sp)
ffffffffc0200118:	e822                	sd	s0,16(sp)
ffffffffc020011a:	87aa                	mv	a5,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020011c:	00054503          	lbu	a0,0(a0)
ffffffffc0200120:	c905                	beqz	a0,ffffffffc0200150 <cputs+0x3c>
ffffffffc0200122:	e426                	sd	s1,8(sp)
ffffffffc0200124:	00178493          	addi	s1,a5,1
ffffffffc0200128:	8426                	mv	s0,s1
    cons_putc(c);
ffffffffc020012a:	34a000ef          	jal	ffffffffc0200474 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020012e:	00044503          	lbu	a0,0(s0)
ffffffffc0200132:	87a2                	mv	a5,s0
ffffffffc0200134:	0405                	addi	s0,s0,1
ffffffffc0200136:	f975                	bnez	a0,ffffffffc020012a <cputs+0x16>
    (*cnt) ++;
ffffffffc0200138:	9f85                	subw	a5,a5,s1
    cons_putc(c);
ffffffffc020013a:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc020013c:	0027841b          	addiw	s0,a5,2
ffffffffc0200140:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc0200142:	332000ef          	jal	ffffffffc0200474 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200146:	60e2                	ld	ra,24(sp)
ffffffffc0200148:	8522                	mv	a0,s0
ffffffffc020014a:	6442                	ld	s0,16(sp)
ffffffffc020014c:	6105                	addi	sp,sp,32
ffffffffc020014e:	8082                	ret
    cons_putc(c);
ffffffffc0200150:	4529                	li	a0,10
ffffffffc0200152:	322000ef          	jal	ffffffffc0200474 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200156:	4405                	li	s0,1
}
ffffffffc0200158:	60e2                	ld	ra,24(sp)
ffffffffc020015a:	8522                	mv	a0,s0
ffffffffc020015c:	6442                	ld	s0,16(sp)
ffffffffc020015e:	6105                	addi	sp,sp,32
ffffffffc0200160:	8082                	ret

ffffffffc0200162 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200162:	1141                	addi	sp,sp,-16
ffffffffc0200164:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200166:	316000ef          	jal	ffffffffc020047c <cons_getc>
ffffffffc020016a:	dd75                	beqz	a0,ffffffffc0200166 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020016c:	60a2                	ld	ra,8(sp)
ffffffffc020016e:	0141                	addi	sp,sp,16
ffffffffc0200170:	8082                	ret

ffffffffc0200172 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200172:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200174:	00002517          	auipc	a0,0x2
ffffffffc0200178:	e6c50513          	addi	a0,a0,-404 # ffffffffc0201fe0 <etext+0x24>
void print_kerninfo(void) {
ffffffffc020017c:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020017e:	f61ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200182:	00000597          	auipc	a1,0x0
ffffffffc0200186:	ed258593          	addi	a1,a1,-302 # ffffffffc0200054 <kern_init>
ffffffffc020018a:	00002517          	auipc	a0,0x2
ffffffffc020018e:	e7650513          	addi	a0,a0,-394 # ffffffffc0202000 <etext+0x44>
ffffffffc0200192:	f4dff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200196:	00002597          	auipc	a1,0x2
ffffffffc020019a:	e2658593          	addi	a1,a1,-474 # ffffffffc0201fbc <etext>
ffffffffc020019e:	00002517          	auipc	a0,0x2
ffffffffc02001a2:	e8250513          	addi	a0,a0,-382 # ffffffffc0202020 <etext+0x64>
ffffffffc02001a6:	f39ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001aa:	00007597          	auipc	a1,0x7
ffffffffc02001ae:	e7e58593          	addi	a1,a1,-386 # ffffffffc0207028 <free_area>
ffffffffc02001b2:	00002517          	auipc	a0,0x2
ffffffffc02001b6:	e8e50513          	addi	a0,a0,-370 # ffffffffc0202040 <etext+0x84>
ffffffffc02001ba:	f25ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001be:	00007597          	auipc	a1,0x7
ffffffffc02001c2:	2e258593          	addi	a1,a1,738 # ffffffffc02074a0 <end>
ffffffffc02001c6:	00002517          	auipc	a0,0x2
ffffffffc02001ca:	e9a50513          	addi	a0,a0,-358 # ffffffffc0202060 <etext+0xa4>
ffffffffc02001ce:	f11ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001d2:	00007797          	auipc	a5,0x7
ffffffffc02001d6:	6cd78793          	addi	a5,a5,1741 # ffffffffc020789f <end+0x3ff>
ffffffffc02001da:	00000717          	auipc	a4,0x0
ffffffffc02001de:	e7a70713          	addi	a4,a4,-390 # ffffffffc0200054 <kern_init>
ffffffffc02001e2:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e4:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001e8:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ea:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001ee:	95be                	add	a1,a1,a5
ffffffffc02001f0:	85a9                	srai	a1,a1,0xa
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	e8e50513          	addi	a0,a0,-370 # ffffffffc0202080 <etext+0xc4>
}
ffffffffc02001fa:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001fc:	b5cd                	j	ffffffffc02000de <cprintf>

ffffffffc02001fe <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001fe:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200200:	00002617          	auipc	a2,0x2
ffffffffc0200204:	eb060613          	addi	a2,a2,-336 # ffffffffc02020b0 <etext+0xf4>
ffffffffc0200208:	04d00593          	li	a1,77
ffffffffc020020c:	00002517          	auipc	a0,0x2
ffffffffc0200210:	ebc50513          	addi	a0,a0,-324 # ffffffffc02020c8 <etext+0x10c>
void print_stackframe(void) {
ffffffffc0200214:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200216:	1bc000ef          	jal	ffffffffc02003d2 <__panic>

ffffffffc020021a <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020021a:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020021c:	00002617          	auipc	a2,0x2
ffffffffc0200220:	ec460613          	addi	a2,a2,-316 # ffffffffc02020e0 <etext+0x124>
ffffffffc0200224:	00002597          	auipc	a1,0x2
ffffffffc0200228:	edc58593          	addi	a1,a1,-292 # ffffffffc0202100 <etext+0x144>
ffffffffc020022c:	00002517          	auipc	a0,0x2
ffffffffc0200230:	edc50513          	addi	a0,a0,-292 # ffffffffc0202108 <etext+0x14c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200234:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200236:	ea9ff0ef          	jal	ffffffffc02000de <cprintf>
ffffffffc020023a:	00002617          	auipc	a2,0x2
ffffffffc020023e:	ede60613          	addi	a2,a2,-290 # ffffffffc0202118 <etext+0x15c>
ffffffffc0200242:	00002597          	auipc	a1,0x2
ffffffffc0200246:	efe58593          	addi	a1,a1,-258 # ffffffffc0202140 <etext+0x184>
ffffffffc020024a:	00002517          	auipc	a0,0x2
ffffffffc020024e:	ebe50513          	addi	a0,a0,-322 # ffffffffc0202108 <etext+0x14c>
ffffffffc0200252:	e8dff0ef          	jal	ffffffffc02000de <cprintf>
ffffffffc0200256:	00002617          	auipc	a2,0x2
ffffffffc020025a:	efa60613          	addi	a2,a2,-262 # ffffffffc0202150 <etext+0x194>
ffffffffc020025e:	00002597          	auipc	a1,0x2
ffffffffc0200262:	f1258593          	addi	a1,a1,-238 # ffffffffc0202170 <etext+0x1b4>
ffffffffc0200266:	00002517          	auipc	a0,0x2
ffffffffc020026a:	ea250513          	addi	a0,a0,-350 # ffffffffc0202108 <etext+0x14c>
ffffffffc020026e:	e71ff0ef          	jal	ffffffffc02000de <cprintf>
    }
    return 0;
}
ffffffffc0200272:	60a2                	ld	ra,8(sp)
ffffffffc0200274:	4501                	li	a0,0
ffffffffc0200276:	0141                	addi	sp,sp,16
ffffffffc0200278:	8082                	ret

ffffffffc020027a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020027a:	1141                	addi	sp,sp,-16
ffffffffc020027c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020027e:	ef5ff0ef          	jal	ffffffffc0200172 <print_kerninfo>
    return 0;
}
ffffffffc0200282:	60a2                	ld	ra,8(sp)
ffffffffc0200284:	4501                	li	a0,0
ffffffffc0200286:	0141                	addi	sp,sp,16
ffffffffc0200288:	8082                	ret

ffffffffc020028a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020028a:	1141                	addi	sp,sp,-16
ffffffffc020028c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020028e:	f71ff0ef          	jal	ffffffffc02001fe <print_stackframe>
    return 0;
}
ffffffffc0200292:	60a2                	ld	ra,8(sp)
ffffffffc0200294:	4501                	li	a0,0
ffffffffc0200296:	0141                	addi	sp,sp,16
ffffffffc0200298:	8082                	ret

ffffffffc020029a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020029a:	7115                	addi	sp,sp,-224
ffffffffc020029c:	f15a                	sd	s6,160(sp)
ffffffffc020029e:	8b2a                	mv	s6,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002a0:	00002517          	auipc	a0,0x2
ffffffffc02002a4:	ee050513          	addi	a0,a0,-288 # ffffffffc0202180 <etext+0x1c4>
kmonitor(struct trapframe *tf) {
ffffffffc02002a8:	ed86                	sd	ra,216(sp)
ffffffffc02002aa:	e9a2                	sd	s0,208(sp)
ffffffffc02002ac:	e5a6                	sd	s1,200(sp)
ffffffffc02002ae:	e1ca                	sd	s2,192(sp)
ffffffffc02002b0:	fd4e                	sd	s3,184(sp)
ffffffffc02002b2:	f952                	sd	s4,176(sp)
ffffffffc02002b4:	f556                	sd	s5,168(sp)
ffffffffc02002b6:	ed5e                	sd	s7,152(sp)
ffffffffc02002b8:	e962                	sd	s8,144(sp)
ffffffffc02002ba:	e566                	sd	s9,136(sp)
ffffffffc02002bc:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002be:	e21ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002c2:	00002517          	auipc	a0,0x2
ffffffffc02002c6:	ee650513          	addi	a0,a0,-282 # ffffffffc02021a8 <etext+0x1ec>
ffffffffc02002ca:	e15ff0ef          	jal	ffffffffc02000de <cprintf>
    if (tf != NULL) {
ffffffffc02002ce:	000b0563          	beqz	s6,ffffffffc02002d8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002d2:	855a                	mv	a0,s6
ffffffffc02002d4:	714000ef          	jal	ffffffffc02009e8 <print_trapframe>
ffffffffc02002d8:	00003c17          	auipc	s8,0x3
ffffffffc02002dc:	b68c0c13          	addi	s8,s8,-1176 # ffffffffc0202e40 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002e0:	00002917          	auipc	s2,0x2
ffffffffc02002e4:	ef090913          	addi	s2,s2,-272 # ffffffffc02021d0 <etext+0x214>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e8:	00002497          	auipc	s1,0x2
ffffffffc02002ec:	ef048493          	addi	s1,s1,-272 # ffffffffc02021d8 <etext+0x21c>
        if (argc == MAXARGS - 1) {
ffffffffc02002f0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002f2:	00002a97          	auipc	s5,0x2
ffffffffc02002f6:	eeea8a93          	addi	s5,s5,-274 # ffffffffc02021e0 <etext+0x224>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fa:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02002fc:	00002b97          	auipc	s7,0x2
ffffffffc0200300:	f04b8b93          	addi	s7,s7,-252 # ffffffffc0202200 <etext+0x244>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200304:	854a                	mv	a0,s2
ffffffffc0200306:	2db010ef          	jal	ffffffffc0201de0 <readline>
ffffffffc020030a:	842a                	mv	s0,a0
ffffffffc020030c:	dd65                	beqz	a0,ffffffffc0200304 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030e:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200312:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200314:	e59d                	bnez	a1,ffffffffc0200342 <kmonitor+0xa8>
    if (argc == 0) {
ffffffffc0200316:	fe0c87e3          	beqz	s9,ffffffffc0200304 <kmonitor+0x6a>
ffffffffc020031a:	00003d17          	auipc	s10,0x3
ffffffffc020031e:	b26d0d13          	addi	s10,s10,-1242 # ffffffffc0202e40 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200322:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200324:	6582                	ld	a1,0(sp)
ffffffffc0200326:	000d3503          	ld	a0,0(s10)
ffffffffc020032a:	40b010ef          	jal	ffffffffc0201f34 <strcmp>
ffffffffc020032e:	c53d                	beqz	a0,ffffffffc020039c <kmonitor+0x102>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200330:	2405                	addiw	s0,s0,1
ffffffffc0200332:	0d61                	addi	s10,s10,24
ffffffffc0200334:	ff4418e3          	bne	s0,s4,ffffffffc0200324 <kmonitor+0x8a>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200338:	6582                	ld	a1,0(sp)
ffffffffc020033a:	855e                	mv	a0,s7
ffffffffc020033c:	da3ff0ef          	jal	ffffffffc02000de <cprintf>
    return 0;
ffffffffc0200340:	b7d1                	j	ffffffffc0200304 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200342:	8526                	mv	a0,s1
ffffffffc0200344:	451010ef          	jal	ffffffffc0201f94 <strchr>
ffffffffc0200348:	c901                	beqz	a0,ffffffffc0200358 <kmonitor+0xbe>
ffffffffc020034a:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020034e:	00040023          	sb	zero,0(s0)
ffffffffc0200352:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200354:	d1e9                	beqz	a1,ffffffffc0200316 <kmonitor+0x7c>
ffffffffc0200356:	b7f5                	j	ffffffffc0200342 <kmonitor+0xa8>
        if (*buf == '\0') {
ffffffffc0200358:	00044783          	lbu	a5,0(s0)
ffffffffc020035c:	dfcd                	beqz	a5,ffffffffc0200316 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc020035e:	033c8a63          	beq	s9,s3,ffffffffc0200392 <kmonitor+0xf8>
        argv[argc ++] = buf;
ffffffffc0200362:	003c9793          	slli	a5,s9,0x3
ffffffffc0200366:	08078793          	addi	a5,a5,128
ffffffffc020036a:	978a                	add	a5,a5,sp
ffffffffc020036c:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200370:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200374:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200376:	e591                	bnez	a1,ffffffffc0200382 <kmonitor+0xe8>
ffffffffc0200378:	bf79                	j	ffffffffc0200316 <kmonitor+0x7c>
ffffffffc020037a:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020037e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200380:	d9d9                	beqz	a1,ffffffffc0200316 <kmonitor+0x7c>
ffffffffc0200382:	8526                	mv	a0,s1
ffffffffc0200384:	411010ef          	jal	ffffffffc0201f94 <strchr>
ffffffffc0200388:	d96d                	beqz	a0,ffffffffc020037a <kmonitor+0xe0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	00044583          	lbu	a1,0(s0)
ffffffffc020038e:	d5c1                	beqz	a1,ffffffffc0200316 <kmonitor+0x7c>
ffffffffc0200390:	bf4d                	j	ffffffffc0200342 <kmonitor+0xa8>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	8556                	mv	a0,s5
ffffffffc0200396:	d49ff0ef          	jal	ffffffffc02000de <cprintf>
ffffffffc020039a:	b7e1                	j	ffffffffc0200362 <kmonitor+0xc8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020039c:	00141793          	slli	a5,s0,0x1
ffffffffc02003a0:	97a2                	add	a5,a5,s0
ffffffffc02003a2:	078e                	slli	a5,a5,0x3
ffffffffc02003a4:	97e2                	add	a5,a5,s8
ffffffffc02003a6:	6b9c                	ld	a5,16(a5)
ffffffffc02003a8:	865a                	mv	a2,s6
ffffffffc02003aa:	002c                	addi	a1,sp,8
ffffffffc02003ac:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003b0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003b2:	f40559e3          	bgez	a0,ffffffffc0200304 <kmonitor+0x6a>
}
ffffffffc02003b6:	60ee                	ld	ra,216(sp)
ffffffffc02003b8:	644e                	ld	s0,208(sp)
ffffffffc02003ba:	64ae                	ld	s1,200(sp)
ffffffffc02003bc:	690e                	ld	s2,192(sp)
ffffffffc02003be:	79ea                	ld	s3,184(sp)
ffffffffc02003c0:	7a4a                	ld	s4,176(sp)
ffffffffc02003c2:	7aaa                	ld	s5,168(sp)
ffffffffc02003c4:	7b0a                	ld	s6,160(sp)
ffffffffc02003c6:	6bea                	ld	s7,152(sp)
ffffffffc02003c8:	6c4a                	ld	s8,144(sp)
ffffffffc02003ca:	6caa                	ld	s9,136(sp)
ffffffffc02003cc:	6d0a                	ld	s10,128(sp)
ffffffffc02003ce:	612d                	addi	sp,sp,224
ffffffffc02003d0:	8082                	ret

ffffffffc02003d2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003d2:	00007317          	auipc	t1,0x7
ffffffffc02003d6:	06e30313          	addi	t1,t1,110 # ffffffffc0207440 <is_panic>
ffffffffc02003da:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003de:	715d                	addi	sp,sp,-80
ffffffffc02003e0:	ec06                	sd	ra,24(sp)
ffffffffc02003e2:	f436                	sd	a3,40(sp)
ffffffffc02003e4:	f83a                	sd	a4,48(sp)
ffffffffc02003e6:	fc3e                	sd	a5,56(sp)
ffffffffc02003e8:	e0c2                	sd	a6,64(sp)
ffffffffc02003ea:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003ec:	020e1c63          	bnez	t3,ffffffffc0200424 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003f0:	4785                	li	a5,1
ffffffffc02003f2:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003f6:	e822                	sd	s0,16(sp)
ffffffffc02003f8:	103c                	addi	a5,sp,40
ffffffffc02003fa:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003fc:	862e                	mv	a2,a1
ffffffffc02003fe:	85aa                	mv	a1,a0
ffffffffc0200400:	00002517          	auipc	a0,0x2
ffffffffc0200404:	e1850513          	addi	a0,a0,-488 # ffffffffc0202218 <etext+0x25c>
    va_start(ap, fmt);
ffffffffc0200408:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020040a:	cd5ff0ef          	jal	ffffffffc02000de <cprintf>
    vcprintf(fmt, ap);
ffffffffc020040e:	65a2                	ld	a1,8(sp)
ffffffffc0200410:	8522                	mv	a0,s0
ffffffffc0200412:	cadff0ef          	jal	ffffffffc02000be <vcprintf>
    cprintf("\n");
ffffffffc0200416:	00002517          	auipc	a0,0x2
ffffffffc020041a:	e2250513          	addi	a0,a0,-478 # ffffffffc0202238 <etext+0x27c>
ffffffffc020041e:	cc1ff0ef          	jal	ffffffffc02000de <cprintf>
ffffffffc0200422:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200424:	3de000ef          	jal	ffffffffc0200802 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200428:	4501                	li	a0,0
ffffffffc020042a:	e71ff0ef          	jal	ffffffffc020029a <kmonitor>
    while (1) {
ffffffffc020042e:	bfed                	j	ffffffffc0200428 <__panic+0x56>

ffffffffc0200430 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200430:	1141                	addi	sp,sp,-16
ffffffffc0200432:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200434:	02000793          	li	a5,32
ffffffffc0200438:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043c:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200440:	67e1                	lui	a5,0x18
ffffffffc0200442:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200446:	953e                	add	a0,a0,a5
ffffffffc0200448:	267010ef          	jal	ffffffffc0201eae <sbi_set_timer>
}
ffffffffc020044c:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020044e:	00007797          	auipc	a5,0x7
ffffffffc0200452:	fe07bd23          	sd	zero,-6(a5) # ffffffffc0207448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200456:	00002517          	auipc	a0,0x2
ffffffffc020045a:	dea50513          	addi	a0,a0,-534 # ffffffffc0202240 <etext+0x284>
}
ffffffffc020045e:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200460:	b9bd                	j	ffffffffc02000de <cprintf>

ffffffffc0200462 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200462:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200466:	67e1                	lui	a5,0x18
ffffffffc0200468:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046c:	953e                	add	a0,a0,a5
ffffffffc020046e:	2410106f          	j	ffffffffc0201eae <sbi_set_timer>

ffffffffc0200472 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200472:	8082                	ret

ffffffffc0200474 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200474:	0ff57513          	zext.b	a0,a0
ffffffffc0200478:	21d0106f          	j	ffffffffc0201e94 <sbi_console_putchar>

ffffffffc020047c <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020047c:	24d0106f          	j	ffffffffc0201ec8 <sbi_console_getchar>

ffffffffc0200480 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200480:	711d                	addi	sp,sp,-96
    cprintf("DTB Init\n");
ffffffffc0200482:	00002517          	auipc	a0,0x2
ffffffffc0200486:	dde50513          	addi	a0,a0,-546 # ffffffffc0202260 <etext+0x2a4>
void dtb_init(void) {
ffffffffc020048a:	ec86                	sd	ra,88(sp)
ffffffffc020048c:	e8a2                	sd	s0,80(sp)
    cprintf("DTB Init\n");
ffffffffc020048e:	c51ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200492:	00007597          	auipc	a1,0x7
ffffffffc0200496:	b6e5b583          	ld	a1,-1170(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc020049a:	00002517          	auipc	a0,0x2
ffffffffc020049e:	dd650513          	addi	a0,a0,-554 # ffffffffc0202270 <etext+0x2b4>
ffffffffc02004a2:	c3dff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004a6:	00007417          	auipc	s0,0x7
ffffffffc02004aa:	b6240413          	addi	s0,s0,-1182 # ffffffffc0207008 <boot_dtb>
ffffffffc02004ae:	600c                	ld	a1,0(s0)
ffffffffc02004b0:	00002517          	auipc	a0,0x2
ffffffffc02004b4:	dd050513          	addi	a0,a0,-560 # ffffffffc0202280 <etext+0x2c4>
ffffffffc02004b8:	c27ff0ef          	jal	ffffffffc02000de <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004bc:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004be:	00002517          	auipc	a0,0x2
ffffffffc02004c2:	dda50513          	addi	a0,a0,-550 # ffffffffc0202298 <etext+0x2dc>
    if (boot_dtb == 0) {
ffffffffc02004c6:	12070d63          	beqz	a4,ffffffffc0200600 <dtb_init+0x180>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004ca:	57f5                	li	a5,-3
ffffffffc02004cc:	07fa                	slli	a5,a5,0x1e
ffffffffc02004ce:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004d0:	431c                	lw	a5,0(a4)
ffffffffc02004d2:	f456                	sd	s5,40(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d4:	00ff0637          	lui	a2,0xff0
ffffffffc02004d8:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004dc:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e4:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e8:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02004ec:	6ac1                	lui	s5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ee:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f0:	8ec9                	or	a3,a3,a0
ffffffffc02004f2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004f6:	1afd                	addi	s5,s5,-1 # ffff <kern_entry-0xffffffffc01f0001>
ffffffffc02004f8:	0157f7b3          	and	a5,a5,s5
ffffffffc02004fc:	8dd5                	or	a1,a1,a3
ffffffffc02004fe:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200500:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200504:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200506:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8a4d>
ffffffffc020050a:	0ef59f63          	bne	a1,a5,ffffffffc0200608 <dtb_init+0x188>
ffffffffc020050e:	471c                	lw	a5,8(a4)
ffffffffc0200510:	4754                	lw	a3,12(a4)
ffffffffc0200512:	fc4e                	sd	s3,56(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200514:	0087d99b          	srliw	s3,a5,0x8
ffffffffc0200518:	0086d41b          	srliw	s0,a3,0x8
ffffffffc020051c:	0186951b          	slliw	a0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200520:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200524:	0187959b          	slliw	a1,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200528:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052c:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200530:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200534:	0109999b          	slliw	s3,s3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200538:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053c:	8c71                	and	s0,s0,a2
ffffffffc020053e:	00c9f9b3          	and	s3,s3,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200542:	01156533          	or	a0,a0,a7
ffffffffc0200546:	0086969b          	slliw	a3,a3,0x8
ffffffffc020054a:	0105e633          	or	a2,a1,a6
ffffffffc020054e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200552:	8c49                	or	s0,s0,a0
ffffffffc0200554:	0156f6b3          	and	a3,a3,s5
ffffffffc0200558:	00c9e9b3          	or	s3,s3,a2
ffffffffc020055c:	0157f7b3          	and	a5,a5,s5
ffffffffc0200560:	8c55                	or	s0,s0,a3
ffffffffc0200562:	00f9e9b3          	or	s3,s3,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200566:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200568:	1982                	slli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020056a:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020056c:	0209d993          	srli	s3,s3,0x20
ffffffffc0200570:	e4a6                	sd	s1,72(sp)
ffffffffc0200572:	e0ca                	sd	s2,64(sp)
ffffffffc0200574:	ec5e                	sd	s7,24(sp)
ffffffffc0200576:	e862                	sd	s8,16(sp)
ffffffffc0200578:	e466                	sd	s9,8(sp)
ffffffffc020057a:	e06a                	sd	s10,0(sp)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020057c:	f852                	sd	s4,48(sp)
    int in_memory_node = 0;
ffffffffc020057e:	4b81                	li	s7,0
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200580:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200582:	99ba                	add	s3,s3,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200584:	00ff0cb7          	lui	s9,0xff0
        switch (token) {
ffffffffc0200588:	4c0d                	li	s8,3
ffffffffc020058a:	4911                	li	s2,4
ffffffffc020058c:	4d05                	li	s10,1
ffffffffc020058e:	4489                	li	s1,2
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200590:	0009a703          	lw	a4,0(s3)
ffffffffc0200594:	00498a13          	addi	s4,s3,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200598:	0087569b          	srliw	a3,a4,0x8
ffffffffc020059c:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a0:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a4:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a8:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005ac:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ae:	0196f6b3          	and	a3,a3,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005b2:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005b6:	8fd5                	or	a5,a5,a3
ffffffffc02005b8:	00eaf733          	and	a4,s5,a4
ffffffffc02005bc:	8fd9                	or	a5,a5,a4
ffffffffc02005be:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005c0:	09878263          	beq	a5,s8,ffffffffc0200644 <dtb_init+0x1c4>
ffffffffc02005c4:	00fc6963          	bltu	s8,a5,ffffffffc02005d6 <dtb_init+0x156>
ffffffffc02005c8:	05a78963          	beq	a5,s10,ffffffffc020061a <dtb_init+0x19a>
ffffffffc02005cc:	00979763          	bne	a5,s1,ffffffffc02005da <dtb_init+0x15a>
ffffffffc02005d0:	4b81                	li	s7,0
ffffffffc02005d2:	89d2                	mv	s3,s4
ffffffffc02005d4:	bf75                	j	ffffffffc0200590 <dtb_init+0x110>
ffffffffc02005d6:	ff278ee3          	beq	a5,s2,ffffffffc02005d2 <dtb_init+0x152>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005da:	00002517          	auipc	a0,0x2
ffffffffc02005de:	d8650513          	addi	a0,a0,-634 # ffffffffc0202360 <etext+0x3a4>
ffffffffc02005e2:	afdff0ef          	jal	ffffffffc02000de <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005e6:	64a6                	ld	s1,72(sp)
ffffffffc02005e8:	6906                	ld	s2,64(sp)
ffffffffc02005ea:	79e2                	ld	s3,56(sp)
ffffffffc02005ec:	7a42                	ld	s4,48(sp)
ffffffffc02005ee:	7aa2                	ld	s5,40(sp)
ffffffffc02005f0:	6be2                	ld	s7,24(sp)
ffffffffc02005f2:	6c42                	ld	s8,16(sp)
ffffffffc02005f4:	6ca2                	ld	s9,8(sp)
ffffffffc02005f6:	6d02                	ld	s10,0(sp)
ffffffffc02005f8:	00002517          	auipc	a0,0x2
ffffffffc02005fc:	da050513          	addi	a0,a0,-608 # ffffffffc0202398 <etext+0x3dc>
}
ffffffffc0200600:	6446                	ld	s0,80(sp)
ffffffffc0200602:	60e6                	ld	ra,88(sp)
ffffffffc0200604:	6125                	addi	sp,sp,96
    cprintf("DTB init completed\n");
ffffffffc0200606:	bce1                	j	ffffffffc02000de <cprintf>
}
ffffffffc0200608:	6446                	ld	s0,80(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020060a:	7aa2                	ld	s5,40(sp)
}
ffffffffc020060c:	60e6                	ld	ra,88(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020060e:	00002517          	auipc	a0,0x2
ffffffffc0200612:	caa50513          	addi	a0,a0,-854 # ffffffffc02022b8 <etext+0x2fc>
}
ffffffffc0200616:	6125                	addi	sp,sp,96
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200618:	b4d9                	j	ffffffffc02000de <cprintf>
                int name_len = strlen(name);
ffffffffc020061a:	8552                	mv	a0,s4
ffffffffc020061c:	0e3010ef          	jal	ffffffffc0201efe <strlen>
ffffffffc0200620:	89aa                	mv	s3,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200622:	4619                	li	a2,6
ffffffffc0200624:	00002597          	auipc	a1,0x2
ffffffffc0200628:	cbc58593          	addi	a1,a1,-836 # ffffffffc02022e0 <etext+0x324>
ffffffffc020062c:	8552                	mv	a0,s4
                int name_len = strlen(name);
ffffffffc020062e:	2981                	sext.w	s3,s3
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200630:	13d010ef          	jal	ffffffffc0201f6c <strncmp>
ffffffffc0200634:	e111                	bnez	a0,ffffffffc0200638 <dtb_init+0x1b8>
                    in_memory_node = 1;
ffffffffc0200636:	4b85                	li	s7,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200638:	0a11                	addi	s4,s4,4
ffffffffc020063a:	9a4e                	add	s4,s4,s3
ffffffffc020063c:	ffca7a13          	andi	s4,s4,-4
        switch (token) {
ffffffffc0200640:	89d2                	mv	s3,s4
ffffffffc0200642:	b7b9                	j	ffffffffc0200590 <dtb_init+0x110>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200644:	0049a783          	lw	a5,4(s3)
ffffffffc0200648:	f05a                	sd	s6,32(sp)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020064a:	0089a683          	lw	a3,8(s3)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064e:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200652:	01879b1b          	slliw	s6,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200656:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065a:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200662:	00cb6b33          	or	s6,s6,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200666:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066a:	0087979b          	slliw	a5,a5,0x8
ffffffffc020066e:	00eb6b33          	or	s6,s6,a4
ffffffffc0200672:	00faf7b3          	and	a5,s5,a5
ffffffffc0200676:	00fb6b33          	or	s6,s6,a5
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020067a:	00c98a13          	addi	s4,s3,12
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067e:	2b01                	sext.w	s6,s6
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200680:	000b9c63          	bnez	s7,ffffffffc0200698 <dtb_init+0x218>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200684:	1b02                	slli	s6,s6,0x20
ffffffffc0200686:	020b5b13          	srli	s6,s6,0x20
ffffffffc020068a:	0a0d                	addi	s4,s4,3
ffffffffc020068c:	9a5a                	add	s4,s4,s6
ffffffffc020068e:	ffca7a13          	andi	s4,s4,-4
                break;
ffffffffc0200692:	7b02                	ld	s6,32(sp)
        switch (token) {
ffffffffc0200694:	89d2                	mv	s3,s4
ffffffffc0200696:	bded                	j	ffffffffc0200590 <dtb_init+0x110>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200698:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020069c:	0186979b          	slliw	a5,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a0:	0186d71b          	srliw	a4,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ac:	01957533          	and	a0,a0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	8fd9                	or	a5,a5,a4
ffffffffc02006b2:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006b6:	8d5d                	or	a0,a0,a5
ffffffffc02006b8:	00daf6b3          	and	a3,s5,a3
ffffffffc02006bc:	8d55                	or	a0,a0,a3
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006be:	1502                	slli	a0,a0,0x20
ffffffffc02006c0:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006c2:	00002597          	auipc	a1,0x2
ffffffffc02006c6:	c2658593          	addi	a1,a1,-986 # ffffffffc02022e8 <etext+0x32c>
ffffffffc02006ca:	9522                	add	a0,a0,s0
ffffffffc02006cc:	069010ef          	jal	ffffffffc0201f34 <strcmp>
ffffffffc02006d0:	f955                	bnez	a0,ffffffffc0200684 <dtb_init+0x204>
ffffffffc02006d2:	47bd                	li	a5,15
ffffffffc02006d4:	fb67f8e3          	bgeu	a5,s6,ffffffffc0200684 <dtb_init+0x204>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006d8:	00c9b783          	ld	a5,12(s3)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006dc:	0149b703          	ld	a4,20(s3)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02006e0:	00002517          	auipc	a0,0x2
ffffffffc02006e4:	c1050513          	addi	a0,a0,-1008 # ffffffffc02022f0 <etext+0x334>
           fdt32_to_cpu(x >> 32);
ffffffffc02006e8:	4207d693          	srai	a3,a5,0x20
ffffffffc02006ec:	42075813          	srai	a6,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006f0:	0187d39b          	srliw	t2,a5,0x18
ffffffffc02006f4:	0186d29b          	srliw	t0,a3,0x18
ffffffffc02006f8:	01875f9b          	srliw	t6,a4,0x18
ffffffffc02006fc:	01885f1b          	srliw	t5,a6,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200700:	0087d49b          	srliw	s1,a5,0x8
ffffffffc0200704:	0087541b          	srliw	s0,a4,0x8
ffffffffc0200708:	01879e9b          	slliw	t4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020070c:	0107d59b          	srliw	a1,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200710:	01869e1b          	slliw	t3,a3,0x18
ffffffffc0200714:	0187131b          	slliw	t1,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200718:	0107561b          	srliw	a2,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071c:	0188189b          	slliw	a7,a6,0x18
ffffffffc0200720:	83e1                	srli	a5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	8361                	srli	a4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200728:	0108581b          	srliw	a6,a6,0x10
ffffffffc020072c:	005e6e33          	or	t3,t3,t0
ffffffffc0200730:	01e8e8b3          	or	a7,a7,t5
ffffffffc0200734:	0088181b          	slliw	a6,a6,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0104949b          	slliw	s1,s1,0x10
ffffffffc020073c:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200740:	0085959b          	slliw	a1,a1,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200744:	0197f7b3          	and	a5,a5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200748:	0086969b          	slliw	a3,a3,0x8
ffffffffc020074c:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200750:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200754:	00daf6b3          	and	a3,s5,a3
ffffffffc0200758:	007eeeb3          	or	t4,t4,t2
ffffffffc020075c:	01f36333          	or	t1,t1,t6
ffffffffc0200760:	01c7e7b3          	or	a5,a5,t3
ffffffffc0200764:	00caf633          	and	a2,s5,a2
ffffffffc0200768:	01176733          	or	a4,a4,a7
ffffffffc020076c:	00baf5b3          	and	a1,s5,a1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200770:	0194f4b3          	and	s1,s1,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200774:	010afab3          	and	s5,s5,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200778:	01947433          	and	s0,s0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020077c:	01d4e4b3          	or	s1,s1,t4
ffffffffc0200780:	00646433          	or	s0,s0,t1
ffffffffc0200784:	8fd5                	or	a5,a5,a3
ffffffffc0200786:	01576733          	or	a4,a4,s5
ffffffffc020078a:	8c51                	or	s0,s0,a2
ffffffffc020078c:	8ccd                	or	s1,s1,a1
           fdt32_to_cpu(x >> 32);
ffffffffc020078e:	1782                	slli	a5,a5,0x20
ffffffffc0200790:	1702                	slli	a4,a4,0x20
ffffffffc0200792:	9381                	srli	a5,a5,0x20
ffffffffc0200794:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200796:	1482                	slli	s1,s1,0x20
ffffffffc0200798:	1402                	slli	s0,s0,0x20
ffffffffc020079a:	8cdd                	or	s1,s1,a5
ffffffffc020079c:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020079e:	941ff0ef          	jal	ffffffffc02000de <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007a2:	85a6                	mv	a1,s1
ffffffffc02007a4:	00002517          	auipc	a0,0x2
ffffffffc02007a8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0202310 <etext+0x354>
ffffffffc02007ac:	933ff0ef          	jal	ffffffffc02000de <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007b0:	01445613          	srli	a2,s0,0x14
ffffffffc02007b4:	85a2                	mv	a1,s0
ffffffffc02007b6:	00002517          	auipc	a0,0x2
ffffffffc02007ba:	b7250513          	addi	a0,a0,-1166 # ffffffffc0202328 <etext+0x36c>
ffffffffc02007be:	921ff0ef          	jal	ffffffffc02000de <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007c2:	009405b3          	add	a1,s0,s1
ffffffffc02007c6:	15fd                	addi	a1,a1,-1
ffffffffc02007c8:	00002517          	auipc	a0,0x2
ffffffffc02007cc:	b8050513          	addi	a0,a0,-1152 # ffffffffc0202348 <etext+0x38c>
ffffffffc02007d0:	90fff0ef          	jal	ffffffffc02000de <cprintf>
        memory_base = mem_base;
ffffffffc02007d4:	7b02                	ld	s6,32(sp)
ffffffffc02007d6:	00007797          	auipc	a5,0x7
ffffffffc02007da:	c897b123          	sd	s1,-894(a5) # ffffffffc0207458 <memory_base>
        memory_size = mem_size;
ffffffffc02007de:	00007797          	auipc	a5,0x7
ffffffffc02007e2:	c687b923          	sd	s0,-910(a5) # ffffffffc0207450 <memory_size>
ffffffffc02007e6:	b501                	j	ffffffffc02005e6 <dtb_init+0x166>

ffffffffc02007e8 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02007e8:	00007517          	auipc	a0,0x7
ffffffffc02007ec:	c7053503          	ld	a0,-912(a0) # ffffffffc0207458 <memory_base>
ffffffffc02007f0:	8082                	ret

ffffffffc02007f2 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02007f2:	00007517          	auipc	a0,0x7
ffffffffc02007f6:	c5e53503          	ld	a0,-930(a0) # ffffffffc0207450 <memory_size>
ffffffffc02007fa:	8082                	ret

ffffffffc02007fc <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02007fc:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200800:	8082                	ret

ffffffffc0200802 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200802:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200806:	8082                	ret

ffffffffc0200808 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200808:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020080c:	00000797          	auipc	a5,0x0
ffffffffc0200810:	39078793          	addi	a5,a5,912 # ffffffffc0200b9c <__alltraps>
ffffffffc0200814:	10579073          	csrw	stvec,a5
}
ffffffffc0200818:	8082                	ret

ffffffffc020081a <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020081a:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020081c:	1141                	addi	sp,sp,-16
ffffffffc020081e:	e022                	sd	s0,0(sp)
ffffffffc0200820:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200822:	00002517          	auipc	a0,0x2
ffffffffc0200826:	b8e50513          	addi	a0,a0,-1138 # ffffffffc02023b0 <etext+0x3f4>
void print_regs(struct pushregs *gpr) {
ffffffffc020082a:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020082c:	8b3ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200830:	640c                	ld	a1,8(s0)
ffffffffc0200832:	00002517          	auipc	a0,0x2
ffffffffc0200836:	b9650513          	addi	a0,a0,-1130 # ffffffffc02023c8 <etext+0x40c>
ffffffffc020083a:	8a5ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020083e:	680c                	ld	a1,16(s0)
ffffffffc0200840:	00002517          	auipc	a0,0x2
ffffffffc0200844:	ba050513          	addi	a0,a0,-1120 # ffffffffc02023e0 <etext+0x424>
ffffffffc0200848:	897ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020084c:	6c0c                	ld	a1,24(s0)
ffffffffc020084e:	00002517          	auipc	a0,0x2
ffffffffc0200852:	baa50513          	addi	a0,a0,-1110 # ffffffffc02023f8 <etext+0x43c>
ffffffffc0200856:	889ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020085a:	700c                	ld	a1,32(s0)
ffffffffc020085c:	00002517          	auipc	a0,0x2
ffffffffc0200860:	bb450513          	addi	a0,a0,-1100 # ffffffffc0202410 <etext+0x454>
ffffffffc0200864:	87bff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200868:	740c                	ld	a1,40(s0)
ffffffffc020086a:	00002517          	auipc	a0,0x2
ffffffffc020086e:	bbe50513          	addi	a0,a0,-1090 # ffffffffc0202428 <etext+0x46c>
ffffffffc0200872:	86dff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200876:	780c                	ld	a1,48(s0)
ffffffffc0200878:	00002517          	auipc	a0,0x2
ffffffffc020087c:	bc850513          	addi	a0,a0,-1080 # ffffffffc0202440 <etext+0x484>
ffffffffc0200880:	85fff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200884:	7c0c                	ld	a1,56(s0)
ffffffffc0200886:	00002517          	auipc	a0,0x2
ffffffffc020088a:	bd250513          	addi	a0,a0,-1070 # ffffffffc0202458 <etext+0x49c>
ffffffffc020088e:	851ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200892:	602c                	ld	a1,64(s0)
ffffffffc0200894:	00002517          	auipc	a0,0x2
ffffffffc0200898:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202470 <etext+0x4b4>
ffffffffc020089c:	843ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008a0:	642c                	ld	a1,72(s0)
ffffffffc02008a2:	00002517          	auipc	a0,0x2
ffffffffc02008a6:	be650513          	addi	a0,a0,-1050 # ffffffffc0202488 <etext+0x4cc>
ffffffffc02008aa:	835ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008ae:	682c                	ld	a1,80(s0)
ffffffffc02008b0:	00002517          	auipc	a0,0x2
ffffffffc02008b4:	bf050513          	addi	a0,a0,-1040 # ffffffffc02024a0 <etext+0x4e4>
ffffffffc02008b8:	827ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008bc:	6c2c                	ld	a1,88(s0)
ffffffffc02008be:	00002517          	auipc	a0,0x2
ffffffffc02008c2:	bfa50513          	addi	a0,a0,-1030 # ffffffffc02024b8 <etext+0x4fc>
ffffffffc02008c6:	819ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008ca:	702c                	ld	a1,96(s0)
ffffffffc02008cc:	00002517          	auipc	a0,0x2
ffffffffc02008d0:	c0450513          	addi	a0,a0,-1020 # ffffffffc02024d0 <etext+0x514>
ffffffffc02008d4:	80bff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02008d8:	742c                	ld	a1,104(s0)
ffffffffc02008da:	00002517          	auipc	a0,0x2
ffffffffc02008de:	c0e50513          	addi	a0,a0,-1010 # ffffffffc02024e8 <etext+0x52c>
ffffffffc02008e2:	ffcff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02008e6:	782c                	ld	a1,112(s0)
ffffffffc02008e8:	00002517          	auipc	a0,0x2
ffffffffc02008ec:	c1850513          	addi	a0,a0,-1000 # ffffffffc0202500 <etext+0x544>
ffffffffc02008f0:	feeff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc02008f4:	7c2c                	ld	a1,120(s0)
ffffffffc02008f6:	00002517          	auipc	a0,0x2
ffffffffc02008fa:	c2250513          	addi	a0,a0,-990 # ffffffffc0202518 <etext+0x55c>
ffffffffc02008fe:	fe0ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200902:	604c                	ld	a1,128(s0)
ffffffffc0200904:	00002517          	auipc	a0,0x2
ffffffffc0200908:	c2c50513          	addi	a0,a0,-980 # ffffffffc0202530 <etext+0x574>
ffffffffc020090c:	fd2ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200910:	644c                	ld	a1,136(s0)
ffffffffc0200912:	00002517          	auipc	a0,0x2
ffffffffc0200916:	c3650513          	addi	a0,a0,-970 # ffffffffc0202548 <etext+0x58c>
ffffffffc020091a:	fc4ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020091e:	684c                	ld	a1,144(s0)
ffffffffc0200920:	00002517          	auipc	a0,0x2
ffffffffc0200924:	c4050513          	addi	a0,a0,-960 # ffffffffc0202560 <etext+0x5a4>
ffffffffc0200928:	fb6ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020092c:	6c4c                	ld	a1,152(s0)
ffffffffc020092e:	00002517          	auipc	a0,0x2
ffffffffc0200932:	c4a50513          	addi	a0,a0,-950 # ffffffffc0202578 <etext+0x5bc>
ffffffffc0200936:	fa8ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020093a:	704c                	ld	a1,160(s0)
ffffffffc020093c:	00002517          	auipc	a0,0x2
ffffffffc0200940:	c5450513          	addi	a0,a0,-940 # ffffffffc0202590 <etext+0x5d4>
ffffffffc0200944:	f9aff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200948:	744c                	ld	a1,168(s0)
ffffffffc020094a:	00002517          	auipc	a0,0x2
ffffffffc020094e:	c5e50513          	addi	a0,a0,-930 # ffffffffc02025a8 <etext+0x5ec>
ffffffffc0200952:	f8cff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200956:	784c                	ld	a1,176(s0)
ffffffffc0200958:	00002517          	auipc	a0,0x2
ffffffffc020095c:	c6850513          	addi	a0,a0,-920 # ffffffffc02025c0 <etext+0x604>
ffffffffc0200960:	f7eff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200964:	7c4c                	ld	a1,184(s0)
ffffffffc0200966:	00002517          	auipc	a0,0x2
ffffffffc020096a:	c7250513          	addi	a0,a0,-910 # ffffffffc02025d8 <etext+0x61c>
ffffffffc020096e:	f70ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200972:	606c                	ld	a1,192(s0)
ffffffffc0200974:	00002517          	auipc	a0,0x2
ffffffffc0200978:	c7c50513          	addi	a0,a0,-900 # ffffffffc02025f0 <etext+0x634>
ffffffffc020097c:	f62ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200980:	646c                	ld	a1,200(s0)
ffffffffc0200982:	00002517          	auipc	a0,0x2
ffffffffc0200986:	c8650513          	addi	a0,a0,-890 # ffffffffc0202608 <etext+0x64c>
ffffffffc020098a:	f54ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc020098e:	686c                	ld	a1,208(s0)
ffffffffc0200990:	00002517          	auipc	a0,0x2
ffffffffc0200994:	c9050513          	addi	a0,a0,-880 # ffffffffc0202620 <etext+0x664>
ffffffffc0200998:	f46ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc020099c:	6c6c                	ld	a1,216(s0)
ffffffffc020099e:	00002517          	auipc	a0,0x2
ffffffffc02009a2:	c9a50513          	addi	a0,a0,-870 # ffffffffc0202638 <etext+0x67c>
ffffffffc02009a6:	f38ff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009aa:	706c                	ld	a1,224(s0)
ffffffffc02009ac:	00002517          	auipc	a0,0x2
ffffffffc02009b0:	ca450513          	addi	a0,a0,-860 # ffffffffc0202650 <etext+0x694>
ffffffffc02009b4:	f2aff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009b8:	746c                	ld	a1,232(s0)
ffffffffc02009ba:	00002517          	auipc	a0,0x2
ffffffffc02009be:	cae50513          	addi	a0,a0,-850 # ffffffffc0202668 <etext+0x6ac>
ffffffffc02009c2:	f1cff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009c6:	786c                	ld	a1,240(s0)
ffffffffc02009c8:	00002517          	auipc	a0,0x2
ffffffffc02009cc:	cb850513          	addi	a0,a0,-840 # ffffffffc0202680 <etext+0x6c4>
ffffffffc02009d0:	f0eff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009d4:	7c6c                	ld	a1,248(s0)
}
ffffffffc02009d6:	6402                	ld	s0,0(sp)
ffffffffc02009d8:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009da:	00002517          	auipc	a0,0x2
ffffffffc02009de:	cbe50513          	addi	a0,a0,-834 # ffffffffc0202698 <etext+0x6dc>
}
ffffffffc02009e2:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009e4:	efaff06f          	j	ffffffffc02000de <cprintf>

ffffffffc02009e8 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc02009e8:	1141                	addi	sp,sp,-16
ffffffffc02009ea:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009ec:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc02009ee:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc02009f0:	00002517          	auipc	a0,0x2
ffffffffc02009f4:	cc050513          	addi	a0,a0,-832 # ffffffffc02026b0 <etext+0x6f4>
void print_trapframe(struct trapframe *tf) {
ffffffffc02009f8:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009fa:	ee4ff0ef          	jal	ffffffffc02000de <cprintf>
    print_regs(&tf->gpr);
ffffffffc02009fe:	8522                	mv	a0,s0
ffffffffc0200a00:	e1bff0ef          	jal	ffffffffc020081a <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a04:	10043583          	ld	a1,256(s0)
ffffffffc0200a08:	00002517          	auipc	a0,0x2
ffffffffc0200a0c:	cc050513          	addi	a0,a0,-832 # ffffffffc02026c8 <etext+0x70c>
ffffffffc0200a10:	eceff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a14:	10843583          	ld	a1,264(s0)
ffffffffc0200a18:	00002517          	auipc	a0,0x2
ffffffffc0200a1c:	cc850513          	addi	a0,a0,-824 # ffffffffc02026e0 <etext+0x724>
ffffffffc0200a20:	ebeff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a24:	11043583          	ld	a1,272(s0)
ffffffffc0200a28:	00002517          	auipc	a0,0x2
ffffffffc0200a2c:	cd050513          	addi	a0,a0,-816 # ffffffffc02026f8 <etext+0x73c>
ffffffffc0200a30:	eaeff0ef          	jal	ffffffffc02000de <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a34:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a38:	6402                	ld	s0,0(sp)
ffffffffc0200a3a:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a3c:	00002517          	auipc	a0,0x2
ffffffffc0200a40:	cd450513          	addi	a0,a0,-812 # ffffffffc0202710 <etext+0x754>
}
ffffffffc0200a44:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a46:	e98ff06f          	j	ffffffffc02000de <cprintf>

ffffffffc0200a4a <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc0200a4a:	11853783          	ld	a5,280(a0)
ffffffffc0200a4e:	472d                	li	a4,11
ffffffffc0200a50:	0786                	slli	a5,a5,0x1
ffffffffc0200a52:	8385                	srli	a5,a5,0x1
ffffffffc0200a54:	08f76263          	bltu	a4,a5,ffffffffc0200ad8 <interrupt_handler+0x8e>
ffffffffc0200a58:	00002717          	auipc	a4,0x2
ffffffffc0200a5c:	43070713          	addi	a4,a4,1072 # ffffffffc0202e88 <commands+0x48>
ffffffffc0200a60:	078a                	slli	a5,a5,0x2
ffffffffc0200a62:	97ba                	add	a5,a5,a4
ffffffffc0200a64:	439c                	lw	a5,0(a5)
ffffffffc0200a66:	97ba                	add	a5,a5,a4
ffffffffc0200a68:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a6a:	00002517          	auipc	a0,0x2
ffffffffc0200a6e:	d1e50513          	addi	a0,a0,-738 # ffffffffc0202788 <etext+0x7cc>
ffffffffc0200a72:	e6cff06f          	j	ffffffffc02000de <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200a76:	00002517          	auipc	a0,0x2
ffffffffc0200a7a:	cf250513          	addi	a0,a0,-782 # ffffffffc0202768 <etext+0x7ac>
ffffffffc0200a7e:	e60ff06f          	j	ffffffffc02000de <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a82:	00002517          	auipc	a0,0x2
ffffffffc0200a86:	ca650513          	addi	a0,a0,-858 # ffffffffc0202728 <etext+0x76c>
ffffffffc0200a8a:	e54ff06f          	j	ffffffffc02000de <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200a8e:	00002517          	auipc	a0,0x2
ffffffffc0200a92:	d1a50513          	addi	a0,a0,-742 # ffffffffc02027a8 <etext+0x7ec>
ffffffffc0200a96:	e48ff06f          	j	ffffffffc02000de <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a9a:	1141                	addi	sp,sp,-16
ffffffffc0200a9c:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200a9e:	9c5ff0ef          	jal	ffffffffc0200462 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200aa2:	00007697          	auipc	a3,0x7
ffffffffc0200aa6:	9a668693          	addi	a3,a3,-1626 # ffffffffc0207448 <ticks>
ffffffffc0200aaa:	629c                	ld	a5,0(a3)
ffffffffc0200aac:	06400713          	li	a4,100
ffffffffc0200ab0:	0785                	addi	a5,a5,1
ffffffffc0200ab2:	02e7f733          	remu	a4,a5,a4
ffffffffc0200ab6:	e29c                	sd	a5,0(a3)
ffffffffc0200ab8:	c30d                	beqz	a4,ffffffffc0200ada <interrupt_handler+0x90>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200aba:	60a2                	ld	ra,8(sp)
ffffffffc0200abc:	0141                	addi	sp,sp,16
ffffffffc0200abe:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200ac0:	00002517          	auipc	a0,0x2
ffffffffc0200ac4:	d1050513          	addi	a0,a0,-752 # ffffffffc02027d0 <etext+0x814>
ffffffffc0200ac8:	e16ff06f          	j	ffffffffc02000de <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200acc:	00002517          	auipc	a0,0x2
ffffffffc0200ad0:	c7c50513          	addi	a0,a0,-900 # ffffffffc0202748 <etext+0x78c>
ffffffffc0200ad4:	e0aff06f          	j	ffffffffc02000de <cprintf>
            print_trapframe(tf);
ffffffffc0200ad8:	bf01                	j	ffffffffc02009e8 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200ada:	06400593          	li	a1,100
ffffffffc0200ade:	00002517          	auipc	a0,0x2
ffffffffc0200ae2:	ce250513          	addi	a0,a0,-798 # ffffffffc02027c0 <etext+0x804>
ffffffffc0200ae6:	df8ff0ef          	jal	ffffffffc02000de <cprintf>
                if (++num >= 10) {
ffffffffc0200aea:	00007717          	auipc	a4,0x7
ffffffffc0200aee:	97670713          	addi	a4,a4,-1674 # ffffffffc0207460 <num>
ffffffffc0200af2:	431c                	lw	a5,0(a4)
ffffffffc0200af4:	46a5                	li	a3,9
ffffffffc0200af6:	0017861b          	addiw	a2,a5,1
ffffffffc0200afa:	c310                	sw	a2,0(a4)
ffffffffc0200afc:	fac6dfe3          	bge	a3,a2,ffffffffc0200aba <interrupt_handler+0x70>
}
ffffffffc0200b00:	60a2                	ld	ra,8(sp)
ffffffffc0200b02:	0141                	addi	sp,sp,16
                    sbi_shutdown();
ffffffffc0200b04:	3e00106f          	j	ffffffffc0201ee4 <sbi_shutdown>

ffffffffc0200b08 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200b08:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b0c:	1141                	addi	sp,sp,-16
ffffffffc0200b0e:	e022                	sd	s0,0(sp)
ffffffffc0200b10:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200b12:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b14:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200b16:	04e78663          	beq	a5,a4,ffffffffc0200b62 <exception_handler+0x5a>
ffffffffc0200b1a:	02f76c63          	bltu	a4,a5,ffffffffc0200b52 <exception_handler+0x4a>
ffffffffc0200b1e:	4709                	li	a4,2
ffffffffc0200b20:	02e79563          	bne	a5,a4,ffffffffc0200b4a <exception_handler+0x42>
             /* LAB3 CHALLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type: Illegal instruction\n");
ffffffffc0200b24:	00002517          	auipc	a0,0x2
ffffffffc0200b28:	ccc50513          	addi	a0,a0,-820 # ffffffffc02027f0 <etext+0x834>
ffffffffc0200b2c:	db2ff0ef          	jal	ffffffffc02000de <cprintf>
    	    cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200b30:	10843583          	ld	a1,264(s0)
ffffffffc0200b34:	00002517          	auipc	a0,0x2
ffffffffc0200b38:	ce450513          	addi	a0,a0,-796 # ffffffffc0202818 <etext+0x85c>
ffffffffc0200b3c:	da2ff0ef          	jal	ffffffffc02000de <cprintf>
            tf->epc += 4;
ffffffffc0200b40:	10843783          	ld	a5,264(s0)
ffffffffc0200b44:	0791                	addi	a5,a5,4
ffffffffc0200b46:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b4a:	60a2                	ld	ra,8(sp)
ffffffffc0200b4c:	6402                	ld	s0,0(sp)
ffffffffc0200b4e:	0141                	addi	sp,sp,16
ffffffffc0200b50:	8082                	ret
    switch (tf->cause) {
ffffffffc0200b52:	17f1                	addi	a5,a5,-4
ffffffffc0200b54:	471d                	li	a4,7
ffffffffc0200b56:	fef77ae3          	bgeu	a4,a5,ffffffffc0200b4a <exception_handler+0x42>
}
ffffffffc0200b5a:	6402                	ld	s0,0(sp)
ffffffffc0200b5c:	60a2                	ld	ra,8(sp)
ffffffffc0200b5e:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200b60:	b561                	j	ffffffffc02009e8 <print_trapframe>
            cprintf("Exception type: breakpoint\n");
ffffffffc0200b62:	00002517          	auipc	a0,0x2
ffffffffc0200b66:	cde50513          	addi	a0,a0,-802 # ffffffffc0202840 <etext+0x884>
ffffffffc0200b6a:	d74ff0ef          	jal	ffffffffc02000de <cprintf>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200b6e:	10843583          	ld	a1,264(s0)
ffffffffc0200b72:	00002517          	auipc	a0,0x2
ffffffffc0200b76:	cee50513          	addi	a0,a0,-786 # ffffffffc0202860 <etext+0x8a4>
ffffffffc0200b7a:	d64ff0ef          	jal	ffffffffc02000de <cprintf>
            tf->epc += 2;
ffffffffc0200b7e:	10843783          	ld	a5,264(s0)
}
ffffffffc0200b82:	60a2                	ld	ra,8(sp)
            tf->epc += 2;
ffffffffc0200b84:	0789                	addi	a5,a5,2
ffffffffc0200b86:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200b8a:	6402                	ld	s0,0(sp)
ffffffffc0200b8c:	0141                	addi	sp,sp,16
ffffffffc0200b8e:	8082                	ret

ffffffffc0200b90 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200b90:	11853783          	ld	a5,280(a0)
ffffffffc0200b94:	0007c363          	bltz	a5,ffffffffc0200b9a <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200b98:	bf85                	j	ffffffffc0200b08 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200b9a:	bd45                	j	ffffffffc0200a4a <interrupt_handler>

ffffffffc0200b9c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200b9c:	14011073          	csrw	sscratch,sp
ffffffffc0200ba0:	712d                	addi	sp,sp,-288
ffffffffc0200ba2:	e002                	sd	zero,0(sp)
ffffffffc0200ba4:	e406                	sd	ra,8(sp)
ffffffffc0200ba6:	ec0e                	sd	gp,24(sp)
ffffffffc0200ba8:	f012                	sd	tp,32(sp)
ffffffffc0200baa:	f416                	sd	t0,40(sp)
ffffffffc0200bac:	f81a                	sd	t1,48(sp)
ffffffffc0200bae:	fc1e                	sd	t2,56(sp)
ffffffffc0200bb0:	e0a2                	sd	s0,64(sp)
ffffffffc0200bb2:	e4a6                	sd	s1,72(sp)
ffffffffc0200bb4:	e8aa                	sd	a0,80(sp)
ffffffffc0200bb6:	ecae                	sd	a1,88(sp)
ffffffffc0200bb8:	f0b2                	sd	a2,96(sp)
ffffffffc0200bba:	f4b6                	sd	a3,104(sp)
ffffffffc0200bbc:	f8ba                	sd	a4,112(sp)
ffffffffc0200bbe:	fcbe                	sd	a5,120(sp)
ffffffffc0200bc0:	e142                	sd	a6,128(sp)
ffffffffc0200bc2:	e546                	sd	a7,136(sp)
ffffffffc0200bc4:	e94a                	sd	s2,144(sp)
ffffffffc0200bc6:	ed4e                	sd	s3,152(sp)
ffffffffc0200bc8:	f152                	sd	s4,160(sp)
ffffffffc0200bca:	f556                	sd	s5,168(sp)
ffffffffc0200bcc:	f95a                	sd	s6,176(sp)
ffffffffc0200bce:	fd5e                	sd	s7,184(sp)
ffffffffc0200bd0:	e1e2                	sd	s8,192(sp)
ffffffffc0200bd2:	e5e6                	sd	s9,200(sp)
ffffffffc0200bd4:	e9ea                	sd	s10,208(sp)
ffffffffc0200bd6:	edee                	sd	s11,216(sp)
ffffffffc0200bd8:	f1f2                	sd	t3,224(sp)
ffffffffc0200bda:	f5f6                	sd	t4,232(sp)
ffffffffc0200bdc:	f9fa                	sd	t5,240(sp)
ffffffffc0200bde:	fdfe                	sd	t6,248(sp)
ffffffffc0200be0:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200be4:	100024f3          	csrr	s1,sstatus
ffffffffc0200be8:	14102973          	csrr	s2,sepc
ffffffffc0200bec:	143029f3          	csrr	s3,stval
ffffffffc0200bf0:	14202a73          	csrr	s4,scause
ffffffffc0200bf4:	e822                	sd	s0,16(sp)
ffffffffc0200bf6:	e226                	sd	s1,256(sp)
ffffffffc0200bf8:	e64a                	sd	s2,264(sp)
ffffffffc0200bfa:	ea4e                	sd	s3,272(sp)
ffffffffc0200bfc:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200bfe:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c00:	f91ff0ef          	jal	ffffffffc0200b90 <trap>

ffffffffc0200c04 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c04:	6492                	ld	s1,256(sp)
ffffffffc0200c06:	6932                	ld	s2,264(sp)
ffffffffc0200c08:	10049073          	csrw	sstatus,s1
ffffffffc0200c0c:	14191073          	csrw	sepc,s2
ffffffffc0200c10:	60a2                	ld	ra,8(sp)
ffffffffc0200c12:	61e2                	ld	gp,24(sp)
ffffffffc0200c14:	7202                	ld	tp,32(sp)
ffffffffc0200c16:	72a2                	ld	t0,40(sp)
ffffffffc0200c18:	7342                	ld	t1,48(sp)
ffffffffc0200c1a:	73e2                	ld	t2,56(sp)
ffffffffc0200c1c:	6406                	ld	s0,64(sp)
ffffffffc0200c1e:	64a6                	ld	s1,72(sp)
ffffffffc0200c20:	6546                	ld	a0,80(sp)
ffffffffc0200c22:	65e6                	ld	a1,88(sp)
ffffffffc0200c24:	7606                	ld	a2,96(sp)
ffffffffc0200c26:	76a6                	ld	a3,104(sp)
ffffffffc0200c28:	7746                	ld	a4,112(sp)
ffffffffc0200c2a:	77e6                	ld	a5,120(sp)
ffffffffc0200c2c:	680a                	ld	a6,128(sp)
ffffffffc0200c2e:	68aa                	ld	a7,136(sp)
ffffffffc0200c30:	694a                	ld	s2,144(sp)
ffffffffc0200c32:	69ea                	ld	s3,152(sp)
ffffffffc0200c34:	7a0a                	ld	s4,160(sp)
ffffffffc0200c36:	7aaa                	ld	s5,168(sp)
ffffffffc0200c38:	7b4a                	ld	s6,176(sp)
ffffffffc0200c3a:	7bea                	ld	s7,184(sp)
ffffffffc0200c3c:	6c0e                	ld	s8,192(sp)
ffffffffc0200c3e:	6cae                	ld	s9,200(sp)
ffffffffc0200c40:	6d4e                	ld	s10,208(sp)
ffffffffc0200c42:	6dee                	ld	s11,216(sp)
ffffffffc0200c44:	7e0e                	ld	t3,224(sp)
ffffffffc0200c46:	7eae                	ld	t4,232(sp)
ffffffffc0200c48:	7f4e                	ld	t5,240(sp)
ffffffffc0200c4a:	7fee                	ld	t6,248(sp)
ffffffffc0200c4c:	6142                	ld	sp,16(sp)
    # return from supervisor call

    # 从监管模式调用返回
    sret
ffffffffc0200c4e:	10200073          	sret

ffffffffc0200c52 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c52:	00006797          	auipc	a5,0x6
ffffffffc0200c56:	3d678793          	addi	a5,a5,982 # ffffffffc0207028 <free_area>
ffffffffc0200c5a:	e79c                	sd	a5,8(a5)
ffffffffc0200c5c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200c5e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200c62:	8082                	ret

ffffffffc0200c64 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200c64:	00006517          	auipc	a0,0x6
ffffffffc0200c68:	3d456503          	lwu	a0,980(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200c6c:	8082                	ret

ffffffffc0200c6e <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200c6e:	715d                	addi	sp,sp,-80
ffffffffc0200c70:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200c72:	00006417          	auipc	s0,0x6
ffffffffc0200c76:	3b640413          	addi	s0,s0,950 # ffffffffc0207028 <free_area>
ffffffffc0200c7a:	641c                	ld	a5,8(s0)
ffffffffc0200c7c:	e486                	sd	ra,72(sp)
ffffffffc0200c7e:	fc26                	sd	s1,56(sp)
ffffffffc0200c80:	f84a                	sd	s2,48(sp)
ffffffffc0200c82:	f44e                	sd	s3,40(sp)
ffffffffc0200c84:	f052                	sd	s4,32(sp)
ffffffffc0200c86:	ec56                	sd	s5,24(sp)
ffffffffc0200c88:	e85a                	sd	s6,16(sp)
ffffffffc0200c8a:	e45e                	sd	s7,8(sp)
ffffffffc0200c8c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c8e:	2e878063          	beq	a5,s0,ffffffffc0200f6e <default_check+0x300>
    int count = 0, total = 0;
ffffffffc0200c92:	4481                	li	s1,0
ffffffffc0200c94:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c96:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200c9a:	8b09                	andi	a4,a4,2
ffffffffc0200c9c:	2c070d63          	beqz	a4,ffffffffc0200f76 <default_check+0x308>
        count ++, total += p->property;
ffffffffc0200ca0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ca4:	679c                	ld	a5,8(a5)
ffffffffc0200ca6:	2905                	addiw	s2,s2,1
ffffffffc0200ca8:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200caa:	fe8796e3          	bne	a5,s0,ffffffffc0200c96 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200cae:	89a6                	mv	s3,s1
ffffffffc0200cb0:	30b000ef          	jal	ffffffffc02017ba <nr_free_pages>
ffffffffc0200cb4:	73351163          	bne	a0,s3,ffffffffc02013d6 <default_check+0x768>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200cb8:	4505                	li	a0,1
ffffffffc0200cba:	283000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200cbe:	8a2a                	mv	s4,a0
ffffffffc0200cc0:	44050b63          	beqz	a0,ffffffffc0201116 <default_check+0x4a8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200cc4:	4505                	li	a0,1
ffffffffc0200cc6:	277000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200cca:	89aa                	mv	s3,a0
ffffffffc0200ccc:	72050563          	beqz	a0,ffffffffc02013f6 <default_check+0x788>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200cd0:	4505                	li	a0,1
ffffffffc0200cd2:	26b000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200cd6:	8aaa                	mv	s5,a0
ffffffffc0200cd8:	4a050f63          	beqz	a0,ffffffffc0201196 <default_check+0x528>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200cdc:	2b3a0d63          	beq	s4,s3,ffffffffc0200f96 <default_check+0x328>
ffffffffc0200ce0:	2aaa0b63          	beq	s4,a0,ffffffffc0200f96 <default_check+0x328>
ffffffffc0200ce4:	2aa98963          	beq	s3,a0,ffffffffc0200f96 <default_check+0x328>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ce8:	000a2783          	lw	a5,0(s4)
ffffffffc0200cec:	2c079563          	bnez	a5,ffffffffc0200fb6 <default_check+0x348>
ffffffffc0200cf0:	0009a783          	lw	a5,0(s3)
ffffffffc0200cf4:	2c079163          	bnez	a5,ffffffffc0200fb6 <default_check+0x348>
ffffffffc0200cf8:	411c                	lw	a5,0(a0)
ffffffffc0200cfa:	2a079e63          	bnez	a5,ffffffffc0200fb6 <default_check+0x348>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cfe:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc0200d02:	ccd78793          	addi	a5,a5,-819 # fffffffffccccccd <end+0x3cac582d>
ffffffffc0200d06:	07b2                	slli	a5,a5,0xc
ffffffffc0200d08:	ccd78793          	addi	a5,a5,-819
ffffffffc0200d0c:	07b2                	slli	a5,a5,0xc
ffffffffc0200d0e:	00006717          	auipc	a4,0x6
ffffffffc0200d12:	78273703          	ld	a4,1922(a4) # ffffffffc0207490 <pages>
ffffffffc0200d16:	ccd78793          	addi	a5,a5,-819
ffffffffc0200d1a:	40ea06b3          	sub	a3,s4,a4
ffffffffc0200d1e:	07b2                	slli	a5,a5,0xc
ffffffffc0200d20:	868d                	srai	a3,a3,0x3
ffffffffc0200d22:	ccd78793          	addi	a5,a5,-819
ffffffffc0200d26:	02f686b3          	mul	a3,a3,a5
ffffffffc0200d2a:	00002597          	auipc	a1,0x2
ffffffffc0200d2e:	3565b583          	ld	a1,854(a1) # ffffffffc0203080 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200d32:	00006617          	auipc	a2,0x6
ffffffffc0200d36:	75663603          	ld	a2,1878(a2) # ffffffffc0207488 <npage>
ffffffffc0200d3a:	0632                	slli	a2,a2,0xc
ffffffffc0200d3c:	96ae                	add	a3,a3,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d3e:	06b2                	slli	a3,a3,0xc
ffffffffc0200d40:	28c6fb63          	bgeu	a3,a2,ffffffffc0200fd6 <default_check+0x368>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d44:	40e986b3          	sub	a3,s3,a4
ffffffffc0200d48:	868d                	srai	a3,a3,0x3
ffffffffc0200d4a:	02f686b3          	mul	a3,a3,a5
ffffffffc0200d4e:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d50:	06b2                	slli	a3,a3,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d52:	4cc6f263          	bgeu	a3,a2,ffffffffc0201216 <default_check+0x5a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d56:	40e50733          	sub	a4,a0,a4
ffffffffc0200d5a:	870d                	srai	a4,a4,0x3
ffffffffc0200d5c:	02f707b3          	mul	a5,a4,a5
ffffffffc0200d60:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d62:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d64:	30c7f963          	bgeu	a5,a2,ffffffffc0201076 <default_check+0x408>
    assert(alloc_page() == NULL);
ffffffffc0200d68:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d6a:	00043c03          	ld	s8,0(s0)
ffffffffc0200d6e:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200d72:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200d76:	e400                	sd	s0,8(s0)
ffffffffc0200d78:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200d7a:	00006797          	auipc	a5,0x6
ffffffffc0200d7e:	2a07af23          	sw	zero,702(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200d82:	1bb000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200d86:	2c051863          	bnez	a0,ffffffffc0201056 <default_check+0x3e8>
    free_page(p0);
ffffffffc0200d8a:	4585                	li	a1,1
ffffffffc0200d8c:	8552                	mv	a0,s4
ffffffffc0200d8e:	1ed000ef          	jal	ffffffffc020177a <free_pages>
    free_page(p1);
ffffffffc0200d92:	4585                	li	a1,1
ffffffffc0200d94:	854e                	mv	a0,s3
ffffffffc0200d96:	1e5000ef          	jal	ffffffffc020177a <free_pages>
    free_page(p2);
ffffffffc0200d9a:	4585                	li	a1,1
ffffffffc0200d9c:	8556                	mv	a0,s5
ffffffffc0200d9e:	1dd000ef          	jal	ffffffffc020177a <free_pages>
    assert(nr_free == 3);
ffffffffc0200da2:	4818                	lw	a4,16(s0)
ffffffffc0200da4:	478d                	li	a5,3
ffffffffc0200da6:	28f71863          	bne	a4,a5,ffffffffc0201036 <default_check+0x3c8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200daa:	4505                	li	a0,1
ffffffffc0200dac:	191000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200db0:	89aa                	mv	s3,a0
ffffffffc0200db2:	26050263          	beqz	a0,ffffffffc0201016 <default_check+0x3a8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200db6:	4505                	li	a0,1
ffffffffc0200db8:	185000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200dbc:	8aaa                	mv	s5,a0
ffffffffc0200dbe:	3a050c63          	beqz	a0,ffffffffc0201176 <default_check+0x508>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200dc2:	4505                	li	a0,1
ffffffffc0200dc4:	179000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200dc8:	8a2a                	mv	s4,a0
ffffffffc0200dca:	38050663          	beqz	a0,ffffffffc0201156 <default_check+0x4e8>
    assert(alloc_page() == NULL);
ffffffffc0200dce:	4505                	li	a0,1
ffffffffc0200dd0:	16d000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200dd4:	36051163          	bnez	a0,ffffffffc0201136 <default_check+0x4c8>
    free_page(p0);
ffffffffc0200dd8:	4585                	li	a1,1
ffffffffc0200dda:	854e                	mv	a0,s3
ffffffffc0200ddc:	19f000ef          	jal	ffffffffc020177a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200de0:	641c                	ld	a5,8(s0)
ffffffffc0200de2:	20878a63          	beq	a5,s0,ffffffffc0200ff6 <default_check+0x388>
    assert((p = alloc_page()) == p0);
ffffffffc0200de6:	4505                	li	a0,1
ffffffffc0200de8:	155000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200dec:	30a99563          	bne	s3,a0,ffffffffc02010f6 <default_check+0x488>
    assert(alloc_page() == NULL);
ffffffffc0200df0:	4505                	li	a0,1
ffffffffc0200df2:	14b000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200df6:	2e051063          	bnez	a0,ffffffffc02010d6 <default_check+0x468>
    assert(nr_free == 0);
ffffffffc0200dfa:	481c                	lw	a5,16(s0)
ffffffffc0200dfc:	2a079d63          	bnez	a5,ffffffffc02010b6 <default_check+0x448>
    free_page(p);
ffffffffc0200e00:	854e                	mv	a0,s3
ffffffffc0200e02:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200e04:	01843023          	sd	s8,0(s0)
ffffffffc0200e08:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200e0c:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200e10:	16b000ef          	jal	ffffffffc020177a <free_pages>
    free_page(p1);
ffffffffc0200e14:	4585                	li	a1,1
ffffffffc0200e16:	8556                	mv	a0,s5
ffffffffc0200e18:	163000ef          	jal	ffffffffc020177a <free_pages>
    free_page(p2);
ffffffffc0200e1c:	4585                	li	a1,1
ffffffffc0200e1e:	8552                	mv	a0,s4
ffffffffc0200e20:	15b000ef          	jal	ffffffffc020177a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200e24:	4515                	li	a0,5
ffffffffc0200e26:	117000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200e2a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200e2c:	26050563          	beqz	a0,ffffffffc0201096 <default_check+0x428>
ffffffffc0200e30:	651c                	ld	a5,8(a0)
ffffffffc0200e32:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200e34:	8b85                	andi	a5,a5,1
ffffffffc0200e36:	54079063          	bnez	a5,ffffffffc0201376 <default_check+0x708>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200e3a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e3c:	00043b03          	ld	s6,0(s0)
ffffffffc0200e40:	00843a83          	ld	s5,8(s0)
ffffffffc0200e44:	e000                	sd	s0,0(s0)
ffffffffc0200e46:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200e48:	0f5000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200e4c:	50051563          	bnez	a0,ffffffffc0201356 <default_check+0x6e8>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200e50:	05098a13          	addi	s4,s3,80
ffffffffc0200e54:	8552                	mv	a0,s4
ffffffffc0200e56:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200e58:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200e5c:	00006797          	auipc	a5,0x6
ffffffffc0200e60:	1c07ae23          	sw	zero,476(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200e64:	117000ef          	jal	ffffffffc020177a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e68:	4511                	li	a0,4
ffffffffc0200e6a:	0d3000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200e6e:	4c051463          	bnez	a0,ffffffffc0201336 <default_check+0x6c8>
ffffffffc0200e72:	0589b783          	ld	a5,88(s3)
ffffffffc0200e76:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200e78:	8b85                	andi	a5,a5,1
ffffffffc0200e7a:	48078e63          	beqz	a5,ffffffffc0201316 <default_check+0x6a8>
ffffffffc0200e7e:	0609a703          	lw	a4,96(s3)
ffffffffc0200e82:	478d                	li	a5,3
ffffffffc0200e84:	48f71963          	bne	a4,a5,ffffffffc0201316 <default_check+0x6a8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200e88:	450d                	li	a0,3
ffffffffc0200e8a:	0b3000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200e8e:	8c2a                	mv	s8,a0
ffffffffc0200e90:	46050363          	beqz	a0,ffffffffc02012f6 <default_check+0x688>
    assert(alloc_page() == NULL);
ffffffffc0200e94:	4505                	li	a0,1
ffffffffc0200e96:	0a7000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200e9a:	42051e63          	bnez	a0,ffffffffc02012d6 <default_check+0x668>
    assert(p0 + 2 == p1);
ffffffffc0200e9e:	418a1c63          	bne	s4,s8,ffffffffc02012b6 <default_check+0x648>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200ea2:	4585                	li	a1,1
ffffffffc0200ea4:	854e                	mv	a0,s3
ffffffffc0200ea6:	0d5000ef          	jal	ffffffffc020177a <free_pages>
    free_pages(p1, 3);
ffffffffc0200eaa:	458d                	li	a1,3
ffffffffc0200eac:	8552                	mv	a0,s4
ffffffffc0200eae:	0cd000ef          	jal	ffffffffc020177a <free_pages>
ffffffffc0200eb2:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200eb6:	02898c13          	addi	s8,s3,40
ffffffffc0200eba:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200ebc:	8b85                	andi	a5,a5,1
ffffffffc0200ebe:	3c078c63          	beqz	a5,ffffffffc0201296 <default_check+0x628>
ffffffffc0200ec2:	0109a703          	lw	a4,16(s3)
ffffffffc0200ec6:	4785                	li	a5,1
ffffffffc0200ec8:	3cf71763          	bne	a4,a5,ffffffffc0201296 <default_check+0x628>
ffffffffc0200ecc:	008a3783          	ld	a5,8(s4)
ffffffffc0200ed0:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200ed2:	8b85                	andi	a5,a5,1
ffffffffc0200ed4:	3a078163          	beqz	a5,ffffffffc0201276 <default_check+0x608>
ffffffffc0200ed8:	010a2703          	lw	a4,16(s4)
ffffffffc0200edc:	478d                	li	a5,3
ffffffffc0200ede:	38f71c63          	bne	a4,a5,ffffffffc0201276 <default_check+0x608>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200ee2:	4505                	li	a0,1
ffffffffc0200ee4:	059000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200ee8:	36a99763          	bne	s3,a0,ffffffffc0201256 <default_check+0x5e8>
    free_page(p0);
ffffffffc0200eec:	4585                	li	a1,1
ffffffffc0200eee:	08d000ef          	jal	ffffffffc020177a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200ef2:	4509                	li	a0,2
ffffffffc0200ef4:	049000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200ef8:	32aa1f63          	bne	s4,a0,ffffffffc0201236 <default_check+0x5c8>

    free_pages(p0, 2);
ffffffffc0200efc:	4589                	li	a1,2
ffffffffc0200efe:	07d000ef          	jal	ffffffffc020177a <free_pages>
    free_page(p2);
ffffffffc0200f02:	4585                	li	a1,1
ffffffffc0200f04:	8562                	mv	a0,s8
ffffffffc0200f06:	075000ef          	jal	ffffffffc020177a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f0a:	4515                	li	a0,5
ffffffffc0200f0c:	031000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200f10:	89aa                	mv	s3,a0
ffffffffc0200f12:	48050263          	beqz	a0,ffffffffc0201396 <default_check+0x728>
    assert(alloc_page() == NULL);
ffffffffc0200f16:	4505                	li	a0,1
ffffffffc0200f18:	025000ef          	jal	ffffffffc020173c <alloc_pages>
ffffffffc0200f1c:	2c051d63          	bnez	a0,ffffffffc02011f6 <default_check+0x588>

    assert(nr_free == 0);
ffffffffc0200f20:	481c                	lw	a5,16(s0)
ffffffffc0200f22:	2a079a63          	bnez	a5,ffffffffc02011d6 <default_check+0x568>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200f26:	4595                	li	a1,5
ffffffffc0200f28:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200f2a:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200f2e:	01643023          	sd	s6,0(s0)
ffffffffc0200f32:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200f36:	045000ef          	jal	ffffffffc020177a <free_pages>
    return listelm->next;
ffffffffc0200f3a:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f3c:	00878963          	beq	a5,s0,ffffffffc0200f4e <default_check+0x2e0>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200f40:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f44:	679c                	ld	a5,8(a5)
ffffffffc0200f46:	397d                	addiw	s2,s2,-1
ffffffffc0200f48:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f4a:	fe879be3          	bne	a5,s0,ffffffffc0200f40 <default_check+0x2d2>
    }
    assert(count == 0);
ffffffffc0200f4e:	26091463          	bnez	s2,ffffffffc02011b6 <default_check+0x548>
    assert(total == 0);
ffffffffc0200f52:	46049263          	bnez	s1,ffffffffc02013b6 <default_check+0x748>
}
ffffffffc0200f56:	60a6                	ld	ra,72(sp)
ffffffffc0200f58:	6406                	ld	s0,64(sp)
ffffffffc0200f5a:	74e2                	ld	s1,56(sp)
ffffffffc0200f5c:	7942                	ld	s2,48(sp)
ffffffffc0200f5e:	79a2                	ld	s3,40(sp)
ffffffffc0200f60:	7a02                	ld	s4,32(sp)
ffffffffc0200f62:	6ae2                	ld	s5,24(sp)
ffffffffc0200f64:	6b42                	ld	s6,16(sp)
ffffffffc0200f66:	6ba2                	ld	s7,8(sp)
ffffffffc0200f68:	6c02                	ld	s8,0(sp)
ffffffffc0200f6a:	6161                	addi	sp,sp,80
ffffffffc0200f6c:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f6e:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200f70:	4481                	li	s1,0
ffffffffc0200f72:	4901                	li	s2,0
ffffffffc0200f74:	bb35                	j	ffffffffc0200cb0 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200f76:	00002697          	auipc	a3,0x2
ffffffffc0200f7a:	90a68693          	addi	a3,a3,-1782 # ffffffffc0202880 <etext+0x8c4>
ffffffffc0200f7e:	00002617          	auipc	a2,0x2
ffffffffc0200f82:	91260613          	addi	a2,a2,-1774 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0200f86:	0f000593          	li	a1,240
ffffffffc0200f8a:	00002517          	auipc	a0,0x2
ffffffffc0200f8e:	91e50513          	addi	a0,a0,-1762 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0200f92:	c40ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f96:	00002697          	auipc	a3,0x2
ffffffffc0200f9a:	9aa68693          	addi	a3,a3,-1622 # ffffffffc0202940 <etext+0x984>
ffffffffc0200f9e:	00002617          	auipc	a2,0x2
ffffffffc0200fa2:	8f260613          	addi	a2,a2,-1806 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0200fa6:	0bd00593          	li	a1,189
ffffffffc0200faa:	00002517          	auipc	a0,0x2
ffffffffc0200fae:	8fe50513          	addi	a0,a0,-1794 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0200fb2:	c20ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200fb6:	00002697          	auipc	a3,0x2
ffffffffc0200fba:	9b268693          	addi	a3,a3,-1614 # ffffffffc0202968 <etext+0x9ac>
ffffffffc0200fbe:	00002617          	auipc	a2,0x2
ffffffffc0200fc2:	8d260613          	addi	a2,a2,-1838 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0200fc6:	0be00593          	li	a1,190
ffffffffc0200fca:	00002517          	auipc	a0,0x2
ffffffffc0200fce:	8de50513          	addi	a0,a0,-1826 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0200fd2:	c00ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200fd6:	00002697          	auipc	a3,0x2
ffffffffc0200fda:	9d268693          	addi	a3,a3,-1582 # ffffffffc02029a8 <etext+0x9ec>
ffffffffc0200fde:	00002617          	auipc	a2,0x2
ffffffffc0200fe2:	8b260613          	addi	a2,a2,-1870 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0200fe6:	0c000593          	li	a1,192
ffffffffc0200fea:	00002517          	auipc	a0,0x2
ffffffffc0200fee:	8be50513          	addi	a0,a0,-1858 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0200ff2:	be0ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200ff6:	00002697          	auipc	a3,0x2
ffffffffc0200ffa:	a3a68693          	addi	a3,a3,-1478 # ffffffffc0202a30 <etext+0xa74>
ffffffffc0200ffe:	00002617          	auipc	a2,0x2
ffffffffc0201002:	89260613          	addi	a2,a2,-1902 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201006:	0d900593          	li	a1,217
ffffffffc020100a:	00002517          	auipc	a0,0x2
ffffffffc020100e:	89e50513          	addi	a0,a0,-1890 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201012:	bc0ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201016:	00002697          	auipc	a3,0x2
ffffffffc020101a:	8ca68693          	addi	a3,a3,-1846 # ffffffffc02028e0 <etext+0x924>
ffffffffc020101e:	00002617          	auipc	a2,0x2
ffffffffc0201022:	87260613          	addi	a2,a2,-1934 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201026:	0d200593          	li	a1,210
ffffffffc020102a:	00002517          	auipc	a0,0x2
ffffffffc020102e:	87e50513          	addi	a0,a0,-1922 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201032:	ba0ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(nr_free == 3);
ffffffffc0201036:	00002697          	auipc	a3,0x2
ffffffffc020103a:	9ea68693          	addi	a3,a3,-1558 # ffffffffc0202a20 <etext+0xa64>
ffffffffc020103e:	00002617          	auipc	a2,0x2
ffffffffc0201042:	85260613          	addi	a2,a2,-1966 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201046:	0d000593          	li	a1,208
ffffffffc020104a:	00002517          	auipc	a0,0x2
ffffffffc020104e:	85e50513          	addi	a0,a0,-1954 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201052:	b80ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201056:	00002697          	auipc	a3,0x2
ffffffffc020105a:	9b268693          	addi	a3,a3,-1614 # ffffffffc0202a08 <etext+0xa4c>
ffffffffc020105e:	00002617          	auipc	a2,0x2
ffffffffc0201062:	83260613          	addi	a2,a2,-1998 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201066:	0cb00593          	li	a1,203
ffffffffc020106a:	00002517          	auipc	a0,0x2
ffffffffc020106e:	83e50513          	addi	a0,a0,-1986 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201072:	b60ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201076:	00002697          	auipc	a3,0x2
ffffffffc020107a:	97268693          	addi	a3,a3,-1678 # ffffffffc02029e8 <etext+0xa2c>
ffffffffc020107e:	00002617          	auipc	a2,0x2
ffffffffc0201082:	81260613          	addi	a2,a2,-2030 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201086:	0c200593          	li	a1,194
ffffffffc020108a:	00002517          	auipc	a0,0x2
ffffffffc020108e:	81e50513          	addi	a0,a0,-2018 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201092:	b40ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(p0 != NULL);
ffffffffc0201096:	00002697          	auipc	a3,0x2
ffffffffc020109a:	9e268693          	addi	a3,a3,-1566 # ffffffffc0202a78 <etext+0xabc>
ffffffffc020109e:	00001617          	auipc	a2,0x1
ffffffffc02010a2:	7f260613          	addi	a2,a2,2034 # ffffffffc0202890 <etext+0x8d4>
ffffffffc02010a6:	0f800593          	li	a1,248
ffffffffc02010aa:	00001517          	auipc	a0,0x1
ffffffffc02010ae:	7fe50513          	addi	a0,a0,2046 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc02010b2:	b20ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(nr_free == 0);
ffffffffc02010b6:	00002697          	auipc	a3,0x2
ffffffffc02010ba:	9b268693          	addi	a3,a3,-1614 # ffffffffc0202a68 <etext+0xaac>
ffffffffc02010be:	00001617          	auipc	a2,0x1
ffffffffc02010c2:	7d260613          	addi	a2,a2,2002 # ffffffffc0202890 <etext+0x8d4>
ffffffffc02010c6:	0df00593          	li	a1,223
ffffffffc02010ca:	00001517          	auipc	a0,0x1
ffffffffc02010ce:	7de50513          	addi	a0,a0,2014 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc02010d2:	b00ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010d6:	00002697          	auipc	a3,0x2
ffffffffc02010da:	93268693          	addi	a3,a3,-1742 # ffffffffc0202a08 <etext+0xa4c>
ffffffffc02010de:	00001617          	auipc	a2,0x1
ffffffffc02010e2:	7b260613          	addi	a2,a2,1970 # ffffffffc0202890 <etext+0x8d4>
ffffffffc02010e6:	0dd00593          	li	a1,221
ffffffffc02010ea:	00001517          	auipc	a0,0x1
ffffffffc02010ee:	7be50513          	addi	a0,a0,1982 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc02010f2:	ae0ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02010f6:	00002697          	auipc	a3,0x2
ffffffffc02010fa:	95268693          	addi	a3,a3,-1710 # ffffffffc0202a48 <etext+0xa8c>
ffffffffc02010fe:	00001617          	auipc	a2,0x1
ffffffffc0201102:	79260613          	addi	a2,a2,1938 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201106:	0dc00593          	li	a1,220
ffffffffc020110a:	00001517          	auipc	a0,0x1
ffffffffc020110e:	79e50513          	addi	a0,a0,1950 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201112:	ac0ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201116:	00001697          	auipc	a3,0x1
ffffffffc020111a:	7ca68693          	addi	a3,a3,1994 # ffffffffc02028e0 <etext+0x924>
ffffffffc020111e:	00001617          	auipc	a2,0x1
ffffffffc0201122:	77260613          	addi	a2,a2,1906 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201126:	0b900593          	li	a1,185
ffffffffc020112a:	00001517          	auipc	a0,0x1
ffffffffc020112e:	77e50513          	addi	a0,a0,1918 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201132:	aa0ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201136:	00002697          	auipc	a3,0x2
ffffffffc020113a:	8d268693          	addi	a3,a3,-1838 # ffffffffc0202a08 <etext+0xa4c>
ffffffffc020113e:	00001617          	auipc	a2,0x1
ffffffffc0201142:	75260613          	addi	a2,a2,1874 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201146:	0d600593          	li	a1,214
ffffffffc020114a:	00001517          	auipc	a0,0x1
ffffffffc020114e:	75e50513          	addi	a0,a0,1886 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201152:	a80ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201156:	00001697          	auipc	a3,0x1
ffffffffc020115a:	7ca68693          	addi	a3,a3,1994 # ffffffffc0202920 <etext+0x964>
ffffffffc020115e:	00001617          	auipc	a2,0x1
ffffffffc0201162:	73260613          	addi	a2,a2,1842 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201166:	0d400593          	li	a1,212
ffffffffc020116a:	00001517          	auipc	a0,0x1
ffffffffc020116e:	73e50513          	addi	a0,a0,1854 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201172:	a60ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201176:	00001697          	auipc	a3,0x1
ffffffffc020117a:	78a68693          	addi	a3,a3,1930 # ffffffffc0202900 <etext+0x944>
ffffffffc020117e:	00001617          	auipc	a2,0x1
ffffffffc0201182:	71260613          	addi	a2,a2,1810 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201186:	0d300593          	li	a1,211
ffffffffc020118a:	00001517          	auipc	a0,0x1
ffffffffc020118e:	71e50513          	addi	a0,a0,1822 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201192:	a40ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201196:	00001697          	auipc	a3,0x1
ffffffffc020119a:	78a68693          	addi	a3,a3,1930 # ffffffffc0202920 <etext+0x964>
ffffffffc020119e:	00001617          	auipc	a2,0x1
ffffffffc02011a2:	6f260613          	addi	a2,a2,1778 # ffffffffc0202890 <etext+0x8d4>
ffffffffc02011a6:	0bb00593          	li	a1,187
ffffffffc02011aa:	00001517          	auipc	a0,0x1
ffffffffc02011ae:	6fe50513          	addi	a0,a0,1790 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc02011b2:	a20ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(count == 0);
ffffffffc02011b6:	00002697          	auipc	a3,0x2
ffffffffc02011ba:	a1268693          	addi	a3,a3,-1518 # ffffffffc0202bc8 <etext+0xc0c>
ffffffffc02011be:	00001617          	auipc	a2,0x1
ffffffffc02011c2:	6d260613          	addi	a2,a2,1746 # ffffffffc0202890 <etext+0x8d4>
ffffffffc02011c6:	12500593          	li	a1,293
ffffffffc02011ca:	00001517          	auipc	a0,0x1
ffffffffc02011ce:	6de50513          	addi	a0,a0,1758 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc02011d2:	a00ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(nr_free == 0);
ffffffffc02011d6:	00002697          	auipc	a3,0x2
ffffffffc02011da:	89268693          	addi	a3,a3,-1902 # ffffffffc0202a68 <etext+0xaac>
ffffffffc02011de:	00001617          	auipc	a2,0x1
ffffffffc02011e2:	6b260613          	addi	a2,a2,1714 # ffffffffc0202890 <etext+0x8d4>
ffffffffc02011e6:	11a00593          	li	a1,282
ffffffffc02011ea:	00001517          	auipc	a0,0x1
ffffffffc02011ee:	6be50513          	addi	a0,a0,1726 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc02011f2:	9e0ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011f6:	00002697          	auipc	a3,0x2
ffffffffc02011fa:	81268693          	addi	a3,a3,-2030 # ffffffffc0202a08 <etext+0xa4c>
ffffffffc02011fe:	00001617          	auipc	a2,0x1
ffffffffc0201202:	69260613          	addi	a2,a2,1682 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201206:	11800593          	li	a1,280
ffffffffc020120a:	00001517          	auipc	a0,0x1
ffffffffc020120e:	69e50513          	addi	a0,a0,1694 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201212:	9c0ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201216:	00001697          	auipc	a3,0x1
ffffffffc020121a:	7b268693          	addi	a3,a3,1970 # ffffffffc02029c8 <etext+0xa0c>
ffffffffc020121e:	00001617          	auipc	a2,0x1
ffffffffc0201222:	67260613          	addi	a2,a2,1650 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201226:	0c100593          	li	a1,193
ffffffffc020122a:	00001517          	auipc	a0,0x1
ffffffffc020122e:	67e50513          	addi	a0,a0,1662 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201232:	9a0ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201236:	00002697          	auipc	a3,0x2
ffffffffc020123a:	95268693          	addi	a3,a3,-1710 # ffffffffc0202b88 <etext+0xbcc>
ffffffffc020123e:	00001617          	auipc	a2,0x1
ffffffffc0201242:	65260613          	addi	a2,a2,1618 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201246:	11200593          	li	a1,274
ffffffffc020124a:	00001517          	auipc	a0,0x1
ffffffffc020124e:	65e50513          	addi	a0,a0,1630 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201252:	980ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201256:	00002697          	auipc	a3,0x2
ffffffffc020125a:	91268693          	addi	a3,a3,-1774 # ffffffffc0202b68 <etext+0xbac>
ffffffffc020125e:	00001617          	auipc	a2,0x1
ffffffffc0201262:	63260613          	addi	a2,a2,1586 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201266:	11000593          	li	a1,272
ffffffffc020126a:	00001517          	auipc	a0,0x1
ffffffffc020126e:	63e50513          	addi	a0,a0,1598 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201272:	960ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201276:	00002697          	auipc	a3,0x2
ffffffffc020127a:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0202b40 <etext+0xb84>
ffffffffc020127e:	00001617          	auipc	a2,0x1
ffffffffc0201282:	61260613          	addi	a2,a2,1554 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201286:	10e00593          	li	a1,270
ffffffffc020128a:	00001517          	auipc	a0,0x1
ffffffffc020128e:	61e50513          	addi	a0,a0,1566 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201292:	940ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201296:	00002697          	auipc	a3,0x2
ffffffffc020129a:	88268693          	addi	a3,a3,-1918 # ffffffffc0202b18 <etext+0xb5c>
ffffffffc020129e:	00001617          	auipc	a2,0x1
ffffffffc02012a2:	5f260613          	addi	a2,a2,1522 # ffffffffc0202890 <etext+0x8d4>
ffffffffc02012a6:	10d00593          	li	a1,269
ffffffffc02012aa:	00001517          	auipc	a0,0x1
ffffffffc02012ae:	5fe50513          	addi	a0,a0,1534 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc02012b2:	920ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02012b6:	00002697          	auipc	a3,0x2
ffffffffc02012ba:	85268693          	addi	a3,a3,-1966 # ffffffffc0202b08 <etext+0xb4c>
ffffffffc02012be:	00001617          	auipc	a2,0x1
ffffffffc02012c2:	5d260613          	addi	a2,a2,1490 # ffffffffc0202890 <etext+0x8d4>
ffffffffc02012c6:	10800593          	li	a1,264
ffffffffc02012ca:	00001517          	auipc	a0,0x1
ffffffffc02012ce:	5de50513          	addi	a0,a0,1502 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc02012d2:	900ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012d6:	00001697          	auipc	a3,0x1
ffffffffc02012da:	73268693          	addi	a3,a3,1842 # ffffffffc0202a08 <etext+0xa4c>
ffffffffc02012de:	00001617          	auipc	a2,0x1
ffffffffc02012e2:	5b260613          	addi	a2,a2,1458 # ffffffffc0202890 <etext+0x8d4>
ffffffffc02012e6:	10700593          	li	a1,263
ffffffffc02012ea:	00001517          	auipc	a0,0x1
ffffffffc02012ee:	5be50513          	addi	a0,a0,1470 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc02012f2:	8e0ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02012f6:	00001697          	auipc	a3,0x1
ffffffffc02012fa:	7f268693          	addi	a3,a3,2034 # ffffffffc0202ae8 <etext+0xb2c>
ffffffffc02012fe:	00001617          	auipc	a2,0x1
ffffffffc0201302:	59260613          	addi	a2,a2,1426 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201306:	10600593          	li	a1,262
ffffffffc020130a:	00001517          	auipc	a0,0x1
ffffffffc020130e:	59e50513          	addi	a0,a0,1438 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201312:	8c0ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201316:	00001697          	auipc	a3,0x1
ffffffffc020131a:	7a268693          	addi	a3,a3,1954 # ffffffffc0202ab8 <etext+0xafc>
ffffffffc020131e:	00001617          	auipc	a2,0x1
ffffffffc0201322:	57260613          	addi	a2,a2,1394 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201326:	10500593          	li	a1,261
ffffffffc020132a:	00001517          	auipc	a0,0x1
ffffffffc020132e:	57e50513          	addi	a0,a0,1406 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201332:	8a0ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201336:	00001697          	auipc	a3,0x1
ffffffffc020133a:	76a68693          	addi	a3,a3,1898 # ffffffffc0202aa0 <etext+0xae4>
ffffffffc020133e:	00001617          	auipc	a2,0x1
ffffffffc0201342:	55260613          	addi	a2,a2,1362 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201346:	10400593          	li	a1,260
ffffffffc020134a:	00001517          	auipc	a0,0x1
ffffffffc020134e:	55e50513          	addi	a0,a0,1374 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201352:	880ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201356:	00001697          	auipc	a3,0x1
ffffffffc020135a:	6b268693          	addi	a3,a3,1714 # ffffffffc0202a08 <etext+0xa4c>
ffffffffc020135e:	00001617          	auipc	a2,0x1
ffffffffc0201362:	53260613          	addi	a2,a2,1330 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201366:	0fe00593          	li	a1,254
ffffffffc020136a:	00001517          	auipc	a0,0x1
ffffffffc020136e:	53e50513          	addi	a0,a0,1342 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201372:	860ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201376:	00001697          	auipc	a3,0x1
ffffffffc020137a:	71268693          	addi	a3,a3,1810 # ffffffffc0202a88 <etext+0xacc>
ffffffffc020137e:	00001617          	auipc	a2,0x1
ffffffffc0201382:	51260613          	addi	a2,a2,1298 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201386:	0f900593          	li	a1,249
ffffffffc020138a:	00001517          	auipc	a0,0x1
ffffffffc020138e:	51e50513          	addi	a0,a0,1310 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201392:	840ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201396:	00002697          	auipc	a3,0x2
ffffffffc020139a:	81268693          	addi	a3,a3,-2030 # ffffffffc0202ba8 <etext+0xbec>
ffffffffc020139e:	00001617          	auipc	a2,0x1
ffffffffc02013a2:	4f260613          	addi	a2,a2,1266 # ffffffffc0202890 <etext+0x8d4>
ffffffffc02013a6:	11700593          	li	a1,279
ffffffffc02013aa:	00001517          	auipc	a0,0x1
ffffffffc02013ae:	4fe50513          	addi	a0,a0,1278 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc02013b2:	820ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(total == 0);
ffffffffc02013b6:	00002697          	auipc	a3,0x2
ffffffffc02013ba:	82268693          	addi	a3,a3,-2014 # ffffffffc0202bd8 <etext+0xc1c>
ffffffffc02013be:	00001617          	auipc	a2,0x1
ffffffffc02013c2:	4d260613          	addi	a2,a2,1234 # ffffffffc0202890 <etext+0x8d4>
ffffffffc02013c6:	12600593          	li	a1,294
ffffffffc02013ca:	00001517          	auipc	a0,0x1
ffffffffc02013ce:	4de50513          	addi	a0,a0,1246 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc02013d2:	800ff0ef          	jal	ffffffffc02003d2 <__panic>
    assert(total == nr_free_pages());
ffffffffc02013d6:	00001697          	auipc	a3,0x1
ffffffffc02013da:	4ea68693          	addi	a3,a3,1258 # ffffffffc02028c0 <etext+0x904>
ffffffffc02013de:	00001617          	auipc	a2,0x1
ffffffffc02013e2:	4b260613          	addi	a2,a2,1202 # ffffffffc0202890 <etext+0x8d4>
ffffffffc02013e6:	0f300593          	li	a1,243
ffffffffc02013ea:	00001517          	auipc	a0,0x1
ffffffffc02013ee:	4be50513          	addi	a0,a0,1214 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc02013f2:	fe1fe0ef          	jal	ffffffffc02003d2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013f6:	00001697          	auipc	a3,0x1
ffffffffc02013fa:	50a68693          	addi	a3,a3,1290 # ffffffffc0202900 <etext+0x944>
ffffffffc02013fe:	00001617          	auipc	a2,0x1
ffffffffc0201402:	49260613          	addi	a2,a2,1170 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201406:	0ba00593          	li	a1,186
ffffffffc020140a:	00001517          	auipc	a0,0x1
ffffffffc020140e:	49e50513          	addi	a0,a0,1182 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201412:	fc1fe0ef          	jal	ffffffffc02003d2 <__panic>

ffffffffc0201416 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201416:	1141                	addi	sp,sp,-16
ffffffffc0201418:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020141a:	14058a63          	beqz	a1,ffffffffc020156e <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc020141e:	00259713          	slli	a4,a1,0x2
ffffffffc0201422:	972e                	add	a4,a4,a1
ffffffffc0201424:	070e                	slli	a4,a4,0x3
ffffffffc0201426:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020142a:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020142c:	c30d                	beqz	a4,ffffffffc020144e <default_free_pages+0x38>
ffffffffc020142e:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201430:	8b05                	andi	a4,a4,1
ffffffffc0201432:	10071e63          	bnez	a4,ffffffffc020154e <default_free_pages+0x138>
ffffffffc0201436:	6798                	ld	a4,8(a5)
ffffffffc0201438:	8b09                	andi	a4,a4,2
ffffffffc020143a:	10071a63          	bnez	a4,ffffffffc020154e <default_free_pages+0x138>
        p->flags = 0;
ffffffffc020143e:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201442:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201446:	02878793          	addi	a5,a5,40
ffffffffc020144a:	fed792e3          	bne	a5,a3,ffffffffc020142e <default_free_pages+0x18>
    base->property = n;
ffffffffc020144e:	2581                	sext.w	a1,a1
ffffffffc0201450:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201452:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201456:	4789                	li	a5,2
ffffffffc0201458:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020145c:	00006697          	auipc	a3,0x6
ffffffffc0201460:	bcc68693          	addi	a3,a3,-1076 # ffffffffc0207028 <free_area>
ffffffffc0201464:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201466:	669c                	ld	a5,8(a3)
ffffffffc0201468:	9f2d                	addw	a4,a4,a1
ffffffffc020146a:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020146c:	0ad78563          	beq	a5,a3,ffffffffc0201516 <default_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc0201470:	fe878713          	addi	a4,a5,-24
ffffffffc0201474:	4581                	li	a1,0
ffffffffc0201476:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc020147a:	00e56a63          	bltu	a0,a4,ffffffffc020148e <default_free_pages+0x78>
    return listelm->next;
ffffffffc020147e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201480:	06d70263          	beq	a4,a3,ffffffffc02014e4 <default_free_pages+0xce>
    struct Page *p = base;
ffffffffc0201484:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201486:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020148a:	fee57ae3          	bgeu	a0,a4,ffffffffc020147e <default_free_pages+0x68>
ffffffffc020148e:	c199                	beqz	a1,ffffffffc0201494 <default_free_pages+0x7e>
ffffffffc0201490:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201494:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201496:	e390                	sd	a2,0(a5)
ffffffffc0201498:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020149a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020149c:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020149e:	02d70063          	beq	a4,a3,ffffffffc02014be <default_free_pages+0xa8>
        if (p + p->property == base) {
ffffffffc02014a2:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc02014a6:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc02014aa:	02081613          	slli	a2,a6,0x20
ffffffffc02014ae:	9201                	srli	a2,a2,0x20
ffffffffc02014b0:	00261793          	slli	a5,a2,0x2
ffffffffc02014b4:	97b2                	add	a5,a5,a2
ffffffffc02014b6:	078e                	slli	a5,a5,0x3
ffffffffc02014b8:	97ae                	add	a5,a5,a1
ffffffffc02014ba:	02f50f63          	beq	a0,a5,ffffffffc02014f8 <default_free_pages+0xe2>
    return listelm->next;
ffffffffc02014be:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02014c0:	00d70f63          	beq	a4,a3,ffffffffc02014de <default_free_pages+0xc8>
        if (base + base->property == p) {
ffffffffc02014c4:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02014c6:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02014ca:	02059613          	slli	a2,a1,0x20
ffffffffc02014ce:	9201                	srli	a2,a2,0x20
ffffffffc02014d0:	00261793          	slli	a5,a2,0x2
ffffffffc02014d4:	97b2                	add	a5,a5,a2
ffffffffc02014d6:	078e                	slli	a5,a5,0x3
ffffffffc02014d8:	97aa                	add	a5,a5,a0
ffffffffc02014da:	04f68a63          	beq	a3,a5,ffffffffc020152e <default_free_pages+0x118>
}
ffffffffc02014de:	60a2                	ld	ra,8(sp)
ffffffffc02014e0:	0141                	addi	sp,sp,16
ffffffffc02014e2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02014e4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02014e6:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02014e8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02014ea:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02014ec:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02014ee:	02d70d63          	beq	a4,a3,ffffffffc0201528 <default_free_pages+0x112>
ffffffffc02014f2:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02014f4:	87ba                	mv	a5,a4
ffffffffc02014f6:	bf41                	j	ffffffffc0201486 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02014f8:	491c                	lw	a5,16(a0)
ffffffffc02014fa:	010787bb          	addw	a5,a5,a6
ffffffffc02014fe:	fef72c23          	sw	a5,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201502:	57f5                	li	a5,-3
ffffffffc0201504:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201508:	6d10                	ld	a2,24(a0)
ffffffffc020150a:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc020150c:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020150e:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201510:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201512:	e390                	sd	a2,0(a5)
ffffffffc0201514:	b775                	j	ffffffffc02014c0 <default_free_pages+0xaa>
}
ffffffffc0201516:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201518:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020151c:	e398                	sd	a4,0(a5)
ffffffffc020151e:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201520:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201522:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201524:	0141                	addi	sp,sp,16
ffffffffc0201526:	8082                	ret
ffffffffc0201528:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020152a:	873e                	mv	a4,a5
ffffffffc020152c:	bf8d                	j	ffffffffc020149e <default_free_pages+0x88>
            base->property += p->property;
ffffffffc020152e:	ff872783          	lw	a5,-8(a4)
ffffffffc0201532:	ff070693          	addi	a3,a4,-16
ffffffffc0201536:	9fad                	addw	a5,a5,a1
ffffffffc0201538:	c91c                	sw	a5,16(a0)
ffffffffc020153a:	57f5                	li	a5,-3
ffffffffc020153c:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201540:	6314                	ld	a3,0(a4)
ffffffffc0201542:	671c                	ld	a5,8(a4)
}
ffffffffc0201544:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201546:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201548:	e394                	sd	a3,0(a5)
ffffffffc020154a:	0141                	addi	sp,sp,16
ffffffffc020154c:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020154e:	00001697          	auipc	a3,0x1
ffffffffc0201552:	6a268693          	addi	a3,a3,1698 # ffffffffc0202bf0 <etext+0xc34>
ffffffffc0201556:	00001617          	auipc	a2,0x1
ffffffffc020155a:	33a60613          	addi	a2,a2,826 # ffffffffc0202890 <etext+0x8d4>
ffffffffc020155e:	08300593          	li	a1,131
ffffffffc0201562:	00001517          	auipc	a0,0x1
ffffffffc0201566:	34650513          	addi	a0,a0,838 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc020156a:	e69fe0ef          	jal	ffffffffc02003d2 <__panic>
    assert(n > 0);
ffffffffc020156e:	00001697          	auipc	a3,0x1
ffffffffc0201572:	67a68693          	addi	a3,a3,1658 # ffffffffc0202be8 <etext+0xc2c>
ffffffffc0201576:	00001617          	auipc	a2,0x1
ffffffffc020157a:	31a60613          	addi	a2,a2,794 # ffffffffc0202890 <etext+0x8d4>
ffffffffc020157e:	08000593          	li	a1,128
ffffffffc0201582:	00001517          	auipc	a0,0x1
ffffffffc0201586:	32650513          	addi	a0,a0,806 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc020158a:	e49fe0ef          	jal	ffffffffc02003d2 <__panic>

ffffffffc020158e <default_alloc_pages>:
    assert(n > 0);
ffffffffc020158e:	c959                	beqz	a0,ffffffffc0201624 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc0201590:	00006617          	auipc	a2,0x6
ffffffffc0201594:	a9860613          	addi	a2,a2,-1384 # ffffffffc0207028 <free_area>
ffffffffc0201598:	4a0c                	lw	a1,16(a2)
ffffffffc020159a:	86aa                	mv	a3,a0
ffffffffc020159c:	02059793          	slli	a5,a1,0x20
ffffffffc02015a0:	9381                	srli	a5,a5,0x20
ffffffffc02015a2:	00a7eb63          	bltu	a5,a0,ffffffffc02015b8 <default_alloc_pages+0x2a>
    list_entry_t *le = &free_list;
ffffffffc02015a6:	87b2                	mv	a5,a2
ffffffffc02015a8:	a029                	j	ffffffffc02015b2 <default_alloc_pages+0x24>
        if (p->property >= n) {
ffffffffc02015aa:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02015ae:	00d77763          	bgeu	a4,a3,ffffffffc02015bc <default_alloc_pages+0x2e>
    return listelm->next;
ffffffffc02015b2:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02015b4:	fec79be3          	bne	a5,a2,ffffffffc02015aa <default_alloc_pages+0x1c>
        return NULL;
ffffffffc02015b8:	4501                	li	a0,0
}
ffffffffc02015ba:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc02015bc:	6798                	ld	a4,8(a5)
    return listelm->prev;
ffffffffc02015be:	0007b803          	ld	a6,0(a5)
        if (page->property > n) {
ffffffffc02015c2:	ff87a883          	lw	a7,-8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02015c6:	fe878513          	addi	a0,a5,-24
    prev->next = next;
ffffffffc02015ca:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02015ce:	01073023          	sd	a6,0(a4)
        if (page->property > n) {
ffffffffc02015d2:	02089713          	slli	a4,a7,0x20
ffffffffc02015d6:	9301                	srli	a4,a4,0x20
            p->property = page->property - n;
ffffffffc02015d8:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc02015dc:	02e6fc63          	bgeu	a3,a4,ffffffffc0201614 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02015e0:	00269713          	slli	a4,a3,0x2
ffffffffc02015e4:	9736                	add	a4,a4,a3
ffffffffc02015e6:	070e                	slli	a4,a4,0x3
ffffffffc02015e8:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02015ea:	406888bb          	subw	a7,a7,t1
ffffffffc02015ee:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015f2:	4689                	li	a3,2
ffffffffc02015f4:	00870593          	addi	a1,a4,8
ffffffffc02015f8:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02015fc:	00883683          	ld	a3,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc0201600:	01870893          	addi	a7,a4,24
        nr_free -= n;
ffffffffc0201604:	4a0c                	lw	a1,16(a2)
    prev->next = next->prev = elm;
ffffffffc0201606:	0116b023          	sd	a7,0(a3)
ffffffffc020160a:	01183423          	sd	a7,8(a6)
    elm->next = next;
ffffffffc020160e:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201610:	01073c23          	sd	a6,24(a4)
ffffffffc0201614:	406585bb          	subw	a1,a1,t1
ffffffffc0201618:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020161a:	5775                	li	a4,-3
ffffffffc020161c:	17c1                	addi	a5,a5,-16
ffffffffc020161e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201622:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201624:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201626:	00001697          	auipc	a3,0x1
ffffffffc020162a:	5c268693          	addi	a3,a3,1474 # ffffffffc0202be8 <etext+0xc2c>
ffffffffc020162e:	00001617          	auipc	a2,0x1
ffffffffc0201632:	26260613          	addi	a2,a2,610 # ffffffffc0202890 <etext+0x8d4>
ffffffffc0201636:	06200593          	li	a1,98
ffffffffc020163a:	00001517          	auipc	a0,0x1
ffffffffc020163e:	26e50513          	addi	a0,a0,622 # ffffffffc02028a8 <etext+0x8ec>
default_alloc_pages(size_t n) {
ffffffffc0201642:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201644:	d8ffe0ef          	jal	ffffffffc02003d2 <__panic>

ffffffffc0201648 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201648:	1141                	addi	sp,sp,-16
ffffffffc020164a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020164c:	c9e1                	beqz	a1,ffffffffc020171c <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc020164e:	00259713          	slli	a4,a1,0x2
ffffffffc0201652:	972e                	add	a4,a4,a1
ffffffffc0201654:	070e                	slli	a4,a4,0x3
ffffffffc0201656:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020165a:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020165c:	cf11                	beqz	a4,ffffffffc0201678 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020165e:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201660:	8b05                	andi	a4,a4,1
ffffffffc0201662:	cf49                	beqz	a4,ffffffffc02016fc <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201664:	0007a823          	sw	zero,16(a5)
ffffffffc0201668:	0007b423          	sd	zero,8(a5)
ffffffffc020166c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201670:	02878793          	addi	a5,a5,40
ffffffffc0201674:	fed795e3          	bne	a5,a3,ffffffffc020165e <default_init_memmap+0x16>
    base->property = n;
ffffffffc0201678:	2581                	sext.w	a1,a1
ffffffffc020167a:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020167c:	4789                	li	a5,2
ffffffffc020167e:	00850713          	addi	a4,a0,8
ffffffffc0201682:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201686:	00006697          	auipc	a3,0x6
ffffffffc020168a:	9a268693          	addi	a3,a3,-1630 # ffffffffc0207028 <free_area>
ffffffffc020168e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201690:	669c                	ld	a5,8(a3)
ffffffffc0201692:	9f2d                	addw	a4,a4,a1
ffffffffc0201694:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201696:	04d78663          	beq	a5,a3,ffffffffc02016e2 <default_init_memmap+0x9a>
            struct Page* page = le2page(le, page_link);
ffffffffc020169a:	fe878713          	addi	a4,a5,-24
ffffffffc020169e:	4581                	li	a1,0
ffffffffc02016a0:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02016a4:	00e56a63          	bltu	a0,a4,ffffffffc02016b8 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02016a8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02016aa:	02d70263          	beq	a4,a3,ffffffffc02016ce <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc02016ae:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02016b0:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016b4:	fee57ae3          	bgeu	a0,a4,ffffffffc02016a8 <default_init_memmap+0x60>
ffffffffc02016b8:	c199                	beqz	a1,ffffffffc02016be <default_init_memmap+0x76>
ffffffffc02016ba:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016be:	6398                	ld	a4,0(a5)
}
ffffffffc02016c0:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02016c2:	e390                	sd	a2,0(a5)
ffffffffc02016c4:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02016c6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016c8:	ed18                	sd	a4,24(a0)
ffffffffc02016ca:	0141                	addi	sp,sp,16
ffffffffc02016cc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02016ce:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016d0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02016d2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02016d4:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02016d6:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016d8:	00d70e63          	beq	a4,a3,ffffffffc02016f4 <default_init_memmap+0xac>
ffffffffc02016dc:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02016de:	87ba                	mv	a5,a4
ffffffffc02016e0:	bfc1                	j	ffffffffc02016b0 <default_init_memmap+0x68>
}
ffffffffc02016e2:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02016e4:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02016e8:	e398                	sd	a4,0(a5)
ffffffffc02016ea:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02016ec:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016ee:	ed1c                	sd	a5,24(a0)
}
ffffffffc02016f0:	0141                	addi	sp,sp,16
ffffffffc02016f2:	8082                	ret
ffffffffc02016f4:	60a2                	ld	ra,8(sp)
ffffffffc02016f6:	e290                	sd	a2,0(a3)
ffffffffc02016f8:	0141                	addi	sp,sp,16
ffffffffc02016fa:	8082                	ret
        assert(PageReserved(p));
ffffffffc02016fc:	00001697          	auipc	a3,0x1
ffffffffc0201700:	51c68693          	addi	a3,a3,1308 # ffffffffc0202c18 <etext+0xc5c>
ffffffffc0201704:	00001617          	auipc	a2,0x1
ffffffffc0201708:	18c60613          	addi	a2,a2,396 # ffffffffc0202890 <etext+0x8d4>
ffffffffc020170c:	04900593          	li	a1,73
ffffffffc0201710:	00001517          	auipc	a0,0x1
ffffffffc0201714:	19850513          	addi	a0,a0,408 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201718:	cbbfe0ef          	jal	ffffffffc02003d2 <__panic>
    assert(n > 0);
ffffffffc020171c:	00001697          	auipc	a3,0x1
ffffffffc0201720:	4cc68693          	addi	a3,a3,1228 # ffffffffc0202be8 <etext+0xc2c>
ffffffffc0201724:	00001617          	auipc	a2,0x1
ffffffffc0201728:	16c60613          	addi	a2,a2,364 # ffffffffc0202890 <etext+0x8d4>
ffffffffc020172c:	04600593          	li	a1,70
ffffffffc0201730:	00001517          	auipc	a0,0x1
ffffffffc0201734:	17850513          	addi	a0,a0,376 # ffffffffc02028a8 <etext+0x8ec>
ffffffffc0201738:	c9bfe0ef          	jal	ffffffffc02003d2 <__panic>

ffffffffc020173c <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020173c:	100027f3          	csrr	a5,sstatus
ffffffffc0201740:	8b89                	andi	a5,a5,2
ffffffffc0201742:	e799                	bnez	a5,ffffffffc0201750 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201744:	00006797          	auipc	a5,0x6
ffffffffc0201748:	d247b783          	ld	a5,-732(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc020174c:	6f9c                	ld	a5,24(a5)
ffffffffc020174e:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0201750:	1141                	addi	sp,sp,-16
ffffffffc0201752:	e406                	sd	ra,8(sp)
ffffffffc0201754:	e022                	sd	s0,0(sp)
ffffffffc0201756:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201758:	8aaff0ef          	jal	ffffffffc0200802 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020175c:	00006797          	auipc	a5,0x6
ffffffffc0201760:	d0c7b783          	ld	a5,-756(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc0201764:	6f9c                	ld	a5,24(a5)
ffffffffc0201766:	8522                	mv	a0,s0
ffffffffc0201768:	9782                	jalr	a5
ffffffffc020176a:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc020176c:	890ff0ef          	jal	ffffffffc02007fc <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201770:	60a2                	ld	ra,8(sp)
ffffffffc0201772:	8522                	mv	a0,s0
ffffffffc0201774:	6402                	ld	s0,0(sp)
ffffffffc0201776:	0141                	addi	sp,sp,16
ffffffffc0201778:	8082                	ret

ffffffffc020177a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020177a:	100027f3          	csrr	a5,sstatus
ffffffffc020177e:	8b89                	andi	a5,a5,2
ffffffffc0201780:	e799                	bnez	a5,ffffffffc020178e <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201782:	00006797          	auipc	a5,0x6
ffffffffc0201786:	ce67b783          	ld	a5,-794(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc020178a:	739c                	ld	a5,32(a5)
ffffffffc020178c:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc020178e:	1101                	addi	sp,sp,-32
ffffffffc0201790:	ec06                	sd	ra,24(sp)
ffffffffc0201792:	e822                	sd	s0,16(sp)
ffffffffc0201794:	e426                	sd	s1,8(sp)
ffffffffc0201796:	842a                	mv	s0,a0
ffffffffc0201798:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020179a:	868ff0ef          	jal	ffffffffc0200802 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020179e:	00006797          	auipc	a5,0x6
ffffffffc02017a2:	cca7b783          	ld	a5,-822(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc02017a6:	739c                	ld	a5,32(a5)
ffffffffc02017a8:	85a6                	mv	a1,s1
ffffffffc02017aa:	8522                	mv	a0,s0
ffffffffc02017ac:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02017ae:	6442                	ld	s0,16(sp)
ffffffffc02017b0:	60e2                	ld	ra,24(sp)
ffffffffc02017b2:	64a2                	ld	s1,8(sp)
ffffffffc02017b4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02017b6:	846ff06f          	j	ffffffffc02007fc <intr_enable>

ffffffffc02017ba <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017ba:	100027f3          	csrr	a5,sstatus
ffffffffc02017be:	8b89                	andi	a5,a5,2
ffffffffc02017c0:	e799                	bnez	a5,ffffffffc02017ce <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02017c2:	00006797          	auipc	a5,0x6
ffffffffc02017c6:	ca67b783          	ld	a5,-858(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc02017ca:	779c                	ld	a5,40(a5)
ffffffffc02017cc:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02017ce:	1141                	addi	sp,sp,-16
ffffffffc02017d0:	e406                	sd	ra,8(sp)
ffffffffc02017d2:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02017d4:	82eff0ef          	jal	ffffffffc0200802 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02017d8:	00006797          	auipc	a5,0x6
ffffffffc02017dc:	c907b783          	ld	a5,-880(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc02017e0:	779c                	ld	a5,40(a5)
ffffffffc02017e2:	9782                	jalr	a5
ffffffffc02017e4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02017e6:	816ff0ef          	jal	ffffffffc02007fc <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02017ea:	60a2                	ld	ra,8(sp)
ffffffffc02017ec:	8522                	mv	a0,s0
ffffffffc02017ee:	6402                	ld	s0,0(sp)
ffffffffc02017f0:	0141                	addi	sp,sp,16
ffffffffc02017f2:	8082                	ret

ffffffffc02017f4 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02017f4:	00001797          	auipc	a5,0x1
ffffffffc02017f8:	6c478793          	addi	a5,a5,1732 # ffffffffc0202eb8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017fc:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02017fe:	7179                	addi	sp,sp,-48
ffffffffc0201800:	f406                	sd	ra,40(sp)
ffffffffc0201802:	f022                	sd	s0,32(sp)
ffffffffc0201804:	ec26                	sd	s1,24(sp)
ffffffffc0201806:	e052                	sd	s4,0(sp)
ffffffffc0201808:	e84a                	sd	s2,16(sp)
ffffffffc020180a:	e44e                	sd	s3,8(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020180c:	00006417          	auipc	s0,0x6
ffffffffc0201810:	c5c40413          	addi	s0,s0,-932 # ffffffffc0207468 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201814:	00001517          	auipc	a0,0x1
ffffffffc0201818:	42c50513          	addi	a0,a0,1068 # ffffffffc0202c40 <etext+0xc84>
    pmm_manager = &default_pmm_manager;
ffffffffc020181c:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020181e:	8c1fe0ef          	jal	ffffffffc02000de <cprintf>
    pmm_manager->init();
ffffffffc0201822:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201824:	00006497          	auipc	s1,0x6
ffffffffc0201828:	c5c48493          	addi	s1,s1,-932 # ffffffffc0207480 <va_pa_offset>
    pmm_manager->init();
ffffffffc020182c:	679c                	ld	a5,8(a5)
ffffffffc020182e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201830:	57f5                	li	a5,-3
ffffffffc0201832:	07fa                	slli	a5,a5,0x1e
ffffffffc0201834:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201836:	fb3fe0ef          	jal	ffffffffc02007e8 <get_memory_base>
ffffffffc020183a:	8a2a                	mv	s4,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020183c:	fb7fe0ef          	jal	ffffffffc02007f2 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201840:	18050363          	beqz	a0,ffffffffc02019c6 <pmm_init+0x1d2>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201844:	89aa                	mv	s3,a0
    cprintf("physcial memory map:\n");
ffffffffc0201846:	00001517          	auipc	a0,0x1
ffffffffc020184a:	44250513          	addi	a0,a0,1090 # ffffffffc0202c88 <etext+0xccc>
ffffffffc020184e:	891fe0ef          	jal	ffffffffc02000de <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201852:	013a0933          	add	s2,s4,s3
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201856:	fff90693          	addi	a3,s2,-1
ffffffffc020185a:	8652                	mv	a2,s4
ffffffffc020185c:	85ce                	mv	a1,s3
ffffffffc020185e:	00001517          	auipc	a0,0x1
ffffffffc0201862:	44250513          	addi	a0,a0,1090 # ffffffffc0202ca0 <etext+0xce4>
ffffffffc0201866:	879fe0ef          	jal	ffffffffc02000de <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc020186a:	c8000737          	lui	a4,0xc8000
ffffffffc020186e:	87ca                	mv	a5,s2
ffffffffc0201870:	0f276863          	bltu	a4,s2,ffffffffc0201960 <pmm_init+0x16c>
ffffffffc0201874:	00007697          	auipc	a3,0x7
ffffffffc0201878:	c2b68693          	addi	a3,a3,-981 # ffffffffc020849f <end+0xfff>
ffffffffc020187c:	777d                	lui	a4,0xfffff
ffffffffc020187e:	8ef9                	and	a3,a3,a4
    npage = maxpa / PGSIZE;
ffffffffc0201880:	83b1                	srli	a5,a5,0xc
ffffffffc0201882:	00006817          	auipc	a6,0x6
ffffffffc0201886:	c0680813          	addi	a6,a6,-1018 # ffffffffc0207488 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020188a:	00006597          	auipc	a1,0x6
ffffffffc020188e:	c0658593          	addi	a1,a1,-1018 # ffffffffc0207490 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201892:	00f83023          	sd	a5,0(a6)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201896:	e194                	sd	a3,0(a1)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201898:	00080637          	lui	a2,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020189c:	88b6                	mv	a7,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020189e:	04c78463          	beq	a5,a2,ffffffffc02018e6 <pmm_init+0xf2>
ffffffffc02018a2:	4785                	li	a5,1
ffffffffc02018a4:	00868713          	addi	a4,a3,8
ffffffffc02018a8:	40f7302f          	amoor.d	zero,a5,(a4)
ffffffffc02018ac:	00083783          	ld	a5,0(a6)
ffffffffc02018b0:	4705                	li	a4,1
ffffffffc02018b2:	02800693          	li	a3,40
ffffffffc02018b6:	40c78633          	sub	a2,a5,a2
ffffffffc02018ba:	4885                	li	a7,1
ffffffffc02018bc:	fff80537          	lui	a0,0xfff80
ffffffffc02018c0:	02c77063          	bgeu	a4,a2,ffffffffc02018e0 <pmm_init+0xec>
        SetPageReserved(pages + i);
ffffffffc02018c4:	619c                	ld	a5,0(a1)
ffffffffc02018c6:	97b6                	add	a5,a5,a3
ffffffffc02018c8:	07a1                	addi	a5,a5,8
ffffffffc02018ca:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018ce:	00083783          	ld	a5,0(a6)
ffffffffc02018d2:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0x3fdf7b61>
ffffffffc02018d4:	02868693          	addi	a3,a3,40
ffffffffc02018d8:	00a78633          	add	a2,a5,a0
ffffffffc02018dc:	fec764e3          	bltu	a4,a2,ffffffffc02018c4 <pmm_init+0xd0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018e0:	0005b883          	ld	a7,0(a1)
ffffffffc02018e4:	86c6                	mv	a3,a7
ffffffffc02018e6:	00279713          	slli	a4,a5,0x2
ffffffffc02018ea:	973e                	add	a4,a4,a5
ffffffffc02018ec:	fec00637          	lui	a2,0xfec00
ffffffffc02018f0:	070e                	slli	a4,a4,0x3
ffffffffc02018f2:	96b2                	add	a3,a3,a2
ffffffffc02018f4:	96ba                	add	a3,a3,a4
ffffffffc02018f6:	c0200737          	lui	a4,0xc0200
ffffffffc02018fa:	0ae6ea63          	bltu	a3,a4,ffffffffc02019ae <pmm_init+0x1ba>
ffffffffc02018fe:	6090                	ld	a2,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201900:	777d                	lui	a4,0xfffff
ffffffffc0201902:	00e97933          	and	s2,s2,a4
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201906:	8e91                	sub	a3,a3,a2
    if (freemem < mem_end) {
ffffffffc0201908:	0526ef63          	bltu	a3,s2,ffffffffc0201966 <pmm_init+0x172>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020190c:	601c                	ld	a5,0(s0)
ffffffffc020190e:	7b9c                	ld	a5,48(a5)
ffffffffc0201910:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201912:	00001517          	auipc	a0,0x1
ffffffffc0201916:	41650513          	addi	a0,a0,1046 # ffffffffc0202d28 <etext+0xd6c>
ffffffffc020191a:	fc4fe0ef          	jal	ffffffffc02000de <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020191e:	00004597          	auipc	a1,0x4
ffffffffc0201922:	6e258593          	addi	a1,a1,1762 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0201926:	00006797          	auipc	a5,0x6
ffffffffc020192a:	b4b7b923          	sd	a1,-1198(a5) # ffffffffc0207478 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020192e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201932:	0af5e663          	bltu	a1,a5,ffffffffc02019de <pmm_init+0x1ea>
ffffffffc0201936:	609c                	ld	a5,0(s1)
}
ffffffffc0201938:	7402                	ld	s0,32(sp)
ffffffffc020193a:	70a2                	ld	ra,40(sp)
ffffffffc020193c:	64e2                	ld	s1,24(sp)
ffffffffc020193e:	6942                	ld	s2,16(sp)
ffffffffc0201940:	69a2                	ld	s3,8(sp)
ffffffffc0201942:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201944:	40f586b3          	sub	a3,a1,a5
ffffffffc0201948:	00006797          	auipc	a5,0x6
ffffffffc020194c:	b2d7b423          	sd	a3,-1240(a5) # ffffffffc0207470 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201950:	00001517          	auipc	a0,0x1
ffffffffc0201954:	3f850513          	addi	a0,a0,1016 # ffffffffc0202d48 <etext+0xd8c>
ffffffffc0201958:	8636                	mv	a2,a3
}
ffffffffc020195a:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020195c:	f82fe06f          	j	ffffffffc02000de <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0201960:	c80007b7          	lui	a5,0xc8000
ffffffffc0201964:	bf01                	j	ffffffffc0201874 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201966:	6605                	lui	a2,0x1
ffffffffc0201968:	167d                	addi	a2,a2,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020196a:	96b2                	add	a3,a3,a2
ffffffffc020196c:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020196e:	00c6d713          	srli	a4,a3,0xc
ffffffffc0201972:	02f77263          	bgeu	a4,a5,ffffffffc0201996 <pmm_init+0x1a2>
    pmm_manager->init_memmap(base, n);
ffffffffc0201976:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201978:	fff807b7          	lui	a5,0xfff80
ffffffffc020197c:	97ba                	add	a5,a5,a4
ffffffffc020197e:	00279513          	slli	a0,a5,0x2
ffffffffc0201982:	953e                	add	a0,a0,a5
ffffffffc0201984:	6a1c                	ld	a5,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201986:	40d90933          	sub	s2,s2,a3
ffffffffc020198a:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020198c:	00c95593          	srli	a1,s2,0xc
ffffffffc0201990:	9546                	add	a0,a0,a7
ffffffffc0201992:	9782                	jalr	a5
}
ffffffffc0201994:	bfa5                	j	ffffffffc020190c <pmm_init+0x118>
        panic("pa2page called with invalid pa");
ffffffffc0201996:	00001617          	auipc	a2,0x1
ffffffffc020199a:	36260613          	addi	a2,a2,866 # ffffffffc0202cf8 <etext+0xd3c>
ffffffffc020199e:	06b00593          	li	a1,107
ffffffffc02019a2:	00001517          	auipc	a0,0x1
ffffffffc02019a6:	37650513          	addi	a0,a0,886 # ffffffffc0202d18 <etext+0xd5c>
ffffffffc02019aa:	a29fe0ef          	jal	ffffffffc02003d2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02019ae:	00001617          	auipc	a2,0x1
ffffffffc02019b2:	32260613          	addi	a2,a2,802 # ffffffffc0202cd0 <etext+0xd14>
ffffffffc02019b6:	07100593          	li	a1,113
ffffffffc02019ba:	00001517          	auipc	a0,0x1
ffffffffc02019be:	2be50513          	addi	a0,a0,702 # ffffffffc0202c78 <etext+0xcbc>
ffffffffc02019c2:	a11fe0ef          	jal	ffffffffc02003d2 <__panic>
        panic("DTB memory info not available");
ffffffffc02019c6:	00001617          	auipc	a2,0x1
ffffffffc02019ca:	29260613          	addi	a2,a2,658 # ffffffffc0202c58 <etext+0xc9c>
ffffffffc02019ce:	05a00593          	li	a1,90
ffffffffc02019d2:	00001517          	auipc	a0,0x1
ffffffffc02019d6:	2a650513          	addi	a0,a0,678 # ffffffffc0202c78 <etext+0xcbc>
ffffffffc02019da:	9f9fe0ef          	jal	ffffffffc02003d2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02019de:	86ae                	mv	a3,a1
ffffffffc02019e0:	00001617          	auipc	a2,0x1
ffffffffc02019e4:	2f060613          	addi	a2,a2,752 # ffffffffc0202cd0 <etext+0xd14>
ffffffffc02019e8:	08c00593          	li	a1,140
ffffffffc02019ec:	00001517          	auipc	a0,0x1
ffffffffc02019f0:	28c50513          	addi	a0,a0,652 # ffffffffc0202c78 <etext+0xcbc>
ffffffffc02019f4:	9dffe0ef          	jal	ffffffffc02003d2 <__panic>

ffffffffc02019f8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02019f8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019fc:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02019fe:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a02:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201a04:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a08:	f022                	sd	s0,32(sp)
ffffffffc0201a0a:	ec26                	sd	s1,24(sp)
ffffffffc0201a0c:	e84a                	sd	s2,16(sp)
ffffffffc0201a0e:	f406                	sd	ra,40(sp)
ffffffffc0201a10:	84aa                	mv	s1,a0
ffffffffc0201a12:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201a14:	fff7041b          	addiw	s0,a4,-1 # ffffffffffffefff <end+0x3fdf7b5f>
    unsigned mod = do_div(result, base);
ffffffffc0201a18:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201a1a:	05067063          	bgeu	a2,a6,ffffffffc0201a5a <printnum+0x62>
ffffffffc0201a1e:	e44e                	sd	s3,8(sp)
ffffffffc0201a20:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201a22:	4785                	li	a5,1
ffffffffc0201a24:	00e7d763          	bge	a5,a4,ffffffffc0201a32 <printnum+0x3a>
            putch(padc, putdat);
ffffffffc0201a28:	85ca                	mv	a1,s2
ffffffffc0201a2a:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0201a2c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201a2e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a30:	fc65                	bnez	s0,ffffffffc0201a28 <printnum+0x30>
ffffffffc0201a32:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a34:	1a02                	slli	s4,s4,0x20
ffffffffc0201a36:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201a3a:	00001797          	auipc	a5,0x1
ffffffffc0201a3e:	34e78793          	addi	a5,a5,846 # ffffffffc0202d88 <etext+0xdcc>
ffffffffc0201a42:	97d2                	add	a5,a5,s4
}
ffffffffc0201a44:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a46:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0201a4a:	70a2                	ld	ra,40(sp)
ffffffffc0201a4c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a4e:	85ca                	mv	a1,s2
ffffffffc0201a50:	87a6                	mv	a5,s1
}
ffffffffc0201a52:	6942                	ld	s2,16(sp)
ffffffffc0201a54:	64e2                	ld	s1,24(sp)
ffffffffc0201a56:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a58:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a5a:	03065633          	divu	a2,a2,a6
ffffffffc0201a5e:	8722                	mv	a4,s0
ffffffffc0201a60:	f99ff0ef          	jal	ffffffffc02019f8 <printnum>
ffffffffc0201a64:	bfc1                	j	ffffffffc0201a34 <printnum+0x3c>

ffffffffc0201a66 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a66:	7119                	addi	sp,sp,-128
ffffffffc0201a68:	f4a6                	sd	s1,104(sp)
ffffffffc0201a6a:	f0ca                	sd	s2,96(sp)
ffffffffc0201a6c:	ecce                	sd	s3,88(sp)
ffffffffc0201a6e:	e8d2                	sd	s4,80(sp)
ffffffffc0201a70:	e4d6                	sd	s5,72(sp)
ffffffffc0201a72:	e0da                	sd	s6,64(sp)
ffffffffc0201a74:	f862                	sd	s8,48(sp)
ffffffffc0201a76:	fc86                	sd	ra,120(sp)
ffffffffc0201a78:	f8a2                	sd	s0,112(sp)
ffffffffc0201a7a:	fc5e                	sd	s7,56(sp)
ffffffffc0201a7c:	f466                	sd	s9,40(sp)
ffffffffc0201a7e:	f06a                	sd	s10,32(sp)
ffffffffc0201a80:	ec6e                	sd	s11,24(sp)
ffffffffc0201a82:	892a                	mv	s2,a0
ffffffffc0201a84:	84ae                	mv	s1,a1
ffffffffc0201a86:	8c32                	mv	s8,a2
ffffffffc0201a88:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a8a:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a8e:	05500b13          	li	s6,85
ffffffffc0201a92:	00001a97          	auipc	s5,0x1
ffffffffc0201a96:	45ea8a93          	addi	s5,s5,1118 # ffffffffc0202ef0 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a9a:	000c4503          	lbu	a0,0(s8)
ffffffffc0201a9e:	001c0413          	addi	s0,s8,1
ffffffffc0201aa2:	01350a63          	beq	a0,s3,ffffffffc0201ab6 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201aa6:	cd0d                	beqz	a0,ffffffffc0201ae0 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201aa8:	85a6                	mv	a1,s1
ffffffffc0201aaa:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201aac:	00044503          	lbu	a0,0(s0)
ffffffffc0201ab0:	0405                	addi	s0,s0,1
ffffffffc0201ab2:	ff351ae3          	bne	a0,s3,ffffffffc0201aa6 <vprintfmt+0x40>
        char padc = ' ';
ffffffffc0201ab6:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0201aba:	4b81                	li	s7,0
ffffffffc0201abc:	4601                	li	a2,0
        width = precision = -1;
ffffffffc0201abe:	5d7d                	li	s10,-1
ffffffffc0201ac0:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ac2:	00044683          	lbu	a3,0(s0)
ffffffffc0201ac6:	00140c13          	addi	s8,s0,1
ffffffffc0201aca:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0201ace:	0ff5f593          	zext.b	a1,a1
ffffffffc0201ad2:	02bb6663          	bltu	s6,a1,ffffffffc0201afe <vprintfmt+0x98>
ffffffffc0201ad6:	058a                	slli	a1,a1,0x2
ffffffffc0201ad8:	95d6                	add	a1,a1,s5
ffffffffc0201ada:	4198                	lw	a4,0(a1)
ffffffffc0201adc:	9756                	add	a4,a4,s5
ffffffffc0201ade:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201ae0:	70e6                	ld	ra,120(sp)
ffffffffc0201ae2:	7446                	ld	s0,112(sp)
ffffffffc0201ae4:	74a6                	ld	s1,104(sp)
ffffffffc0201ae6:	7906                	ld	s2,96(sp)
ffffffffc0201ae8:	69e6                	ld	s3,88(sp)
ffffffffc0201aea:	6a46                	ld	s4,80(sp)
ffffffffc0201aec:	6aa6                	ld	s5,72(sp)
ffffffffc0201aee:	6b06                	ld	s6,64(sp)
ffffffffc0201af0:	7be2                	ld	s7,56(sp)
ffffffffc0201af2:	7c42                	ld	s8,48(sp)
ffffffffc0201af4:	7ca2                	ld	s9,40(sp)
ffffffffc0201af6:	7d02                	ld	s10,32(sp)
ffffffffc0201af8:	6de2                	ld	s11,24(sp)
ffffffffc0201afa:	6109                	addi	sp,sp,128
ffffffffc0201afc:	8082                	ret
            putch('%', putdat);
ffffffffc0201afe:	85a6                	mv	a1,s1
ffffffffc0201b00:	02500513          	li	a0,37
ffffffffc0201b04:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201b06:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201b0a:	02500793          	li	a5,37
ffffffffc0201b0e:	8c22                	mv	s8,s0
ffffffffc0201b10:	f8f705e3          	beq	a4,a5,ffffffffc0201a9a <vprintfmt+0x34>
ffffffffc0201b14:	02500713          	li	a4,37
ffffffffc0201b18:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201b1c:	1c7d                	addi	s8,s8,-1
ffffffffc0201b1e:	fee79de3          	bne	a5,a4,ffffffffc0201b18 <vprintfmt+0xb2>
ffffffffc0201b22:	bfa5                	j	ffffffffc0201a9a <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0201b24:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0201b28:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0201b2a:	fd068d1b          	addiw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0201b2e:	fd07859b          	addiw	a1,a5,-48
                ch = *fmt;
ffffffffc0201b32:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b36:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0201b38:	02b76563          	bltu	a4,a1,ffffffffc0201b62 <vprintfmt+0xfc>
ffffffffc0201b3c:	4525                	li	a0,9
                ch = *fmt;
ffffffffc0201b3e:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b42:	002d171b          	slliw	a4,s10,0x2
ffffffffc0201b46:	01a7073b          	addw	a4,a4,s10
ffffffffc0201b4a:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b4e:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201b50:	fd07859b          	addiw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b54:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b56:	fd070d1b          	addiw	s10,a4,-48
                ch = *fmt;
ffffffffc0201b5a:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc0201b5e:	feb570e3          	bgeu	a0,a1,ffffffffc0201b3e <vprintfmt+0xd8>
            if (width < 0)
ffffffffc0201b62:	f60cd0e3          	bgez	s9,ffffffffc0201ac2 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0201b66:	8cea                	mv	s9,s10
ffffffffc0201b68:	5d7d                	li	s10,-1
ffffffffc0201b6a:	bfa1                	j	ffffffffc0201ac2 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b6c:	8db6                	mv	s11,a3
ffffffffc0201b6e:	8462                	mv	s0,s8
ffffffffc0201b70:	bf89                	j	ffffffffc0201ac2 <vprintfmt+0x5c>
ffffffffc0201b72:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0201b74:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0201b76:	b7b1                	j	ffffffffc0201ac2 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0201b78:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201b7a:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201b7e:	00c7c463          	blt	a5,a2,ffffffffc0201b86 <vprintfmt+0x120>
    else if (lflag) {
ffffffffc0201b82:	1a060163          	beqz	a2,ffffffffc0201d24 <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0201b86:	000a3603          	ld	a2,0(s4)
ffffffffc0201b8a:	46c1                	li	a3,16
ffffffffc0201b8c:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b8e:	000d879b          	sext.w	a5,s11
ffffffffc0201b92:	8766                	mv	a4,s9
ffffffffc0201b94:	85a6                	mv	a1,s1
ffffffffc0201b96:	854a                	mv	a0,s2
ffffffffc0201b98:	e61ff0ef          	jal	ffffffffc02019f8 <printnum>
            break;
ffffffffc0201b9c:	bdfd                	j	ffffffffc0201a9a <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b9e:	000a2503          	lw	a0,0(s4)
ffffffffc0201ba2:	85a6                	mv	a1,s1
ffffffffc0201ba4:	0a21                	addi	s4,s4,8
ffffffffc0201ba6:	9902                	jalr	s2
            break;
ffffffffc0201ba8:	bdcd                	j	ffffffffc0201a9a <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201baa:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201bac:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201bb0:	00c7c463          	blt	a5,a2,ffffffffc0201bb8 <vprintfmt+0x152>
    else if (lflag) {
ffffffffc0201bb4:	16060363          	beqz	a2,ffffffffc0201d1a <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0201bb8:	000a3603          	ld	a2,0(s4)
ffffffffc0201bbc:	46a9                	li	a3,10
ffffffffc0201bbe:	8a3a                	mv	s4,a4
ffffffffc0201bc0:	b7f9                	j	ffffffffc0201b8e <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc0201bc2:	85a6                	mv	a1,s1
ffffffffc0201bc4:	03000513          	li	a0,48
ffffffffc0201bc8:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201bca:	85a6                	mv	a1,s1
ffffffffc0201bcc:	07800513          	li	a0,120
ffffffffc0201bd0:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bd2:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201bd6:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bd8:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201bda:	bf55                	j	ffffffffc0201b8e <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0201bdc:	85a6                	mv	a1,s1
ffffffffc0201bde:	02500513          	li	a0,37
ffffffffc0201be2:	9902                	jalr	s2
            break;
ffffffffc0201be4:	bd5d                	j	ffffffffc0201a9a <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201be6:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bea:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201bec:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201bee:	bf95                	j	ffffffffc0201b62 <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc0201bf0:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201bf2:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201bf6:	00c7c463          	blt	a5,a2,ffffffffc0201bfe <vprintfmt+0x198>
    else if (lflag) {
ffffffffc0201bfa:	10060b63          	beqz	a2,ffffffffc0201d10 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0201bfe:	000a3603          	ld	a2,0(s4)
ffffffffc0201c02:	46a1                	li	a3,8
ffffffffc0201c04:	8a3a                	mv	s4,a4
ffffffffc0201c06:	b761                	j	ffffffffc0201b8e <vprintfmt+0x128>
            if (width < 0)
ffffffffc0201c08:	fffcc793          	not	a5,s9
ffffffffc0201c0c:	97fd                	srai	a5,a5,0x3f
ffffffffc0201c0e:	00fcf7b3          	and	a5,s9,a5
ffffffffc0201c12:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c16:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201c18:	b56d                	j	ffffffffc0201ac2 <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c1a:	000a3403          	ld	s0,0(s4)
ffffffffc0201c1e:	008a0793          	addi	a5,s4,8
ffffffffc0201c22:	e43e                	sd	a5,8(sp)
ffffffffc0201c24:	12040063          	beqz	s0,ffffffffc0201d44 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0201c28:	0d905963          	blez	s9,ffffffffc0201cfa <vprintfmt+0x294>
ffffffffc0201c2c:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c30:	00140a13          	addi	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc0201c34:	12fd9763          	bne	s11,a5,ffffffffc0201d62 <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c38:	00044783          	lbu	a5,0(s0)
ffffffffc0201c3c:	0007851b          	sext.w	a0,a5
ffffffffc0201c40:	cb9d                	beqz	a5,ffffffffc0201c76 <vprintfmt+0x210>
ffffffffc0201c42:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c44:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c48:	000d4563          	bltz	s10,ffffffffc0201c52 <vprintfmt+0x1ec>
ffffffffc0201c4c:	3d7d                	addiw	s10,s10,-1
ffffffffc0201c4e:	028d0263          	beq	s10,s0,ffffffffc0201c72 <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc0201c52:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c54:	0c0b8d63          	beqz	s7,ffffffffc0201d2e <vprintfmt+0x2c8>
ffffffffc0201c58:	3781                	addiw	a5,a5,-32
ffffffffc0201c5a:	0cfdfa63          	bgeu	s11,a5,ffffffffc0201d2e <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc0201c5e:	03f00513          	li	a0,63
ffffffffc0201c62:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c64:	000a4783          	lbu	a5,0(s4)
ffffffffc0201c68:	3cfd                	addiw	s9,s9,-1 # feffff <kern_entry-0xffffffffbf210001>
ffffffffc0201c6a:	0a05                	addi	s4,s4,1
ffffffffc0201c6c:	0007851b          	sext.w	a0,a5
ffffffffc0201c70:	ffe1                	bnez	a5,ffffffffc0201c48 <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc0201c72:	01905963          	blez	s9,ffffffffc0201c84 <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc0201c76:	85a6                	mv	a1,s1
ffffffffc0201c78:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0201c7c:	3cfd                	addiw	s9,s9,-1
                putch(' ', putdat);
ffffffffc0201c7e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201c80:	fe0c9be3          	bnez	s9,ffffffffc0201c76 <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c84:	6a22                	ld	s4,8(sp)
ffffffffc0201c86:	bd11                	j	ffffffffc0201a9a <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201c88:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201c8a:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201c8e:	00c7c363          	blt	a5,a2,ffffffffc0201c94 <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc0201c92:	ce25                	beqz	a2,ffffffffc0201d0a <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc0201c94:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c98:	08044d63          	bltz	s0,ffffffffc0201d32 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201c9c:	8622                	mv	a2,s0
ffffffffc0201c9e:	8a5e                	mv	s4,s7
ffffffffc0201ca0:	46a9                	li	a3,10
ffffffffc0201ca2:	b5f5                	j	ffffffffc0201b8e <vprintfmt+0x128>
            if (err < 0) {
ffffffffc0201ca4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201ca8:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0201caa:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201cae:	8fb9                	xor	a5,a5,a4
ffffffffc0201cb0:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201cb4:	02d64663          	blt	a2,a3,ffffffffc0201ce0 <vprintfmt+0x27a>
ffffffffc0201cb8:	00369713          	slli	a4,a3,0x3
ffffffffc0201cbc:	00001797          	auipc	a5,0x1
ffffffffc0201cc0:	38c78793          	addi	a5,a5,908 # ffffffffc0203048 <error_string>
ffffffffc0201cc4:	97ba                	add	a5,a5,a4
ffffffffc0201cc6:	639c                	ld	a5,0(a5)
ffffffffc0201cc8:	cf81                	beqz	a5,ffffffffc0201ce0 <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201cca:	86be                	mv	a3,a5
ffffffffc0201ccc:	00001617          	auipc	a2,0x1
ffffffffc0201cd0:	0ec60613          	addi	a2,a2,236 # ffffffffc0202db8 <etext+0xdfc>
ffffffffc0201cd4:	85a6                	mv	a1,s1
ffffffffc0201cd6:	854a                	mv	a0,s2
ffffffffc0201cd8:	0e8000ef          	jal	ffffffffc0201dc0 <printfmt>
            err = va_arg(ap, int);
ffffffffc0201cdc:	0a21                	addi	s4,s4,8
ffffffffc0201cde:	bb75                	j	ffffffffc0201a9a <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201ce0:	00001617          	auipc	a2,0x1
ffffffffc0201ce4:	0c860613          	addi	a2,a2,200 # ffffffffc0202da8 <etext+0xdec>
ffffffffc0201ce8:	85a6                	mv	a1,s1
ffffffffc0201cea:	854a                	mv	a0,s2
ffffffffc0201cec:	0d4000ef          	jal	ffffffffc0201dc0 <printfmt>
            err = va_arg(ap, int);
ffffffffc0201cf0:	0a21                	addi	s4,s4,8
ffffffffc0201cf2:	b365                	j	ffffffffc0201a9a <vprintfmt+0x34>
            lflag ++;
ffffffffc0201cf4:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cf6:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201cf8:	b3e9                	j	ffffffffc0201ac2 <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cfa:	00044783          	lbu	a5,0(s0)
ffffffffc0201cfe:	0007851b          	sext.w	a0,a5
ffffffffc0201d02:	d3c9                	beqz	a5,ffffffffc0201c84 <vprintfmt+0x21e>
ffffffffc0201d04:	00140a13          	addi	s4,s0,1
ffffffffc0201d08:	bf2d                	j	ffffffffc0201c42 <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc0201d0a:	000a2403          	lw	s0,0(s4)
ffffffffc0201d0e:	b769                	j	ffffffffc0201c98 <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc0201d10:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d14:	46a1                	li	a3,8
ffffffffc0201d16:	8a3a                	mv	s4,a4
ffffffffc0201d18:	bd9d                	j	ffffffffc0201b8e <vprintfmt+0x128>
ffffffffc0201d1a:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d1e:	46a9                	li	a3,10
ffffffffc0201d20:	8a3a                	mv	s4,a4
ffffffffc0201d22:	b5b5                	j	ffffffffc0201b8e <vprintfmt+0x128>
ffffffffc0201d24:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d28:	46c1                	li	a3,16
ffffffffc0201d2a:	8a3a                	mv	s4,a4
ffffffffc0201d2c:	b58d                	j	ffffffffc0201b8e <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc0201d2e:	9902                	jalr	s2
ffffffffc0201d30:	bf15                	j	ffffffffc0201c64 <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc0201d32:	85a6                	mv	a1,s1
ffffffffc0201d34:	02d00513          	li	a0,45
ffffffffc0201d38:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d3a:	40800633          	neg	a2,s0
ffffffffc0201d3e:	8a5e                	mv	s4,s7
ffffffffc0201d40:	46a9                	li	a3,10
ffffffffc0201d42:	b5b1                	j	ffffffffc0201b8e <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc0201d44:	01905663          	blez	s9,ffffffffc0201d50 <vprintfmt+0x2ea>
ffffffffc0201d48:	02d00793          	li	a5,45
ffffffffc0201d4c:	04fd9263          	bne	s11,a5,ffffffffc0201d90 <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d50:	02800793          	li	a5,40
ffffffffc0201d54:	00001a17          	auipc	s4,0x1
ffffffffc0201d58:	04da0a13          	addi	s4,s4,77 # ffffffffc0202da1 <etext+0xde5>
ffffffffc0201d5c:	02800513          	li	a0,40
ffffffffc0201d60:	b5cd                	j	ffffffffc0201c42 <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d62:	85ea                	mv	a1,s10
ffffffffc0201d64:	8522                	mv	a0,s0
ffffffffc0201d66:	1b2000ef          	jal	ffffffffc0201f18 <strnlen>
ffffffffc0201d6a:	40ac8cbb          	subw	s9,s9,a0
ffffffffc0201d6e:	01905963          	blez	s9,ffffffffc0201d80 <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc0201d72:	2d81                	sext.w	s11,s11
ffffffffc0201d74:	85a6                	mv	a1,s1
ffffffffc0201d76:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d78:	3cfd                	addiw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc0201d7a:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d7c:	fe0c9ce3          	bnez	s9,ffffffffc0201d74 <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d80:	00044783          	lbu	a5,0(s0)
ffffffffc0201d84:	0007851b          	sext.w	a0,a5
ffffffffc0201d88:	ea079de3          	bnez	a5,ffffffffc0201c42 <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d8c:	6a22                	ld	s4,8(sp)
ffffffffc0201d8e:	b331                	j	ffffffffc0201a9a <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d90:	85ea                	mv	a1,s10
ffffffffc0201d92:	00001517          	auipc	a0,0x1
ffffffffc0201d96:	00e50513          	addi	a0,a0,14 # ffffffffc0202da0 <etext+0xde4>
ffffffffc0201d9a:	17e000ef          	jal	ffffffffc0201f18 <strnlen>
ffffffffc0201d9e:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc0201da2:	00001417          	auipc	s0,0x1
ffffffffc0201da6:	ffe40413          	addi	s0,s0,-2 # ffffffffc0202da0 <etext+0xde4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201daa:	00001a17          	auipc	s4,0x1
ffffffffc0201dae:	ff7a0a13          	addi	s4,s4,-9 # ffffffffc0202da1 <etext+0xde5>
ffffffffc0201db2:	02800793          	li	a5,40
ffffffffc0201db6:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201dba:	fb904ce3          	bgtz	s9,ffffffffc0201d72 <vprintfmt+0x30c>
ffffffffc0201dbe:	b551                	j	ffffffffc0201c42 <vprintfmt+0x1dc>

ffffffffc0201dc0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201dc0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201dc2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201dc6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201dc8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201dca:	ec06                	sd	ra,24(sp)
ffffffffc0201dcc:	f83a                	sd	a4,48(sp)
ffffffffc0201dce:	fc3e                	sd	a5,56(sp)
ffffffffc0201dd0:	e0c2                	sd	a6,64(sp)
ffffffffc0201dd2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201dd4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201dd6:	c91ff0ef          	jal	ffffffffc0201a66 <vprintfmt>
}
ffffffffc0201dda:	60e2                	ld	ra,24(sp)
ffffffffc0201ddc:	6161                	addi	sp,sp,80
ffffffffc0201dde:	8082                	ret

ffffffffc0201de0 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201de0:	715d                	addi	sp,sp,-80
ffffffffc0201de2:	e486                	sd	ra,72(sp)
ffffffffc0201de4:	e0a2                	sd	s0,64(sp)
ffffffffc0201de6:	fc26                	sd	s1,56(sp)
ffffffffc0201de8:	f84a                	sd	s2,48(sp)
ffffffffc0201dea:	f44e                	sd	s3,40(sp)
ffffffffc0201dec:	f052                	sd	s4,32(sp)
ffffffffc0201dee:	ec56                	sd	s5,24(sp)
ffffffffc0201df0:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc0201df2:	c901                	beqz	a0,ffffffffc0201e02 <readline+0x22>
ffffffffc0201df4:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201df6:	00001517          	auipc	a0,0x1
ffffffffc0201dfa:	fc250513          	addi	a0,a0,-62 # ffffffffc0202db8 <etext+0xdfc>
ffffffffc0201dfe:	ae0fe0ef          	jal	ffffffffc02000de <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc0201e02:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e04:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201e06:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201e08:	4a29                	li	s4,10
ffffffffc0201e0a:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc0201e0c:	00005b17          	auipc	s6,0x5
ffffffffc0201e10:	234b0b13          	addi	s6,s6,564 # ffffffffc0207040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e14:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc0201e18:	b4afe0ef          	jal	ffffffffc0200162 <getchar>
        if (c < 0) {
ffffffffc0201e1c:	00054a63          	bltz	a0,ffffffffc0201e30 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e20:	00a4da63          	bge	s1,a0,ffffffffc0201e34 <readline+0x54>
ffffffffc0201e24:	0289d263          	bge	s3,s0,ffffffffc0201e48 <readline+0x68>
        c = getchar();
ffffffffc0201e28:	b3afe0ef          	jal	ffffffffc0200162 <getchar>
        if (c < 0) {
ffffffffc0201e2c:	fe055ae3          	bgez	a0,ffffffffc0201e20 <readline+0x40>
            return NULL;
ffffffffc0201e30:	4501                	li	a0,0
ffffffffc0201e32:	a091                	j	ffffffffc0201e76 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201e34:	03251463          	bne	a0,s2,ffffffffc0201e5c <readline+0x7c>
ffffffffc0201e38:	04804963          	bgtz	s0,ffffffffc0201e8a <readline+0xaa>
        c = getchar();
ffffffffc0201e3c:	b26fe0ef          	jal	ffffffffc0200162 <getchar>
        if (c < 0) {
ffffffffc0201e40:	fe0548e3          	bltz	a0,ffffffffc0201e30 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e44:	fea4d8e3          	bge	s1,a0,ffffffffc0201e34 <readline+0x54>
            cputchar(c);
ffffffffc0201e48:	e42a                	sd	a0,8(sp)
ffffffffc0201e4a:	ac8fe0ef          	jal	ffffffffc0200112 <cputchar>
            buf[i ++] = c;
ffffffffc0201e4e:	6522                	ld	a0,8(sp)
ffffffffc0201e50:	008b07b3          	add	a5,s6,s0
ffffffffc0201e54:	2405                	addiw	s0,s0,1
ffffffffc0201e56:	00a78023          	sb	a0,0(a5)
ffffffffc0201e5a:	bf7d                	j	ffffffffc0201e18 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201e5c:	01450463          	beq	a0,s4,ffffffffc0201e64 <readline+0x84>
ffffffffc0201e60:	fb551ce3          	bne	a0,s5,ffffffffc0201e18 <readline+0x38>
            cputchar(c);
ffffffffc0201e64:	aaefe0ef          	jal	ffffffffc0200112 <cputchar>
            buf[i] = '\0';
ffffffffc0201e68:	00005517          	auipc	a0,0x5
ffffffffc0201e6c:	1d850513          	addi	a0,a0,472 # ffffffffc0207040 <buf>
ffffffffc0201e70:	942a                	add	s0,s0,a0
ffffffffc0201e72:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc0201e76:	60a6                	ld	ra,72(sp)
ffffffffc0201e78:	6406                	ld	s0,64(sp)
ffffffffc0201e7a:	74e2                	ld	s1,56(sp)
ffffffffc0201e7c:	7942                	ld	s2,48(sp)
ffffffffc0201e7e:	79a2                	ld	s3,40(sp)
ffffffffc0201e80:	7a02                	ld	s4,32(sp)
ffffffffc0201e82:	6ae2                	ld	s5,24(sp)
ffffffffc0201e84:	6b42                	ld	s6,16(sp)
ffffffffc0201e86:	6161                	addi	sp,sp,80
ffffffffc0201e88:	8082                	ret
            cputchar(c);
ffffffffc0201e8a:	4521                	li	a0,8
ffffffffc0201e8c:	a86fe0ef          	jal	ffffffffc0200112 <cputchar>
            i --;
ffffffffc0201e90:	347d                	addiw	s0,s0,-1
ffffffffc0201e92:	b759                	j	ffffffffc0201e18 <readline+0x38>

ffffffffc0201e94 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201e94:	4781                	li	a5,0
ffffffffc0201e96:	00005717          	auipc	a4,0x5
ffffffffc0201e9a:	18a73703          	ld	a4,394(a4) # ffffffffc0207020 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e9e:	88ba                	mv	a7,a4
ffffffffc0201ea0:	852a                	mv	a0,a0
ffffffffc0201ea2:	85be                	mv	a1,a5
ffffffffc0201ea4:	863e                	mv	a2,a5
ffffffffc0201ea6:	00000073          	ecall
ffffffffc0201eaa:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201eac:	8082                	ret

ffffffffc0201eae <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201eae:	4781                	li	a5,0
ffffffffc0201eb0:	00005717          	auipc	a4,0x5
ffffffffc0201eb4:	5e873703          	ld	a4,1512(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc0201eb8:	88ba                	mv	a7,a4
ffffffffc0201eba:	852a                	mv	a0,a0
ffffffffc0201ebc:	85be                	mv	a1,a5
ffffffffc0201ebe:	863e                	mv	a2,a5
ffffffffc0201ec0:	00000073          	ecall
ffffffffc0201ec4:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201ec6:	8082                	ret

ffffffffc0201ec8 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201ec8:	4501                	li	a0,0
ffffffffc0201eca:	00005797          	auipc	a5,0x5
ffffffffc0201ece:	14e7b783          	ld	a5,334(a5) # ffffffffc0207018 <SBI_CONSOLE_GETCHAR>
ffffffffc0201ed2:	88be                	mv	a7,a5
ffffffffc0201ed4:	852a                	mv	a0,a0
ffffffffc0201ed6:	85aa                	mv	a1,a0
ffffffffc0201ed8:	862a                	mv	a2,a0
ffffffffc0201eda:	00000073          	ecall
ffffffffc0201ede:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201ee0:	2501                	sext.w	a0,a0
ffffffffc0201ee2:	8082                	ret

ffffffffc0201ee4 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201ee4:	4781                	li	a5,0
ffffffffc0201ee6:	00005717          	auipc	a4,0x5
ffffffffc0201eea:	12a73703          	ld	a4,298(a4) # ffffffffc0207010 <SBI_SHUTDOWN>
ffffffffc0201eee:	88ba                	mv	a7,a4
ffffffffc0201ef0:	853e                	mv	a0,a5
ffffffffc0201ef2:	85be                	mv	a1,a5
ffffffffc0201ef4:	863e                	mv	a2,a5
ffffffffc0201ef6:	00000073          	ecall
ffffffffc0201efa:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201efc:	8082                	ret

ffffffffc0201efe <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201efe:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201f02:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201f04:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201f06:	cb81                	beqz	a5,ffffffffc0201f16 <strlen+0x18>
        cnt ++;
ffffffffc0201f08:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201f0a:	00a707b3          	add	a5,a4,a0
ffffffffc0201f0e:	0007c783          	lbu	a5,0(a5)
ffffffffc0201f12:	fbfd                	bnez	a5,ffffffffc0201f08 <strlen+0xa>
ffffffffc0201f14:	8082                	ret
    }
    return cnt;
}
ffffffffc0201f16:	8082                	ret

ffffffffc0201f18 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201f18:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f1a:	e589                	bnez	a1,ffffffffc0201f24 <strnlen+0xc>
ffffffffc0201f1c:	a811                	j	ffffffffc0201f30 <strnlen+0x18>
        cnt ++;
ffffffffc0201f1e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f20:	00f58863          	beq	a1,a5,ffffffffc0201f30 <strnlen+0x18>
ffffffffc0201f24:	00f50733          	add	a4,a0,a5
ffffffffc0201f28:	00074703          	lbu	a4,0(a4)
ffffffffc0201f2c:	fb6d                	bnez	a4,ffffffffc0201f1e <strnlen+0x6>
ffffffffc0201f2e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201f30:	852e                	mv	a0,a1
ffffffffc0201f32:	8082                	ret

ffffffffc0201f34 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f34:	00054783          	lbu	a5,0(a0)
ffffffffc0201f38:	e791                	bnez	a5,ffffffffc0201f44 <strcmp+0x10>
ffffffffc0201f3a:	a02d                	j	ffffffffc0201f64 <strcmp+0x30>
ffffffffc0201f3c:	00054783          	lbu	a5,0(a0)
ffffffffc0201f40:	cf89                	beqz	a5,ffffffffc0201f5a <strcmp+0x26>
ffffffffc0201f42:	85b6                	mv	a1,a3
ffffffffc0201f44:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0201f48:	0505                	addi	a0,a0,1
ffffffffc0201f4a:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f4e:	fef707e3          	beq	a4,a5,ffffffffc0201f3c <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f52:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201f56:	9d19                	subw	a0,a0,a4
ffffffffc0201f58:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f5a:	0015c703          	lbu	a4,1(a1)
ffffffffc0201f5e:	4501                	li	a0,0
}
ffffffffc0201f60:	9d19                	subw	a0,a0,a4
ffffffffc0201f62:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f64:	0005c703          	lbu	a4,0(a1)
ffffffffc0201f68:	4501                	li	a0,0
ffffffffc0201f6a:	b7f5                	j	ffffffffc0201f56 <strcmp+0x22>

ffffffffc0201f6c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f6c:	ce01                	beqz	a2,ffffffffc0201f84 <strncmp+0x18>
ffffffffc0201f6e:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201f72:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f74:	cb91                	beqz	a5,ffffffffc0201f88 <strncmp+0x1c>
ffffffffc0201f76:	0005c703          	lbu	a4,0(a1)
ffffffffc0201f7a:	00f71763          	bne	a4,a5,ffffffffc0201f88 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0201f7e:	0505                	addi	a0,a0,1
ffffffffc0201f80:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f82:	f675                	bnez	a2,ffffffffc0201f6e <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f84:	4501                	li	a0,0
ffffffffc0201f86:	8082                	ret
ffffffffc0201f88:	00054503          	lbu	a0,0(a0)
ffffffffc0201f8c:	0005c783          	lbu	a5,0(a1)
ffffffffc0201f90:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201f92:	8082                	ret

ffffffffc0201f94 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201f94:	00054783          	lbu	a5,0(a0)
ffffffffc0201f98:	c799                	beqz	a5,ffffffffc0201fa6 <strchr+0x12>
        if (*s == c) {
ffffffffc0201f9a:	00f58763          	beq	a1,a5,ffffffffc0201fa8 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201f9e:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201fa2:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201fa4:	fbfd                	bnez	a5,ffffffffc0201f9a <strchr+0x6>
    }
    return NULL;
ffffffffc0201fa6:	4501                	li	a0,0
}
ffffffffc0201fa8:	8082                	ret

ffffffffc0201faa <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201faa:	ca01                	beqz	a2,ffffffffc0201fba <memset+0x10>
ffffffffc0201fac:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201fae:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201fb0:	0785                	addi	a5,a5,1
ffffffffc0201fb2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201fb6:	fef61de3          	bne	a2,a5,ffffffffc0201fb0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201fba:	8082                	ret
