
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
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
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49e60613          	addi	a2,a2,1182 # ffffffffc020d4f0 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc0207ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	5b3030ef          	jal	ffffffffc0203e14 <memset>
    dtb_init();
ffffffffc0200066:	502000ef          	jal	ffffffffc0200568 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	48c000ef          	jal	ffffffffc02004f6 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	dfa58593          	addi	a1,a1,-518 # ffffffffc0203e68 <etext+0x6>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	e1250513          	addi	a0,a0,-494 # ffffffffc0203e88 <etext+0x26>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	158000ef          	jal	ffffffffc02001da <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	078020ef          	jal	ffffffffc02020fe <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	067000ef          	jal	ffffffffc02008f0 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	065000ef          	jal	ffffffffc02008f2 <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	5ed020ef          	jal	ffffffffc0202e7e <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	52c030ef          	jal	ffffffffc02035c2 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	40a000ef          	jal	ffffffffc02004a4 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	047000ef          	jal	ffffffffc02008e4 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	76c030ef          	jal	ffffffffc020380e <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a2                	sd	s0,64(sp)
ffffffffc02000ac:	fc26                	sd	s1,56(sp)
ffffffffc02000ae:	f84a                	sd	s2,48(sp)
ffffffffc02000b0:	f44e                	sd	s3,40(sp)
ffffffffc02000b2:	f052                	sd	s4,32(sp)
ffffffffc02000b4:	ec56                	sd	s5,24(sp)
ffffffffc02000b6:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00004517          	auipc	a0,0x4
ffffffffc02000c0:	dd450513          	addi	a0,a0,-556 # ffffffffc0203e90 <etext+0x2e>
ffffffffc02000c4:	0d0000ef          	jal	ffffffffc0200194 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000c8:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4a29                	li	s4,10
ffffffffc02000d0:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc02000d2:	00009b17          	auipc	s6,0x9
ffffffffc02000d6:	f5eb0b13          	addi	s6,s6,-162 # ffffffffc0209030 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc02000de:	0ec000ef          	jal	ffffffffc02001ca <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a4da63          	bge	s1,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	0289d263          	bge	s3,s0,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	0dc000ef          	jal	ffffffffc02001ca <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03251463          	bne	a0,s2,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	04804963          	bgtz	s0,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200102:	0c8000ef          	jal	ffffffffc02001ca <getchar>
        if (c < 0) {
ffffffffc0200106:	fe0548e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020010a:	fea4d8e3          	bge	s1,a0,ffffffffc02000fa <readline+0x54>
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0b8000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	008b07b3          	add	a5,s6,s0
ffffffffc020011a:	2405                	addiw	s0,s0,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01450463          	beq	a0,s4,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb551ce3          	bne	a0,s5,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	09e000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	00009517          	auipc	a0,0x9
ffffffffc0200132:	f0250513          	addi	a0,a0,-254 # ffffffffc0209030 <buf>
ffffffffc0200136:	942a                	add	s0,s0,a0
ffffffffc0200138:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6406                	ld	s0,64(sp)
ffffffffc0200140:	74e2                	ld	s1,56(sp)
ffffffffc0200142:	7942                	ld	s2,48(sp)
ffffffffc0200144:	79a2                	ld	s3,40(sp)
ffffffffc0200146:	7a02                	ld	s4,32(sp)
ffffffffc0200148:	6ae2                	ld	s5,24(sp)
ffffffffc020014a:	6b42                	ld	s6,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	076000ef          	jal	ffffffffc02001c8 <cputchar>
            i --;
ffffffffc0200156:	347d                	addiw	s0,s0,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	396000ef          	jal	ffffffffc02004f8 <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	055030ef          	jal	ffffffffc02039dc <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40
{
ffffffffc020019a:	f42e                	sd	a1,40(sp)
ffffffffc020019c:	f832                	sd	a2,48(sp)
ffffffffc020019e:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a0:	862a                	mv	a2,a0
ffffffffc02001a2:	004c                	addi	a1,sp,4
ffffffffc02001a4:	00000517          	auipc	a0,0x0
ffffffffc02001a8:	fb650513          	addi	a0,a0,-74 # ffffffffc020015a <cputch>
ffffffffc02001ac:	869a                	mv	a3,t1
{
ffffffffc02001ae:	ec06                	sd	ra,24(sp)
ffffffffc02001b0:	e0ba                	sd	a4,64(sp)
ffffffffc02001b2:	e4be                	sd	a5,72(sp)
ffffffffc02001b4:	e8c2                	sd	a6,80(sp)
ffffffffc02001b6:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001b8:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001ba:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001bc:	021030ef          	jal	ffffffffc02039dc <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c0:	60e2                	ld	ra,24(sp)
ffffffffc02001c2:	4512                	lw	a0,4(sp)
ffffffffc02001c4:	6125                	addi	sp,sp,96
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001c8:	ae05                	j	ffffffffc02004f8 <cons_putc>

ffffffffc02001ca <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001ca:	1141                	addi	sp,sp,-16
ffffffffc02001cc:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001ce:	35e000ef          	jal	ffffffffc020052c <cons_getc>
ffffffffc02001d2:	dd75                	beqz	a0,ffffffffc02001ce <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d4:	60a2                	ld	ra,8(sp)
ffffffffc02001d6:	0141                	addi	sp,sp,16
ffffffffc02001d8:	8082                	ret

ffffffffc02001da <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001da:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001dc:	00004517          	auipc	a0,0x4
ffffffffc02001e0:	cbc50513          	addi	a0,a0,-836 # ffffffffc0203e98 <etext+0x36>
{
ffffffffc02001e4:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e6:	fafff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ea:	00000597          	auipc	a1,0x0
ffffffffc02001ee:	e6058593          	addi	a1,a1,-416 # ffffffffc020004a <kern_init>
ffffffffc02001f2:	00004517          	auipc	a0,0x4
ffffffffc02001f6:	cc650513          	addi	a0,a0,-826 # ffffffffc0203eb8 <etext+0x56>
ffffffffc02001fa:	f9bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02001fe:	00004597          	auipc	a1,0x4
ffffffffc0200202:	c6458593          	addi	a1,a1,-924 # ffffffffc0203e62 <etext>
ffffffffc0200206:	00004517          	auipc	a0,0x4
ffffffffc020020a:	cd250513          	addi	a0,a0,-814 # ffffffffc0203ed8 <etext+0x76>
ffffffffc020020e:	f87ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200212:	00009597          	auipc	a1,0x9
ffffffffc0200216:	e1e58593          	addi	a1,a1,-482 # ffffffffc0209030 <buf>
ffffffffc020021a:	00004517          	auipc	a0,0x4
ffffffffc020021e:	cde50513          	addi	a0,a0,-802 # ffffffffc0203ef8 <etext+0x96>
ffffffffc0200222:	f73ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200226:	0000d597          	auipc	a1,0xd
ffffffffc020022a:	2ca58593          	addi	a1,a1,714 # ffffffffc020d4f0 <end>
ffffffffc020022e:	00004517          	auipc	a0,0x4
ffffffffc0200232:	cea50513          	addi	a0,a0,-790 # ffffffffc0203f18 <etext+0xb6>
ffffffffc0200236:	f5fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023a:	0000d797          	auipc	a5,0xd
ffffffffc020023e:	6b578793          	addi	a5,a5,1717 # ffffffffc020d8ef <end+0x3ff>
ffffffffc0200242:	00000717          	auipc	a4,0x0
ffffffffc0200246:	e0870713          	addi	a4,a4,-504 # ffffffffc020004a <kern_init>
ffffffffc020024a:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020024c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200250:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200252:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200256:	95be                	add	a1,a1,a5
ffffffffc0200258:	85a9                	srai	a1,a1,0xa
ffffffffc020025a:	00004517          	auipc	a0,0x4
ffffffffc020025e:	cde50513          	addi	a0,a0,-802 # ffffffffc0203f38 <etext+0xd6>
}
ffffffffc0200262:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200264:	bf05                	j	ffffffffc0200194 <cprintf>

ffffffffc0200266 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc0200266:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200268:	00004617          	auipc	a2,0x4
ffffffffc020026c:	d0060613          	addi	a2,a2,-768 # ffffffffc0203f68 <etext+0x106>
ffffffffc0200270:	04900593          	li	a1,73
ffffffffc0200274:	00004517          	auipc	a0,0x4
ffffffffc0200278:	d0c50513          	addi	a0,a0,-756 # ffffffffc0203f80 <etext+0x11e>
{
ffffffffc020027c:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020027e:	1c8000ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0200282 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200282:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200284:	00004617          	auipc	a2,0x4
ffffffffc0200288:	d1460613          	addi	a2,a2,-748 # ffffffffc0203f98 <etext+0x136>
ffffffffc020028c:	00004597          	auipc	a1,0x4
ffffffffc0200290:	d2c58593          	addi	a1,a1,-724 # ffffffffc0203fb8 <etext+0x156>
ffffffffc0200294:	00004517          	auipc	a0,0x4
ffffffffc0200298:	d2c50513          	addi	a0,a0,-724 # ffffffffc0203fc0 <etext+0x15e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020029c:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020029e:	ef7ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc02002a2:	00004617          	auipc	a2,0x4
ffffffffc02002a6:	d2e60613          	addi	a2,a2,-722 # ffffffffc0203fd0 <etext+0x16e>
ffffffffc02002aa:	00004597          	auipc	a1,0x4
ffffffffc02002ae:	d4e58593          	addi	a1,a1,-690 # ffffffffc0203ff8 <etext+0x196>
ffffffffc02002b2:	00004517          	auipc	a0,0x4
ffffffffc02002b6:	d0e50513          	addi	a0,a0,-754 # ffffffffc0203fc0 <etext+0x15e>
ffffffffc02002ba:	edbff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc02002be:	00004617          	auipc	a2,0x4
ffffffffc02002c2:	d4a60613          	addi	a2,a2,-694 # ffffffffc0204008 <etext+0x1a6>
ffffffffc02002c6:	00004597          	auipc	a1,0x4
ffffffffc02002ca:	d6258593          	addi	a1,a1,-670 # ffffffffc0204028 <etext+0x1c6>
ffffffffc02002ce:	00004517          	auipc	a0,0x4
ffffffffc02002d2:	cf250513          	addi	a0,a0,-782 # ffffffffc0203fc0 <etext+0x15e>
ffffffffc02002d6:	ebfff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc02002da:	60a2                	ld	ra,8(sp)
ffffffffc02002dc:	4501                	li	a0,0
ffffffffc02002de:	0141                	addi	sp,sp,16
ffffffffc02002e0:	8082                	ret

ffffffffc02002e2 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e2:	1141                	addi	sp,sp,-16
ffffffffc02002e4:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002e6:	ef5ff0ef          	jal	ffffffffc02001da <print_kerninfo>
    return 0;
}
ffffffffc02002ea:	60a2                	ld	ra,8(sp)
ffffffffc02002ec:	4501                	li	a0,0
ffffffffc02002ee:	0141                	addi	sp,sp,16
ffffffffc02002f0:	8082                	ret

ffffffffc02002f2 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002f2:	1141                	addi	sp,sp,-16
ffffffffc02002f4:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002f6:	f71ff0ef          	jal	ffffffffc0200266 <print_stackframe>
    return 0;
}
ffffffffc02002fa:	60a2                	ld	ra,8(sp)
ffffffffc02002fc:	4501                	li	a0,0
ffffffffc02002fe:	0141                	addi	sp,sp,16
ffffffffc0200300:	8082                	ret

ffffffffc0200302 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200302:	7115                	addi	sp,sp,-224
ffffffffc0200304:	f15a                	sd	s6,160(sp)
ffffffffc0200306:	8b2a                	mv	s6,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200308:	00004517          	auipc	a0,0x4
ffffffffc020030c:	d3050513          	addi	a0,a0,-720 # ffffffffc0204038 <etext+0x1d6>
kmonitor(struct trapframe *tf) {
ffffffffc0200310:	ed86                	sd	ra,216(sp)
ffffffffc0200312:	e9a2                	sd	s0,208(sp)
ffffffffc0200314:	e5a6                	sd	s1,200(sp)
ffffffffc0200316:	e1ca                	sd	s2,192(sp)
ffffffffc0200318:	fd4e                	sd	s3,184(sp)
ffffffffc020031a:	f952                	sd	s4,176(sp)
ffffffffc020031c:	f556                	sd	s5,168(sp)
ffffffffc020031e:	ed5e                	sd	s7,152(sp)
ffffffffc0200320:	e962                	sd	s8,144(sp)
ffffffffc0200322:	e566                	sd	s9,136(sp)
ffffffffc0200324:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200326:	e6fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020032a:	00004517          	auipc	a0,0x4
ffffffffc020032e:	d3650513          	addi	a0,a0,-714 # ffffffffc0204060 <etext+0x1fe>
ffffffffc0200332:	e63ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc0200336:	000b0563          	beqz	s6,ffffffffc0200340 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020033a:	855a                	mv	a0,s6
ffffffffc020033c:	79e000ef          	jal	ffffffffc0200ada <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	4581                	li	a1,0
ffffffffc0200344:	4601                	li	a2,0
ffffffffc0200346:	48a1                	li	a7,8
ffffffffc0200348:	00000073          	ecall
ffffffffc020034c:	00005c17          	auipc	s8,0x5
ffffffffc0200350:	3ecc0c13          	addi	s8,s8,1004 # ffffffffc0205738 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200354:	00004917          	auipc	s2,0x4
ffffffffc0200358:	d3490913          	addi	s2,s2,-716 # ffffffffc0204088 <etext+0x226>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020035c:	00004497          	auipc	s1,0x4
ffffffffc0200360:	d3448493          	addi	s1,s1,-716 # ffffffffc0204090 <etext+0x22e>
        if (argc == MAXARGS - 1) {
ffffffffc0200364:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200366:	00004a97          	auipc	s5,0x4
ffffffffc020036a:	d32a8a93          	addi	s5,s5,-718 # ffffffffc0204098 <etext+0x236>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020036e:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200370:	00004b97          	auipc	s7,0x4
ffffffffc0200374:	d48b8b93          	addi	s7,s7,-696 # ffffffffc02040b8 <etext+0x256>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200378:	854a                	mv	a0,s2
ffffffffc020037a:	d2dff0ef          	jal	ffffffffc02000a6 <readline>
ffffffffc020037e:	842a                	mv	s0,a0
ffffffffc0200380:	dd65                	beqz	a0,ffffffffc0200378 <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200382:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200386:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200388:	e59d                	bnez	a1,ffffffffc02003b6 <kmonitor+0xb4>
    if (argc == 0) {
ffffffffc020038a:	fe0c87e3          	beqz	s9,ffffffffc0200378 <kmonitor+0x76>
ffffffffc020038e:	00005d17          	auipc	s10,0x5
ffffffffc0200392:	3aad0d13          	addi	s10,s10,938 # ffffffffc0205738 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200396:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200398:	6582                	ld	a1,0(sp)
ffffffffc020039a:	000d3503          	ld	a0,0(s10)
ffffffffc020039e:	201030ef          	jal	ffffffffc0203d9e <strcmp>
ffffffffc02003a2:	c53d                	beqz	a0,ffffffffc0200410 <kmonitor+0x10e>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003a4:	2405                	addiw	s0,s0,1
ffffffffc02003a6:	0d61                	addi	s10,s10,24
ffffffffc02003a8:	ff4418e3          	bne	s0,s4,ffffffffc0200398 <kmonitor+0x96>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003ac:	6582                	ld	a1,0(sp)
ffffffffc02003ae:	855e                	mv	a0,s7
ffffffffc02003b0:	de5ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc02003b4:	b7d1                	j	ffffffffc0200378 <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b6:	8526                	mv	a0,s1
ffffffffc02003b8:	247030ef          	jal	ffffffffc0203dfe <strchr>
ffffffffc02003bc:	c901                	beqz	a0,ffffffffc02003cc <kmonitor+0xca>
ffffffffc02003be:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003c2:	00040023          	sb	zero,0(s0)
ffffffffc02003c6:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c8:	d1e9                	beqz	a1,ffffffffc020038a <kmonitor+0x88>
ffffffffc02003ca:	b7f5                	j	ffffffffc02003b6 <kmonitor+0xb4>
        if (*buf == '\0') {
ffffffffc02003cc:	00044783          	lbu	a5,0(s0)
ffffffffc02003d0:	dfcd                	beqz	a5,ffffffffc020038a <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc02003d2:	033c8a63          	beq	s9,s3,ffffffffc0200406 <kmonitor+0x104>
        argv[argc ++] = buf;
ffffffffc02003d6:	003c9793          	slli	a5,s9,0x3
ffffffffc02003da:	08078793          	addi	a5,a5,128
ffffffffc02003de:	978a                	add	a5,a5,sp
ffffffffc02003e0:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003e4:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003e8:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003ea:	e591                	bnez	a1,ffffffffc02003f6 <kmonitor+0xf4>
ffffffffc02003ec:	bf79                	j	ffffffffc020038a <kmonitor+0x88>
ffffffffc02003ee:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003f2:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003f4:	d9d9                	beqz	a1,ffffffffc020038a <kmonitor+0x88>
ffffffffc02003f6:	8526                	mv	a0,s1
ffffffffc02003f8:	207030ef          	jal	ffffffffc0203dfe <strchr>
ffffffffc02003fc:	d96d                	beqz	a0,ffffffffc02003ee <kmonitor+0xec>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003fe:	00044583          	lbu	a1,0(s0)
ffffffffc0200402:	d5c1                	beqz	a1,ffffffffc020038a <kmonitor+0x88>
ffffffffc0200404:	bf4d                	j	ffffffffc02003b6 <kmonitor+0xb4>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200406:	45c1                	li	a1,16
ffffffffc0200408:	8556                	mv	a0,s5
ffffffffc020040a:	d8bff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc020040e:	b7e1                	j	ffffffffc02003d6 <kmonitor+0xd4>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200410:	00141793          	slli	a5,s0,0x1
ffffffffc0200414:	97a2                	add	a5,a5,s0
ffffffffc0200416:	078e                	slli	a5,a5,0x3
ffffffffc0200418:	97e2                	add	a5,a5,s8
ffffffffc020041a:	6b9c                	ld	a5,16(a5)
ffffffffc020041c:	865a                	mv	a2,s6
ffffffffc020041e:	002c                	addi	a1,sp,8
ffffffffc0200420:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200424:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200426:	f40559e3          	bgez	a0,ffffffffc0200378 <kmonitor+0x76>
}
ffffffffc020042a:	60ee                	ld	ra,216(sp)
ffffffffc020042c:	644e                	ld	s0,208(sp)
ffffffffc020042e:	64ae                	ld	s1,200(sp)
ffffffffc0200430:	690e                	ld	s2,192(sp)
ffffffffc0200432:	79ea                	ld	s3,184(sp)
ffffffffc0200434:	7a4a                	ld	s4,176(sp)
ffffffffc0200436:	7aaa                	ld	s5,168(sp)
ffffffffc0200438:	7b0a                	ld	s6,160(sp)
ffffffffc020043a:	6bea                	ld	s7,152(sp)
ffffffffc020043c:	6c4a                	ld	s8,144(sp)
ffffffffc020043e:	6caa                	ld	s9,136(sp)
ffffffffc0200440:	6d0a                	ld	s10,128(sp)
ffffffffc0200442:	612d                	addi	sp,sp,224
ffffffffc0200444:	8082                	ret

ffffffffc0200446 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200446:	0000d317          	auipc	t1,0xd
ffffffffc020044a:	02230313          	addi	t1,t1,34 # ffffffffc020d468 <is_panic>
ffffffffc020044e:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200452:	715d                	addi	sp,sp,-80
ffffffffc0200454:	ec06                	sd	ra,24(sp)
ffffffffc0200456:	f436                	sd	a3,40(sp)
ffffffffc0200458:	f83a                	sd	a4,48(sp)
ffffffffc020045a:	fc3e                	sd	a5,56(sp)
ffffffffc020045c:	e0c2                	sd	a6,64(sp)
ffffffffc020045e:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200460:	020e1c63          	bnez	t3,ffffffffc0200498 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200464:	4785                	li	a5,1
ffffffffc0200466:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc020046a:	e822                	sd	s0,16(sp)
ffffffffc020046c:	103c                	addi	a5,sp,40
ffffffffc020046e:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200470:	862e                	mv	a2,a1
ffffffffc0200472:	85aa                	mv	a1,a0
ffffffffc0200474:	00004517          	auipc	a0,0x4
ffffffffc0200478:	c5c50513          	addi	a0,a0,-932 # ffffffffc02040d0 <etext+0x26e>
    va_start(ap, fmt);
ffffffffc020047c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020047e:	d17ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200482:	65a2                	ld	a1,8(sp)
ffffffffc0200484:	8522                	mv	a0,s0
ffffffffc0200486:	cefff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020048a:	00004517          	auipc	a0,0x4
ffffffffc020048e:	c6650513          	addi	a0,a0,-922 # ffffffffc02040f0 <etext+0x28e>
ffffffffc0200492:	d03ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200496:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200498:	452000ef          	jal	ffffffffc02008ea <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020049c:	4501                	li	a0,0
ffffffffc020049e:	e65ff0ef          	jal	ffffffffc0200302 <kmonitor>
    while (1) {
ffffffffc02004a2:	bfed                	j	ffffffffc020049c <__panic+0x56>

ffffffffc02004a4 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004a4:	67e1                	lui	a5,0x18
ffffffffc02004a6:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004aa:	0000d717          	auipc	a4,0xd
ffffffffc02004ae:	fcf73323          	sd	a5,-58(a4) # ffffffffc020d470 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004b2:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02004b6:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004b8:	953e                	add	a0,a0,a5
ffffffffc02004ba:	4601                	li	a2,0
ffffffffc02004bc:	4881                	li	a7,0
ffffffffc02004be:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02004c2:	02000793          	li	a5,32
ffffffffc02004c6:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02004ca:	00004517          	auipc	a0,0x4
ffffffffc02004ce:	c2e50513          	addi	a0,a0,-978 # ffffffffc02040f8 <etext+0x296>
    ticks = 0;
ffffffffc02004d2:	0000d797          	auipc	a5,0xd
ffffffffc02004d6:	fa07b323          	sd	zero,-90(a5) # ffffffffc020d478 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02004da:	b96d                	j	ffffffffc0200194 <cprintf>

ffffffffc02004dc <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004dc:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004e0:	0000d797          	auipc	a5,0xd
ffffffffc02004e4:	f907b783          	ld	a5,-112(a5) # ffffffffc020d470 <timebase>
ffffffffc02004e8:	953e                	add	a0,a0,a5
ffffffffc02004ea:	4581                	li	a1,0
ffffffffc02004ec:	4601                	li	a2,0
ffffffffc02004ee:	4881                	li	a7,0
ffffffffc02004f0:	00000073          	ecall
ffffffffc02004f4:	8082                	ret

ffffffffc02004f6 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02004f6:	8082                	ret

ffffffffc02004f8 <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004f8:	100027f3          	csrr	a5,sstatus
ffffffffc02004fc:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02004fe:	0ff57513          	zext.b	a0,a0
ffffffffc0200502:	e799                	bnez	a5,ffffffffc0200510 <cons_putc+0x18>
ffffffffc0200504:	4581                	li	a1,0
ffffffffc0200506:	4601                	li	a2,0
ffffffffc0200508:	4885                	li	a7,1
ffffffffc020050a:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc020050e:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200510:	1101                	addi	sp,sp,-32
ffffffffc0200512:	ec06                	sd	ra,24(sp)
ffffffffc0200514:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200516:	3d4000ef          	jal	ffffffffc02008ea <intr_disable>
ffffffffc020051a:	6522                	ld	a0,8(sp)
ffffffffc020051c:	4581                	li	a1,0
ffffffffc020051e:	4601                	li	a2,0
ffffffffc0200520:	4885                	li	a7,1
ffffffffc0200522:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200526:	60e2                	ld	ra,24(sp)
ffffffffc0200528:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020052a:	ae6d                	j	ffffffffc02008e4 <intr_enable>

ffffffffc020052c <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020052c:	100027f3          	csrr	a5,sstatus
ffffffffc0200530:	8b89                	andi	a5,a5,2
ffffffffc0200532:	eb89                	bnez	a5,ffffffffc0200544 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200534:	4501                	li	a0,0
ffffffffc0200536:	4581                	li	a1,0
ffffffffc0200538:	4601                	li	a2,0
ffffffffc020053a:	4889                	li	a7,2
ffffffffc020053c:	00000073          	ecall
ffffffffc0200540:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200542:	8082                	ret
int cons_getc(void) {
ffffffffc0200544:	1101                	addi	sp,sp,-32
ffffffffc0200546:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200548:	3a2000ef          	jal	ffffffffc02008ea <intr_disable>
ffffffffc020054c:	4501                	li	a0,0
ffffffffc020054e:	4581                	li	a1,0
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4889                	li	a7,2
ffffffffc0200554:	00000073          	ecall
ffffffffc0200558:	2501                	sext.w	a0,a0
ffffffffc020055a:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020055c:	388000ef          	jal	ffffffffc02008e4 <intr_enable>
}
ffffffffc0200560:	60e2                	ld	ra,24(sp)
ffffffffc0200562:	6522                	ld	a0,8(sp)
ffffffffc0200564:	6105                	addi	sp,sp,32
ffffffffc0200566:	8082                	ret

ffffffffc0200568 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200568:	711d                	addi	sp,sp,-96
    cprintf("DTB Init\n");
ffffffffc020056a:	00004517          	auipc	a0,0x4
ffffffffc020056e:	bae50513          	addi	a0,a0,-1106 # ffffffffc0204118 <etext+0x2b6>
void dtb_init(void) {
ffffffffc0200572:	ec86                	sd	ra,88(sp)
ffffffffc0200574:	e8a2                	sd	s0,80(sp)
    cprintf("DTB Init\n");
ffffffffc0200576:	c1fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020057a:	00009597          	auipc	a1,0x9
ffffffffc020057e:	a865b583          	ld	a1,-1402(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc0200582:	00004517          	auipc	a0,0x4
ffffffffc0200586:	ba650513          	addi	a0,a0,-1114 # ffffffffc0204128 <etext+0x2c6>
ffffffffc020058a:	c0bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020058e:	00009417          	auipc	s0,0x9
ffffffffc0200592:	a7a40413          	addi	s0,s0,-1414 # ffffffffc0209008 <boot_dtb>
ffffffffc0200596:	600c                	ld	a1,0(s0)
ffffffffc0200598:	00004517          	auipc	a0,0x4
ffffffffc020059c:	ba050513          	addi	a0,a0,-1120 # ffffffffc0204138 <etext+0x2d6>
ffffffffc02005a0:	bf5ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005a4:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005a6:	00004517          	auipc	a0,0x4
ffffffffc02005aa:	baa50513          	addi	a0,a0,-1110 # ffffffffc0204150 <etext+0x2ee>
    if (boot_dtb == 0) {
ffffffffc02005ae:	12070d63          	beqz	a4,ffffffffc02006e8 <dtb_init+0x180>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02005b2:	57f5                	li	a5,-3
ffffffffc02005b4:	07fa                	slli	a5,a5,0x1e
ffffffffc02005b6:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02005b8:	431c                	lw	a5,0(a4)
ffffffffc02005ba:	f456                	sd	s5,40(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005bc:	00ff0637          	lui	a2,0xff0
ffffffffc02005c0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02005c4:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005c8:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005cc:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005d0:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02005d4:	6ac1                	lui	s5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005d6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005d8:	8ec9                	or	a3,a3,a0
ffffffffc02005da:	0087979b          	slliw	a5,a5,0x8
ffffffffc02005de:	1afd                	addi	s5,s5,-1 # ffff <kern_entry-0xffffffffc01f0001>
ffffffffc02005e0:	0157f7b3          	and	a5,a5,s5
ffffffffc02005e4:	8dd5                	or	a1,a1,a3
ffffffffc02005e6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02005e8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ec:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02005ee:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed29fd>
ffffffffc02005f2:	0ef59f63          	bne	a1,a5,ffffffffc02006f0 <dtb_init+0x188>
ffffffffc02005f6:	471c                	lw	a5,8(a4)
ffffffffc02005f8:	4754                	lw	a3,12(a4)
ffffffffc02005fa:	fc4e                	sd	s3,56(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005fc:	0087d99b          	srliw	s3,a5,0x8
ffffffffc0200600:	0086d41b          	srliw	s0,a3,0x8
ffffffffc0200604:	0186951b          	slliw	a0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200608:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020060c:	0187959b          	slliw	a1,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200610:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200614:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200618:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020061c:	0109999b          	slliw	s3,s3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200620:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200624:	8c71                	and	s0,s0,a2
ffffffffc0200626:	00c9f9b3          	and	s3,s3,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020062a:	01156533          	or	a0,a0,a7
ffffffffc020062e:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200632:	0105e633          	or	a2,a1,a6
ffffffffc0200636:	0087979b          	slliw	a5,a5,0x8
ffffffffc020063a:	8c49                	or	s0,s0,a0
ffffffffc020063c:	0156f6b3          	and	a3,a3,s5
ffffffffc0200640:	00c9e9b3          	or	s3,s3,a2
ffffffffc0200644:	0157f7b3          	and	a5,a5,s5
ffffffffc0200648:	8c55                	or	s0,s0,a3
ffffffffc020064a:	00f9e9b3          	or	s3,s3,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020064e:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200650:	1982                	slli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200652:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200654:	0209d993          	srli	s3,s3,0x20
ffffffffc0200658:	e4a6                	sd	s1,72(sp)
ffffffffc020065a:	e0ca                	sd	s2,64(sp)
ffffffffc020065c:	ec5e                	sd	s7,24(sp)
ffffffffc020065e:	e862                	sd	s8,16(sp)
ffffffffc0200660:	e466                	sd	s9,8(sp)
ffffffffc0200662:	e06a                	sd	s10,0(sp)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200664:	f852                	sd	s4,48(sp)
    int in_memory_node = 0;
ffffffffc0200666:	4b81                	li	s7,0
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200668:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020066a:	99ba                	add	s3,s3,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066c:	00ff0cb7          	lui	s9,0xff0
        switch (token) {
ffffffffc0200670:	4c0d                	li	s8,3
ffffffffc0200672:	4911                	li	s2,4
ffffffffc0200674:	4d05                	li	s10,1
ffffffffc0200676:	4489                	li	s1,2
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200678:	0009a703          	lw	a4,0(s3)
ffffffffc020067c:	00498a13          	addi	s4,s3,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200680:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200684:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200688:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068c:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200690:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200694:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200696:	0196f6b3          	and	a3,a3,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	0087171b          	slliw	a4,a4,0x8
ffffffffc020069e:	8fd5                	or	a5,a5,a3
ffffffffc02006a0:	00eaf733          	and	a4,s5,a4
ffffffffc02006a4:	8fd9                	or	a5,a5,a4
ffffffffc02006a6:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02006a8:	09878263          	beq	a5,s8,ffffffffc020072c <dtb_init+0x1c4>
ffffffffc02006ac:	00fc6963          	bltu	s8,a5,ffffffffc02006be <dtb_init+0x156>
ffffffffc02006b0:	05a78963          	beq	a5,s10,ffffffffc0200702 <dtb_init+0x19a>
ffffffffc02006b4:	00979763          	bne	a5,s1,ffffffffc02006c2 <dtb_init+0x15a>
ffffffffc02006b8:	4b81                	li	s7,0
ffffffffc02006ba:	89d2                	mv	s3,s4
ffffffffc02006bc:	bf75                	j	ffffffffc0200678 <dtb_init+0x110>
ffffffffc02006be:	ff278ee3          	beq	a5,s2,ffffffffc02006ba <dtb_init+0x152>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006c2:	00004517          	auipc	a0,0x4
ffffffffc02006c6:	b5650513          	addi	a0,a0,-1194 # ffffffffc0204218 <etext+0x3b6>
ffffffffc02006ca:	acbff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006ce:	64a6                	ld	s1,72(sp)
ffffffffc02006d0:	6906                	ld	s2,64(sp)
ffffffffc02006d2:	79e2                	ld	s3,56(sp)
ffffffffc02006d4:	7a42                	ld	s4,48(sp)
ffffffffc02006d6:	7aa2                	ld	s5,40(sp)
ffffffffc02006d8:	6be2                	ld	s7,24(sp)
ffffffffc02006da:	6c42                	ld	s8,16(sp)
ffffffffc02006dc:	6ca2                	ld	s9,8(sp)
ffffffffc02006de:	6d02                	ld	s10,0(sp)
ffffffffc02006e0:	00004517          	auipc	a0,0x4
ffffffffc02006e4:	b7050513          	addi	a0,a0,-1168 # ffffffffc0204250 <etext+0x3ee>
}
ffffffffc02006e8:	6446                	ld	s0,80(sp)
ffffffffc02006ea:	60e6                	ld	ra,88(sp)
ffffffffc02006ec:	6125                	addi	sp,sp,96
    cprintf("DTB init completed\n");
ffffffffc02006ee:	b45d                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02006f0:	6446                	ld	s0,80(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02006f2:	7aa2                	ld	s5,40(sp)
}
ffffffffc02006f4:	60e6                	ld	ra,88(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02006f6:	00004517          	auipc	a0,0x4
ffffffffc02006fa:	a7a50513          	addi	a0,a0,-1414 # ffffffffc0204170 <etext+0x30e>
}
ffffffffc02006fe:	6125                	addi	sp,sp,96
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200700:	bc51                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc0200702:	8552                	mv	a0,s4
ffffffffc0200704:	652030ef          	jal	ffffffffc0203d56 <strlen>
ffffffffc0200708:	89aa                	mv	s3,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020070a:	4619                	li	a2,6
ffffffffc020070c:	00004597          	auipc	a1,0x4
ffffffffc0200710:	a8c58593          	addi	a1,a1,-1396 # ffffffffc0204198 <etext+0x336>
ffffffffc0200714:	8552                	mv	a0,s4
                int name_len = strlen(name);
ffffffffc0200716:	2981                	sext.w	s3,s3
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200718:	6be030ef          	jal	ffffffffc0203dd6 <strncmp>
ffffffffc020071c:	e111                	bnez	a0,ffffffffc0200720 <dtb_init+0x1b8>
                    in_memory_node = 1;
ffffffffc020071e:	4b85                	li	s7,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200720:	0a11                	addi	s4,s4,4
ffffffffc0200722:	9a4e                	add	s4,s4,s3
ffffffffc0200724:	ffca7a13          	andi	s4,s4,-4
        switch (token) {
ffffffffc0200728:	89d2                	mv	s3,s4
ffffffffc020072a:	b7b9                	j	ffffffffc0200678 <dtb_init+0x110>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020072c:	0049a783          	lw	a5,4(s3)
ffffffffc0200730:	f05a                	sd	s6,32(sp)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200732:	0089a683          	lw	a3,8(s3)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200736:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020073a:	01879b1b          	slliw	s6,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020074a:	00cb6b33          	or	s6,s6,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074e:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200752:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200756:	00eb6b33          	or	s6,s6,a4
ffffffffc020075a:	00faf7b3          	and	a5,s5,a5
ffffffffc020075e:	00fb6b33          	or	s6,s6,a5
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200762:	00c98a13          	addi	s4,s3,12
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200766:	2b01                	sext.w	s6,s6
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200768:	000b9c63          	bnez	s7,ffffffffc0200780 <dtb_init+0x218>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020076c:	1b02                	slli	s6,s6,0x20
ffffffffc020076e:	020b5b13          	srli	s6,s6,0x20
ffffffffc0200772:	0a0d                	addi	s4,s4,3
ffffffffc0200774:	9a5a                	add	s4,s4,s6
ffffffffc0200776:	ffca7a13          	andi	s4,s4,-4
                break;
ffffffffc020077a:	7b02                	ld	s6,32(sp)
        switch (token) {
ffffffffc020077c:	89d2                	mv	s3,s4
ffffffffc020077e:	bded                	j	ffffffffc0200678 <dtb_init+0x110>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200780:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200784:	0186979b          	slliw	a5,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200788:	0186d71b          	srliw	a4,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020078c:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200790:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200794:	01957533          	and	a0,a0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200798:	8fd9                	or	a5,a5,a4
ffffffffc020079a:	0086969b          	slliw	a3,a3,0x8
ffffffffc020079e:	8d5d                	or	a0,a0,a5
ffffffffc02007a0:	00daf6b3          	and	a3,s5,a3
ffffffffc02007a4:	8d55                	or	a0,a0,a3
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007a6:	1502                	slli	a0,a0,0x20
ffffffffc02007a8:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007aa:	00004597          	auipc	a1,0x4
ffffffffc02007ae:	9f658593          	addi	a1,a1,-1546 # ffffffffc02041a0 <etext+0x33e>
ffffffffc02007b2:	9522                	add	a0,a0,s0
ffffffffc02007b4:	5ea030ef          	jal	ffffffffc0203d9e <strcmp>
ffffffffc02007b8:	f955                	bnez	a0,ffffffffc020076c <dtb_init+0x204>
ffffffffc02007ba:	47bd                	li	a5,15
ffffffffc02007bc:	fb67f8e3          	bgeu	a5,s6,ffffffffc020076c <dtb_init+0x204>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007c0:	00c9b783          	ld	a5,12(s3)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007c4:	0149b703          	ld	a4,20(s3)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007c8:	00004517          	auipc	a0,0x4
ffffffffc02007cc:	9e050513          	addi	a0,a0,-1568 # ffffffffc02041a8 <etext+0x346>
           fdt32_to_cpu(x >> 32);
ffffffffc02007d0:	4207d693          	srai	a3,a5,0x20
ffffffffc02007d4:	42075813          	srai	a6,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d8:	0187d39b          	srliw	t2,a5,0x18
ffffffffc02007dc:	0186d29b          	srliw	t0,a3,0x18
ffffffffc02007e0:	01875f9b          	srliw	t6,a4,0x18
ffffffffc02007e4:	01885f1b          	srliw	t5,a6,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007e8:	0087d49b          	srliw	s1,a5,0x8
ffffffffc02007ec:	0087541b          	srliw	s0,a4,0x8
ffffffffc02007f0:	01879e9b          	slliw	t4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f4:	0107d59b          	srliw	a1,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f8:	01869e1b          	slliw	t3,a3,0x18
ffffffffc02007fc:	0187131b          	slliw	t1,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200800:	0107561b          	srliw	a2,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200804:	0188189b          	slliw	a7,a6,0x18
ffffffffc0200808:	83e1                	srli	a5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080a:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080e:	8361                	srli	a4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0108581b          	srliw	a6,a6,0x10
ffffffffc0200814:	005e6e33          	or	t3,t3,t0
ffffffffc0200818:	01e8e8b3          	or	a7,a7,t5
ffffffffc020081c:	0088181b          	slliw	a6,a6,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200820:	0104949b          	slliw	s1,s1,0x10
ffffffffc0200824:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200828:	0085959b          	slliw	a1,a1,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020082c:	0197f7b3          	and	a5,a5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200830:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200834:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200838:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020083c:	00daf6b3          	and	a3,s5,a3
ffffffffc0200840:	007eeeb3          	or	t4,t4,t2
ffffffffc0200844:	01f36333          	or	t1,t1,t6
ffffffffc0200848:	01c7e7b3          	or	a5,a5,t3
ffffffffc020084c:	00caf633          	and	a2,s5,a2
ffffffffc0200850:	01176733          	or	a4,a4,a7
ffffffffc0200854:	00baf5b3          	and	a1,s5,a1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	0194f4b3          	and	s1,s1,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	010afab3          	and	s5,s5,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200860:	01947433          	and	s0,s0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200864:	01d4e4b3          	or	s1,s1,t4
ffffffffc0200868:	00646433          	or	s0,s0,t1
ffffffffc020086c:	8fd5                	or	a5,a5,a3
ffffffffc020086e:	01576733          	or	a4,a4,s5
ffffffffc0200872:	8c51                	or	s0,s0,a2
ffffffffc0200874:	8ccd                	or	s1,s1,a1
           fdt32_to_cpu(x >> 32);
ffffffffc0200876:	1782                	slli	a5,a5,0x20
ffffffffc0200878:	1702                	slli	a4,a4,0x20
ffffffffc020087a:	9381                	srli	a5,a5,0x20
ffffffffc020087c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020087e:	1482                	slli	s1,s1,0x20
ffffffffc0200880:	1402                	slli	s0,s0,0x20
ffffffffc0200882:	8cdd                	or	s1,s1,a5
ffffffffc0200884:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200886:	90fff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020088a:	85a6                	mv	a1,s1
ffffffffc020088c:	00004517          	auipc	a0,0x4
ffffffffc0200890:	93c50513          	addi	a0,a0,-1732 # ffffffffc02041c8 <etext+0x366>
ffffffffc0200894:	901ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200898:	01445613          	srli	a2,s0,0x14
ffffffffc020089c:	85a2                	mv	a1,s0
ffffffffc020089e:	00004517          	auipc	a0,0x4
ffffffffc02008a2:	94250513          	addi	a0,a0,-1726 # ffffffffc02041e0 <etext+0x37e>
ffffffffc02008a6:	8efff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008aa:	009405b3          	add	a1,s0,s1
ffffffffc02008ae:	15fd                	addi	a1,a1,-1
ffffffffc02008b0:	00004517          	auipc	a0,0x4
ffffffffc02008b4:	95050513          	addi	a0,a0,-1712 # ffffffffc0204200 <etext+0x39e>
ffffffffc02008b8:	8ddff0ef          	jal	ffffffffc0200194 <cprintf>
        memory_base = mem_base;
ffffffffc02008bc:	7b02                	ld	s6,32(sp)
ffffffffc02008be:	0000d797          	auipc	a5,0xd
ffffffffc02008c2:	bc97b523          	sd	s1,-1078(a5) # ffffffffc020d488 <memory_base>
        memory_size = mem_size;
ffffffffc02008c6:	0000d797          	auipc	a5,0xd
ffffffffc02008ca:	ba87bd23          	sd	s0,-1094(a5) # ffffffffc020d480 <memory_size>
ffffffffc02008ce:	b501                	j	ffffffffc02006ce <dtb_init+0x166>

ffffffffc02008d0 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02008d0:	0000d517          	auipc	a0,0xd
ffffffffc02008d4:	bb853503          	ld	a0,-1096(a0) # ffffffffc020d488 <memory_base>
ffffffffc02008d8:	8082                	ret

ffffffffc02008da <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02008da:	0000d517          	auipc	a0,0xd
ffffffffc02008de:	ba653503          	ld	a0,-1114(a0) # ffffffffc020d480 <memory_size>
ffffffffc02008e2:	8082                	ret

ffffffffc02008e4 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008e4:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02008e8:	8082                	ret

ffffffffc02008ea <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008ea:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02008ee:	8082                	ret

ffffffffc02008f0 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02008f0:	8082                	ret

ffffffffc02008f2 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02008f2:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02008f6:	00000797          	auipc	a5,0x0
ffffffffc02008fa:	3e678793          	addi	a5,a5,998 # ffffffffc0200cdc <__alltraps>
ffffffffc02008fe:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200902:	000407b7          	lui	a5,0x40
ffffffffc0200906:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020090a:	8082                	ret

ffffffffc020090c <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020090c:	610c                	ld	a1,0(a0)
{
ffffffffc020090e:	1141                	addi	sp,sp,-16
ffffffffc0200910:	e022                	sd	s0,0(sp)
ffffffffc0200912:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200914:	00004517          	auipc	a0,0x4
ffffffffc0200918:	95450513          	addi	a0,a0,-1708 # ffffffffc0204268 <etext+0x406>
{
ffffffffc020091c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020091e:	877ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200922:	640c                	ld	a1,8(s0)
ffffffffc0200924:	00004517          	auipc	a0,0x4
ffffffffc0200928:	95c50513          	addi	a0,a0,-1700 # ffffffffc0204280 <etext+0x41e>
ffffffffc020092c:	869ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200930:	680c                	ld	a1,16(s0)
ffffffffc0200932:	00004517          	auipc	a0,0x4
ffffffffc0200936:	96650513          	addi	a0,a0,-1690 # ffffffffc0204298 <etext+0x436>
ffffffffc020093a:	85bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020093e:	6c0c                	ld	a1,24(s0)
ffffffffc0200940:	00004517          	auipc	a0,0x4
ffffffffc0200944:	97050513          	addi	a0,a0,-1680 # ffffffffc02042b0 <etext+0x44e>
ffffffffc0200948:	84dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020094c:	700c                	ld	a1,32(s0)
ffffffffc020094e:	00004517          	auipc	a0,0x4
ffffffffc0200952:	97a50513          	addi	a0,a0,-1670 # ffffffffc02042c8 <etext+0x466>
ffffffffc0200956:	83fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020095a:	740c                	ld	a1,40(s0)
ffffffffc020095c:	00004517          	auipc	a0,0x4
ffffffffc0200960:	98450513          	addi	a0,a0,-1660 # ffffffffc02042e0 <etext+0x47e>
ffffffffc0200964:	831ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200968:	780c                	ld	a1,48(s0)
ffffffffc020096a:	00004517          	auipc	a0,0x4
ffffffffc020096e:	98e50513          	addi	a0,a0,-1650 # ffffffffc02042f8 <etext+0x496>
ffffffffc0200972:	823ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200976:	7c0c                	ld	a1,56(s0)
ffffffffc0200978:	00004517          	auipc	a0,0x4
ffffffffc020097c:	99850513          	addi	a0,a0,-1640 # ffffffffc0204310 <etext+0x4ae>
ffffffffc0200980:	815ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200984:	602c                	ld	a1,64(s0)
ffffffffc0200986:	00004517          	auipc	a0,0x4
ffffffffc020098a:	9a250513          	addi	a0,a0,-1630 # ffffffffc0204328 <etext+0x4c6>
ffffffffc020098e:	807ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200992:	642c                	ld	a1,72(s0)
ffffffffc0200994:	00004517          	auipc	a0,0x4
ffffffffc0200998:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0204340 <etext+0x4de>
ffffffffc020099c:	ff8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009a0:	682c                	ld	a1,80(s0)
ffffffffc02009a2:	00004517          	auipc	a0,0x4
ffffffffc02009a6:	9b650513          	addi	a0,a0,-1610 # ffffffffc0204358 <etext+0x4f6>
ffffffffc02009aa:	feaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009ae:	6c2c                	ld	a1,88(s0)
ffffffffc02009b0:	00004517          	auipc	a0,0x4
ffffffffc02009b4:	9c050513          	addi	a0,a0,-1600 # ffffffffc0204370 <etext+0x50e>
ffffffffc02009b8:	fdcff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009bc:	702c                	ld	a1,96(s0)
ffffffffc02009be:	00004517          	auipc	a0,0x4
ffffffffc02009c2:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0204388 <etext+0x526>
ffffffffc02009c6:	fceff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009ca:	742c                	ld	a1,104(s0)
ffffffffc02009cc:	00004517          	auipc	a0,0x4
ffffffffc02009d0:	9d450513          	addi	a0,a0,-1580 # ffffffffc02043a0 <etext+0x53e>
ffffffffc02009d4:	fc0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02009d8:	782c                	ld	a1,112(s0)
ffffffffc02009da:	00004517          	auipc	a0,0x4
ffffffffc02009de:	9de50513          	addi	a0,a0,-1570 # ffffffffc02043b8 <etext+0x556>
ffffffffc02009e2:	fb2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc02009e6:	7c2c                	ld	a1,120(s0)
ffffffffc02009e8:	00004517          	auipc	a0,0x4
ffffffffc02009ec:	9e850513          	addi	a0,a0,-1560 # ffffffffc02043d0 <etext+0x56e>
ffffffffc02009f0:	fa4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc02009f4:	604c                	ld	a1,128(s0)
ffffffffc02009f6:	00004517          	auipc	a0,0x4
ffffffffc02009fa:	9f250513          	addi	a0,a0,-1550 # ffffffffc02043e8 <etext+0x586>
ffffffffc02009fe:	f96ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a02:	644c                	ld	a1,136(s0)
ffffffffc0200a04:	00004517          	auipc	a0,0x4
ffffffffc0200a08:	9fc50513          	addi	a0,a0,-1540 # ffffffffc0204400 <etext+0x59e>
ffffffffc0200a0c:	f88ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a10:	684c                	ld	a1,144(s0)
ffffffffc0200a12:	00004517          	auipc	a0,0x4
ffffffffc0200a16:	a0650513          	addi	a0,a0,-1530 # ffffffffc0204418 <etext+0x5b6>
ffffffffc0200a1a:	f7aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a1e:	6c4c                	ld	a1,152(s0)
ffffffffc0200a20:	00004517          	auipc	a0,0x4
ffffffffc0200a24:	a1050513          	addi	a0,a0,-1520 # ffffffffc0204430 <etext+0x5ce>
ffffffffc0200a28:	f6cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a2c:	704c                	ld	a1,160(s0)
ffffffffc0200a2e:	00004517          	auipc	a0,0x4
ffffffffc0200a32:	a1a50513          	addi	a0,a0,-1510 # ffffffffc0204448 <etext+0x5e6>
ffffffffc0200a36:	f5eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a3a:	744c                	ld	a1,168(s0)
ffffffffc0200a3c:	00004517          	auipc	a0,0x4
ffffffffc0200a40:	a2450513          	addi	a0,a0,-1500 # ffffffffc0204460 <etext+0x5fe>
ffffffffc0200a44:	f50ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a48:	784c                	ld	a1,176(s0)
ffffffffc0200a4a:	00004517          	auipc	a0,0x4
ffffffffc0200a4e:	a2e50513          	addi	a0,a0,-1490 # ffffffffc0204478 <etext+0x616>
ffffffffc0200a52:	f42ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a56:	7c4c                	ld	a1,184(s0)
ffffffffc0200a58:	00004517          	auipc	a0,0x4
ffffffffc0200a5c:	a3850513          	addi	a0,a0,-1480 # ffffffffc0204490 <etext+0x62e>
ffffffffc0200a60:	f34ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a64:	606c                	ld	a1,192(s0)
ffffffffc0200a66:	00004517          	auipc	a0,0x4
ffffffffc0200a6a:	a4250513          	addi	a0,a0,-1470 # ffffffffc02044a8 <etext+0x646>
ffffffffc0200a6e:	f26ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a72:	646c                	ld	a1,200(s0)
ffffffffc0200a74:	00004517          	auipc	a0,0x4
ffffffffc0200a78:	a4c50513          	addi	a0,a0,-1460 # ffffffffc02044c0 <etext+0x65e>
ffffffffc0200a7c:	f18ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a80:	686c                	ld	a1,208(s0)
ffffffffc0200a82:	00004517          	auipc	a0,0x4
ffffffffc0200a86:	a5650513          	addi	a0,a0,-1450 # ffffffffc02044d8 <etext+0x676>
ffffffffc0200a8a:	f0aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200a8e:	6c6c                	ld	a1,216(s0)
ffffffffc0200a90:	00004517          	auipc	a0,0x4
ffffffffc0200a94:	a6050513          	addi	a0,a0,-1440 # ffffffffc02044f0 <etext+0x68e>
ffffffffc0200a98:	efcff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200a9c:	706c                	ld	a1,224(s0)
ffffffffc0200a9e:	00004517          	auipc	a0,0x4
ffffffffc0200aa2:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0204508 <etext+0x6a6>
ffffffffc0200aa6:	eeeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200aaa:	746c                	ld	a1,232(s0)
ffffffffc0200aac:	00004517          	auipc	a0,0x4
ffffffffc0200ab0:	a7450513          	addi	a0,a0,-1420 # ffffffffc0204520 <etext+0x6be>
ffffffffc0200ab4:	ee0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200ab8:	786c                	ld	a1,240(s0)
ffffffffc0200aba:	00004517          	auipc	a0,0x4
ffffffffc0200abe:	a7e50513          	addi	a0,a0,-1410 # ffffffffc0204538 <etext+0x6d6>
ffffffffc0200ac2:	ed2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ac6:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200ac8:	6402                	ld	s0,0(sp)
ffffffffc0200aca:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200acc:	00004517          	auipc	a0,0x4
ffffffffc0200ad0:	a8450513          	addi	a0,a0,-1404 # ffffffffc0204550 <etext+0x6ee>
}
ffffffffc0200ad4:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ad6:	ebeff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ada <print_trapframe>:
{
ffffffffc0200ada:	1141                	addi	sp,sp,-16
ffffffffc0200adc:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ade:	85aa                	mv	a1,a0
{
ffffffffc0200ae0:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ae2:	00004517          	auipc	a0,0x4
ffffffffc0200ae6:	a8650513          	addi	a0,a0,-1402 # ffffffffc0204568 <etext+0x706>
{
ffffffffc0200aea:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200aec:	ea8ff0ef          	jal	ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200af0:	8522                	mv	a0,s0
ffffffffc0200af2:	e1bff0ef          	jal	ffffffffc020090c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200af6:	10043583          	ld	a1,256(s0)
ffffffffc0200afa:	00004517          	auipc	a0,0x4
ffffffffc0200afe:	a8650513          	addi	a0,a0,-1402 # ffffffffc0204580 <etext+0x71e>
ffffffffc0200b02:	e92ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b06:	10843583          	ld	a1,264(s0)
ffffffffc0200b0a:	00004517          	auipc	a0,0x4
ffffffffc0200b0e:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0204598 <etext+0x736>
ffffffffc0200b12:	e82ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b16:	11043583          	ld	a1,272(s0)
ffffffffc0200b1a:	00004517          	auipc	a0,0x4
ffffffffc0200b1e:	a9650513          	addi	a0,a0,-1386 # ffffffffc02045b0 <etext+0x74e>
ffffffffc0200b22:	e72ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b26:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b2a:	6402                	ld	s0,0(sp)
ffffffffc0200b2c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b2e:	00004517          	auipc	a0,0x4
ffffffffc0200b32:	a9a50513          	addi	a0,a0,-1382 # ffffffffc02045c8 <etext+0x766>
}
ffffffffc0200b36:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b38:	e5cff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b3c <interrupt_handler>:
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
ffffffffc0200b3c:	11853783          	ld	a5,280(a0)
ffffffffc0200b40:	472d                	li	a4,11
ffffffffc0200b42:	0786                	slli	a5,a5,0x1
ffffffffc0200b44:	8385                	srli	a5,a5,0x1
ffffffffc0200b46:	08f76963          	bltu	a4,a5,ffffffffc0200bd8 <interrupt_handler+0x9c>
ffffffffc0200b4a:	00005717          	auipc	a4,0x5
ffffffffc0200b4e:	c3670713          	addi	a4,a4,-970 # ffffffffc0205780 <commands+0x48>
ffffffffc0200b52:	078a                	slli	a5,a5,0x2
ffffffffc0200b54:	97ba                	add	a5,a5,a4
ffffffffc0200b56:	439c                	lw	a5,0(a5)
ffffffffc0200b58:	97ba                	add	a5,a5,a4
ffffffffc0200b5a:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200b5c:	00004517          	auipc	a0,0x4
ffffffffc0200b60:	ae450513          	addi	a0,a0,-1308 # ffffffffc0204640 <etext+0x7de>
ffffffffc0200b64:	e30ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b68:	00004517          	auipc	a0,0x4
ffffffffc0200b6c:	ab850513          	addi	a0,a0,-1352 # ffffffffc0204620 <etext+0x7be>
ffffffffc0200b70:	e24ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200b74:	00004517          	auipc	a0,0x4
ffffffffc0200b78:	a6c50513          	addi	a0,a0,-1428 # ffffffffc02045e0 <etext+0x77e>
ffffffffc0200b7c:	e18ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b80:	00004517          	auipc	a0,0x4
ffffffffc0200b84:	a8050513          	addi	a0,a0,-1408 # ffffffffc0204600 <etext+0x79e>
ffffffffc0200b88:	e0cff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200b8c:	1141                	addi	sp,sp,-16
ffffffffc0200b8e:	e406                	sd	ra,8(sp)
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /*LAB3 请补充你在lab3中的代码 */ 
	clock_set_next_event();
ffffffffc0200b90:	94dff0ef          	jal	ffffffffc02004dc <clock_set_next_event>

        static int ticks = 0;
        static int num = 0;

        ticks++;
ffffffffc0200b94:	0000d697          	auipc	a3,0xd
ffffffffc0200b98:	90068693          	addi	a3,a3,-1792 # ffffffffc020d494 <ticks.1>
ffffffffc0200b9c:	429c                	lw	a5,0(a3)

        if (ticks % TICK_NUM == 0) {
ffffffffc0200b9e:	06400713          	li	a4,100
        ticks++;
ffffffffc0200ba2:	2785                	addiw	a5,a5,1 # 40001 <kern_entry-0xffffffffc01bffff>
        if (ticks % TICK_NUM == 0) {
ffffffffc0200ba4:	02e7e73b          	remw	a4,a5,a4
        ticks++;
ffffffffc0200ba8:	c29c                	sw	a5,0(a3)
        if (ticks % TICK_NUM == 0) {
ffffffffc0200baa:	cb05                	beqz	a4,ffffffffc0200bda <interrupt_handler+0x9e>
                print_ticks();
                num++;
        }

        if (num >= 10) {
ffffffffc0200bac:	0000d717          	auipc	a4,0xd
ffffffffc0200bb0:	8e472703          	lw	a4,-1820(a4) # ffffffffc020d490 <num.0>
ffffffffc0200bb4:	47a5                	li	a5,9
ffffffffc0200bb6:	00e7d863          	bge	a5,a4,ffffffffc0200bc6 <interrupt_handler+0x8a>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200bba:	4501                	li	a0,0
ffffffffc0200bbc:	4581                	li	a1,0
ffffffffc0200bbe:	4601                	li	a2,0
ffffffffc0200bc0:	48a1                	li	a7,8
ffffffffc0200bc2:	00000073          	ecall
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bc6:	60a2                	ld	ra,8(sp)
ffffffffc0200bc8:	0141                	addi	sp,sp,16
ffffffffc0200bca:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bcc:	00004517          	auipc	a0,0x4
ffffffffc0200bd0:	aa450513          	addi	a0,a0,-1372 # ffffffffc0204670 <etext+0x80e>
ffffffffc0200bd4:	dc0ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200bd8:	b709                	j	ffffffffc0200ada <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200bda:	06400593          	li	a1,100
ffffffffc0200bde:	00004517          	auipc	a0,0x4
ffffffffc0200be2:	a8250513          	addi	a0,a0,-1406 # ffffffffc0204660 <etext+0x7fe>
ffffffffc0200be6:	daeff0ef          	jal	ffffffffc0200194 <cprintf>
                num++;
ffffffffc0200bea:	0000d697          	auipc	a3,0xd
ffffffffc0200bee:	8a668693          	addi	a3,a3,-1882 # ffffffffc020d490 <num.0>
ffffffffc0200bf2:	429c                	lw	a5,0(a3)
ffffffffc0200bf4:	0017871b          	addiw	a4,a5,1
ffffffffc0200bf8:	c298                	sw	a4,0(a3)
ffffffffc0200bfa:	bf6d                	j	ffffffffc0200bb4 <interrupt_handler+0x78>

ffffffffc0200bfc <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200bfc:	11853783          	ld	a5,280(a0)
ffffffffc0200c00:	473d                	li	a4,15
ffffffffc0200c02:	0cf76563          	bltu	a4,a5,ffffffffc0200ccc <exception_handler+0xd0>
ffffffffc0200c06:	00005717          	auipc	a4,0x5
ffffffffc0200c0a:	baa70713          	addi	a4,a4,-1110 # ffffffffc02057b0 <commands+0x78>
ffffffffc0200c0e:	078a                	slli	a5,a5,0x2
ffffffffc0200c10:	97ba                	add	a5,a5,a4
ffffffffc0200c12:	439c                	lw	a5,0(a5)
ffffffffc0200c14:	97ba                	add	a5,a5,a4
ffffffffc0200c16:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200c18:	00004517          	auipc	a0,0x4
ffffffffc0200c1c:	bf850513          	addi	a0,a0,-1032 # ffffffffc0204810 <etext+0x9ae>
ffffffffc0200c20:	d74ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200c24:	00004517          	auipc	a0,0x4
ffffffffc0200c28:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0204690 <etext+0x82e>
ffffffffc0200c2c:	d68ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200c30:	00004517          	auipc	a0,0x4
ffffffffc0200c34:	a8050513          	addi	a0,a0,-1408 # ffffffffc02046b0 <etext+0x84e>
ffffffffc0200c38:	d5cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200c3c:	00004517          	auipc	a0,0x4
ffffffffc0200c40:	a9450513          	addi	a0,a0,-1388 # ffffffffc02046d0 <etext+0x86e>
ffffffffc0200c44:	d50ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200c48:	00004517          	auipc	a0,0x4
ffffffffc0200c4c:	aa050513          	addi	a0,a0,-1376 # ffffffffc02046e8 <etext+0x886>
ffffffffc0200c50:	d44ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200c54:	00004517          	auipc	a0,0x4
ffffffffc0200c58:	aa450513          	addi	a0,a0,-1372 # ffffffffc02046f8 <etext+0x896>
ffffffffc0200c5c:	d38ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200c60:	00004517          	auipc	a0,0x4
ffffffffc0200c64:	ab850513          	addi	a0,a0,-1352 # ffffffffc0204718 <etext+0x8b6>
ffffffffc0200c68:	d2cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200c6c:	00004517          	auipc	a0,0x4
ffffffffc0200c70:	ac450513          	addi	a0,a0,-1340 # ffffffffc0204730 <etext+0x8ce>
ffffffffc0200c74:	d20ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200c78:	00004517          	auipc	a0,0x4
ffffffffc0200c7c:	ad050513          	addi	a0,a0,-1328 # ffffffffc0204748 <etext+0x8e6>
ffffffffc0200c80:	d14ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200c84:	00004517          	auipc	a0,0x4
ffffffffc0200c88:	adc50513          	addi	a0,a0,-1316 # ffffffffc0204760 <etext+0x8fe>
ffffffffc0200c8c:	d08ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200c90:	00004517          	auipc	a0,0x4
ffffffffc0200c94:	af050513          	addi	a0,a0,-1296 # ffffffffc0204780 <etext+0x91e>
ffffffffc0200c98:	cfcff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200c9c:	00004517          	auipc	a0,0x4
ffffffffc0200ca0:	b0450513          	addi	a0,a0,-1276 # ffffffffc02047a0 <etext+0x93e>
ffffffffc0200ca4:	cf0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200ca8:	00004517          	auipc	a0,0x4
ffffffffc0200cac:	b1850513          	addi	a0,a0,-1256 # ffffffffc02047c0 <etext+0x95e>
ffffffffc0200cb0:	ce4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200cb4:	00004517          	auipc	a0,0x4
ffffffffc0200cb8:	b2c50513          	addi	a0,a0,-1236 # ffffffffc02047e0 <etext+0x97e>
ffffffffc0200cbc:	cd8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200cc0:	00004517          	auipc	a0,0x4
ffffffffc0200cc4:	b3850513          	addi	a0,a0,-1224 # ffffffffc02047f8 <etext+0x996>
ffffffffc0200cc8:	cccff06f          	j	ffffffffc0200194 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200ccc:	b539                	j	ffffffffc0200ada <print_trapframe>

ffffffffc0200cce <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200cce:	11853783          	ld	a5,280(a0)
ffffffffc0200cd2:	0007c363          	bltz	a5,ffffffffc0200cd8 <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200cd6:	b71d                	j	ffffffffc0200bfc <exception_handler>
        interrupt_handler(tf);
ffffffffc0200cd8:	b595                	j	ffffffffc0200b3c <interrupt_handler>
	...

ffffffffc0200cdc <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200cdc:	14011073          	csrw	sscratch,sp
ffffffffc0200ce0:	712d                	addi	sp,sp,-288
ffffffffc0200ce2:	e406                	sd	ra,8(sp)
ffffffffc0200ce4:	ec0e                	sd	gp,24(sp)
ffffffffc0200ce6:	f012                	sd	tp,32(sp)
ffffffffc0200ce8:	f416                	sd	t0,40(sp)
ffffffffc0200cea:	f81a                	sd	t1,48(sp)
ffffffffc0200cec:	fc1e                	sd	t2,56(sp)
ffffffffc0200cee:	e0a2                	sd	s0,64(sp)
ffffffffc0200cf0:	e4a6                	sd	s1,72(sp)
ffffffffc0200cf2:	e8aa                	sd	a0,80(sp)
ffffffffc0200cf4:	ecae                	sd	a1,88(sp)
ffffffffc0200cf6:	f0b2                	sd	a2,96(sp)
ffffffffc0200cf8:	f4b6                	sd	a3,104(sp)
ffffffffc0200cfa:	f8ba                	sd	a4,112(sp)
ffffffffc0200cfc:	fcbe                	sd	a5,120(sp)
ffffffffc0200cfe:	e142                	sd	a6,128(sp)
ffffffffc0200d00:	e546                	sd	a7,136(sp)
ffffffffc0200d02:	e94a                	sd	s2,144(sp)
ffffffffc0200d04:	ed4e                	sd	s3,152(sp)
ffffffffc0200d06:	f152                	sd	s4,160(sp)
ffffffffc0200d08:	f556                	sd	s5,168(sp)
ffffffffc0200d0a:	f95a                	sd	s6,176(sp)
ffffffffc0200d0c:	fd5e                	sd	s7,184(sp)
ffffffffc0200d0e:	e1e2                	sd	s8,192(sp)
ffffffffc0200d10:	e5e6                	sd	s9,200(sp)
ffffffffc0200d12:	e9ea                	sd	s10,208(sp)
ffffffffc0200d14:	edee                	sd	s11,216(sp)
ffffffffc0200d16:	f1f2                	sd	t3,224(sp)
ffffffffc0200d18:	f5f6                	sd	t4,232(sp)
ffffffffc0200d1a:	f9fa                	sd	t5,240(sp)
ffffffffc0200d1c:	fdfe                	sd	t6,248(sp)
ffffffffc0200d1e:	14002473          	csrr	s0,sscratch
ffffffffc0200d22:	100024f3          	csrr	s1,sstatus
ffffffffc0200d26:	14102973          	csrr	s2,sepc
ffffffffc0200d2a:	143029f3          	csrr	s3,stval
ffffffffc0200d2e:	14202a73          	csrr	s4,scause
ffffffffc0200d32:	e822                	sd	s0,16(sp)
ffffffffc0200d34:	e226                	sd	s1,256(sp)
ffffffffc0200d36:	e64a                	sd	s2,264(sp)
ffffffffc0200d38:	ea4e                	sd	s3,272(sp)
ffffffffc0200d3a:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d3c:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d3e:	f91ff0ef          	jal	ffffffffc0200cce <trap>

ffffffffc0200d42 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d42:	6492                	ld	s1,256(sp)
ffffffffc0200d44:	6932                	ld	s2,264(sp)
ffffffffc0200d46:	10049073          	csrw	sstatus,s1
ffffffffc0200d4a:	14191073          	csrw	sepc,s2
ffffffffc0200d4e:	60a2                	ld	ra,8(sp)
ffffffffc0200d50:	61e2                	ld	gp,24(sp)
ffffffffc0200d52:	7202                	ld	tp,32(sp)
ffffffffc0200d54:	72a2                	ld	t0,40(sp)
ffffffffc0200d56:	7342                	ld	t1,48(sp)
ffffffffc0200d58:	73e2                	ld	t2,56(sp)
ffffffffc0200d5a:	6406                	ld	s0,64(sp)
ffffffffc0200d5c:	64a6                	ld	s1,72(sp)
ffffffffc0200d5e:	6546                	ld	a0,80(sp)
ffffffffc0200d60:	65e6                	ld	a1,88(sp)
ffffffffc0200d62:	7606                	ld	a2,96(sp)
ffffffffc0200d64:	76a6                	ld	a3,104(sp)
ffffffffc0200d66:	7746                	ld	a4,112(sp)
ffffffffc0200d68:	77e6                	ld	a5,120(sp)
ffffffffc0200d6a:	680a                	ld	a6,128(sp)
ffffffffc0200d6c:	68aa                	ld	a7,136(sp)
ffffffffc0200d6e:	694a                	ld	s2,144(sp)
ffffffffc0200d70:	69ea                	ld	s3,152(sp)
ffffffffc0200d72:	7a0a                	ld	s4,160(sp)
ffffffffc0200d74:	7aaa                	ld	s5,168(sp)
ffffffffc0200d76:	7b4a                	ld	s6,176(sp)
ffffffffc0200d78:	7bea                	ld	s7,184(sp)
ffffffffc0200d7a:	6c0e                	ld	s8,192(sp)
ffffffffc0200d7c:	6cae                	ld	s9,200(sp)
ffffffffc0200d7e:	6d4e                	ld	s10,208(sp)
ffffffffc0200d80:	6dee                	ld	s11,216(sp)
ffffffffc0200d82:	7e0e                	ld	t3,224(sp)
ffffffffc0200d84:	7eae                	ld	t4,232(sp)
ffffffffc0200d86:	7f4e                	ld	t5,240(sp)
ffffffffc0200d88:	7fee                	ld	t6,248(sp)
ffffffffc0200d8a:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200d8c:	10200073          	sret

ffffffffc0200d90 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d90:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d92:	bf45                	j	ffffffffc0200d42 <__trapret>
	...

ffffffffc0200d96 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200d96:	00008797          	auipc	a5,0x8
ffffffffc0200d9a:	69a78793          	addi	a5,a5,1690 # ffffffffc0209430 <free_area>
ffffffffc0200d9e:	e79c                	sd	a5,8(a5)
ffffffffc0200da0:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200da2:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200da6:	8082                	ret

ffffffffc0200da8 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200da8:	00008517          	auipc	a0,0x8
ffffffffc0200dac:	69856503          	lwu	a0,1688(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200db0:	8082                	ret

ffffffffc0200db2 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200db2:	715d                	addi	sp,sp,-80
ffffffffc0200db4:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200db6:	00008417          	auipc	s0,0x8
ffffffffc0200dba:	67a40413          	addi	s0,s0,1658 # ffffffffc0209430 <free_area>
ffffffffc0200dbe:	641c                	ld	a5,8(s0)
ffffffffc0200dc0:	e486                	sd	ra,72(sp)
ffffffffc0200dc2:	fc26                	sd	s1,56(sp)
ffffffffc0200dc4:	f84a                	sd	s2,48(sp)
ffffffffc0200dc6:	f44e                	sd	s3,40(sp)
ffffffffc0200dc8:	f052                	sd	s4,32(sp)
ffffffffc0200dca:	ec56                	sd	s5,24(sp)
ffffffffc0200dcc:	e85a                	sd	s6,16(sp)
ffffffffc0200dce:	e45e                	sd	s7,8(sp)
ffffffffc0200dd0:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dd2:	2a878d63          	beq	a5,s0,ffffffffc020108c <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200dd6:	4481                	li	s1,0
ffffffffc0200dd8:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200dda:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200dde:	8b09                	andi	a4,a4,2
ffffffffc0200de0:	2a070a63          	beqz	a4,ffffffffc0201094 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200de4:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200de8:	679c                	ld	a5,8(a5)
ffffffffc0200dea:	2905                	addiw	s2,s2,1
ffffffffc0200dec:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dee:	fe8796e3          	bne	a5,s0,ffffffffc0200dda <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200df2:	89a6                	mv	s3,s1
ffffffffc0200df4:	6bf000ef          	jal	ffffffffc0201cb2 <nr_free_pages>
ffffffffc0200df8:	6f351e63          	bne	a0,s3,ffffffffc02014f4 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200dfc:	4505                	li	a0,1
ffffffffc0200dfe:	637000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200e02:	8aaa                	mv	s5,a0
ffffffffc0200e04:	42050863          	beqz	a0,ffffffffc0201234 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e08:	4505                	li	a0,1
ffffffffc0200e0a:	62b000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200e0e:	89aa                	mv	s3,a0
ffffffffc0200e10:	70050263          	beqz	a0,ffffffffc0201514 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e14:	4505                	li	a0,1
ffffffffc0200e16:	61f000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200e1a:	8a2a                	mv	s4,a0
ffffffffc0200e1c:	48050c63          	beqz	a0,ffffffffc02012b4 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e20:	293a8a63          	beq	s5,s3,ffffffffc02010b4 <default_check+0x302>
ffffffffc0200e24:	28aa8863          	beq	s5,a0,ffffffffc02010b4 <default_check+0x302>
ffffffffc0200e28:	28a98663          	beq	s3,a0,ffffffffc02010b4 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e2c:	000aa783          	lw	a5,0(s5)
ffffffffc0200e30:	2a079263          	bnez	a5,ffffffffc02010d4 <default_check+0x322>
ffffffffc0200e34:	0009a783          	lw	a5,0(s3)
ffffffffc0200e38:	28079e63          	bnez	a5,ffffffffc02010d4 <default_check+0x322>
ffffffffc0200e3c:	411c                	lw	a5,0(a0)
ffffffffc0200e3e:	28079b63          	bnez	a5,ffffffffc02010d4 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200e42:	0000c797          	auipc	a5,0xc
ffffffffc0200e46:	6867b783          	ld	a5,1670(a5) # ffffffffc020d4c8 <pages>
ffffffffc0200e4a:	40fa8733          	sub	a4,s5,a5
ffffffffc0200e4e:	00005617          	auipc	a2,0x5
ffffffffc0200e52:	b6a63603          	ld	a2,-1174(a2) # ffffffffc02059b8 <nbase>
ffffffffc0200e56:	8719                	srai	a4,a4,0x6
ffffffffc0200e58:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e5a:	0000c697          	auipc	a3,0xc
ffffffffc0200e5e:	6666b683          	ld	a3,1638(a3) # ffffffffc020d4c0 <npage>
ffffffffc0200e62:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e64:	0732                	slli	a4,a4,0xc
ffffffffc0200e66:	28d77763          	bgeu	a4,a3,ffffffffc02010f4 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200e6a:	40f98733          	sub	a4,s3,a5
ffffffffc0200e6e:	8719                	srai	a4,a4,0x6
ffffffffc0200e70:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e72:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e74:	4cd77063          	bgeu	a4,a3,ffffffffc0201334 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200e78:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e7c:	8799                	srai	a5,a5,0x6
ffffffffc0200e7e:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e80:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e82:	30d7f963          	bgeu	a5,a3,ffffffffc0201194 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200e86:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e88:	00043c03          	ld	s8,0(s0)
ffffffffc0200e8c:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e90:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200e94:	e400                	sd	s0,8(s0)
ffffffffc0200e96:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200e98:	00008797          	auipc	a5,0x8
ffffffffc0200e9c:	5a07a423          	sw	zero,1448(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200ea0:	595000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200ea4:	2c051863          	bnez	a0,ffffffffc0201174 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200ea8:	4585                	li	a1,1
ffffffffc0200eaa:	8556                	mv	a0,s5
ffffffffc0200eac:	5c7000ef          	jal	ffffffffc0201c72 <free_pages>
    free_page(p1);
ffffffffc0200eb0:	4585                	li	a1,1
ffffffffc0200eb2:	854e                	mv	a0,s3
ffffffffc0200eb4:	5bf000ef          	jal	ffffffffc0201c72 <free_pages>
    free_page(p2);
ffffffffc0200eb8:	4585                	li	a1,1
ffffffffc0200eba:	8552                	mv	a0,s4
ffffffffc0200ebc:	5b7000ef          	jal	ffffffffc0201c72 <free_pages>
    assert(nr_free == 3);
ffffffffc0200ec0:	4818                	lw	a4,16(s0)
ffffffffc0200ec2:	478d                	li	a5,3
ffffffffc0200ec4:	28f71863          	bne	a4,a5,ffffffffc0201154 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ec8:	4505                	li	a0,1
ffffffffc0200eca:	56b000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200ece:	89aa                	mv	s3,a0
ffffffffc0200ed0:	26050263          	beqz	a0,ffffffffc0201134 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ed4:	4505                	li	a0,1
ffffffffc0200ed6:	55f000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200eda:	8aaa                	mv	s5,a0
ffffffffc0200edc:	3a050c63          	beqz	a0,ffffffffc0201294 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ee0:	4505                	li	a0,1
ffffffffc0200ee2:	553000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200ee6:	8a2a                	mv	s4,a0
ffffffffc0200ee8:	38050663          	beqz	a0,ffffffffc0201274 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200eec:	4505                	li	a0,1
ffffffffc0200eee:	547000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200ef2:	36051163          	bnez	a0,ffffffffc0201254 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200ef6:	4585                	li	a1,1
ffffffffc0200ef8:	854e                	mv	a0,s3
ffffffffc0200efa:	579000ef          	jal	ffffffffc0201c72 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200efe:	641c                	ld	a5,8(s0)
ffffffffc0200f00:	20878a63          	beq	a5,s0,ffffffffc0201114 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200f04:	4505                	li	a0,1
ffffffffc0200f06:	52f000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200f0a:	30a99563          	bne	s3,a0,ffffffffc0201214 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200f0e:	4505                	li	a0,1
ffffffffc0200f10:	525000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200f14:	2e051063          	bnez	a0,ffffffffc02011f4 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0200f18:	481c                	lw	a5,16(s0)
ffffffffc0200f1a:	2a079d63          	bnez	a5,ffffffffc02011d4 <default_check+0x422>
    free_page(p);
ffffffffc0200f1e:	854e                	mv	a0,s3
ffffffffc0200f20:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200f22:	01843023          	sd	s8,0(s0)
ffffffffc0200f26:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200f2a:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200f2e:	545000ef          	jal	ffffffffc0201c72 <free_pages>
    free_page(p1);
ffffffffc0200f32:	4585                	li	a1,1
ffffffffc0200f34:	8556                	mv	a0,s5
ffffffffc0200f36:	53d000ef          	jal	ffffffffc0201c72 <free_pages>
    free_page(p2);
ffffffffc0200f3a:	4585                	li	a1,1
ffffffffc0200f3c:	8552                	mv	a0,s4
ffffffffc0200f3e:	535000ef          	jal	ffffffffc0201c72 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f42:	4515                	li	a0,5
ffffffffc0200f44:	4f1000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200f48:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f4a:	26050563          	beqz	a0,ffffffffc02011b4 <default_check+0x402>
ffffffffc0200f4e:	651c                	ld	a5,8(a0)
ffffffffc0200f50:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f52:	8b85                	andi	a5,a5,1
ffffffffc0200f54:	54079063          	bnez	a5,ffffffffc0201494 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f58:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f5a:	00043b03          	ld	s6,0(s0)
ffffffffc0200f5e:	00843a83          	ld	s5,8(s0)
ffffffffc0200f62:	e000                	sd	s0,0(s0)
ffffffffc0200f64:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200f66:	4cf000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200f6a:	50051563          	bnez	a0,ffffffffc0201474 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200f6e:	08098a13          	addi	s4,s3,128
ffffffffc0200f72:	8552                	mv	a0,s4
ffffffffc0200f74:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200f76:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200f7a:	00008797          	auipc	a5,0x8
ffffffffc0200f7e:	4c07a323          	sw	zero,1222(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200f82:	4f1000ef          	jal	ffffffffc0201c72 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f86:	4511                	li	a0,4
ffffffffc0200f88:	4ad000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200f8c:	4c051463          	bnez	a0,ffffffffc0201454 <default_check+0x6a2>
ffffffffc0200f90:	0889b783          	ld	a5,136(s3)
ffffffffc0200f94:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200f96:	8b85                	andi	a5,a5,1
ffffffffc0200f98:	48078e63          	beqz	a5,ffffffffc0201434 <default_check+0x682>
ffffffffc0200f9c:	0909a703          	lw	a4,144(s3)
ffffffffc0200fa0:	478d                	li	a5,3
ffffffffc0200fa2:	48f71963          	bne	a4,a5,ffffffffc0201434 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200fa6:	450d                	li	a0,3
ffffffffc0200fa8:	48d000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200fac:	8c2a                	mv	s8,a0
ffffffffc0200fae:	46050363          	beqz	a0,ffffffffc0201414 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0200fb2:	4505                	li	a0,1
ffffffffc0200fb4:	481000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0200fb8:	42051e63          	bnez	a0,ffffffffc02013f4 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0200fbc:	418a1c63          	bne	s4,s8,ffffffffc02013d4 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200fc0:	4585                	li	a1,1
ffffffffc0200fc2:	854e                	mv	a0,s3
ffffffffc0200fc4:	4af000ef          	jal	ffffffffc0201c72 <free_pages>
    free_pages(p1, 3);
ffffffffc0200fc8:	458d                	li	a1,3
ffffffffc0200fca:	8552                	mv	a0,s4
ffffffffc0200fcc:	4a7000ef          	jal	ffffffffc0201c72 <free_pages>
ffffffffc0200fd0:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200fd4:	04098c13          	addi	s8,s3,64
ffffffffc0200fd8:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200fda:	8b85                	andi	a5,a5,1
ffffffffc0200fdc:	3c078c63          	beqz	a5,ffffffffc02013b4 <default_check+0x602>
ffffffffc0200fe0:	0109a703          	lw	a4,16(s3)
ffffffffc0200fe4:	4785                	li	a5,1
ffffffffc0200fe6:	3cf71763          	bne	a4,a5,ffffffffc02013b4 <default_check+0x602>
ffffffffc0200fea:	008a3783          	ld	a5,8(s4)
ffffffffc0200fee:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200ff0:	8b85                	andi	a5,a5,1
ffffffffc0200ff2:	3a078163          	beqz	a5,ffffffffc0201394 <default_check+0x5e2>
ffffffffc0200ff6:	010a2703          	lw	a4,16(s4)
ffffffffc0200ffa:	478d                	li	a5,3
ffffffffc0200ffc:	38f71c63          	bne	a4,a5,ffffffffc0201394 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201000:	4505                	li	a0,1
ffffffffc0201002:	433000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0201006:	36a99763          	bne	s3,a0,ffffffffc0201374 <default_check+0x5c2>
    free_page(p0);
ffffffffc020100a:	4585                	li	a1,1
ffffffffc020100c:	467000ef          	jal	ffffffffc0201c72 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201010:	4509                	li	a0,2
ffffffffc0201012:	423000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc0201016:	32aa1f63          	bne	s4,a0,ffffffffc0201354 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020101a:	4589                	li	a1,2
ffffffffc020101c:	457000ef          	jal	ffffffffc0201c72 <free_pages>
    free_page(p2);
ffffffffc0201020:	4585                	li	a1,1
ffffffffc0201022:	8562                	mv	a0,s8
ffffffffc0201024:	44f000ef          	jal	ffffffffc0201c72 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201028:	4515                	li	a0,5
ffffffffc020102a:	40b000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc020102e:	89aa                	mv	s3,a0
ffffffffc0201030:	48050263          	beqz	a0,ffffffffc02014b4 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201034:	4505                	li	a0,1
ffffffffc0201036:	3ff000ef          	jal	ffffffffc0201c34 <alloc_pages>
ffffffffc020103a:	2c051d63          	bnez	a0,ffffffffc0201314 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc020103e:	481c                	lw	a5,16(s0)
ffffffffc0201040:	2a079a63          	bnez	a5,ffffffffc02012f4 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201044:	4595                	li	a1,5
ffffffffc0201046:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201048:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc020104c:	01643023          	sd	s6,0(s0)
ffffffffc0201050:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201054:	41f000ef          	jal	ffffffffc0201c72 <free_pages>
    return listelm->next;
ffffffffc0201058:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020105a:	00878963          	beq	a5,s0,ffffffffc020106c <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020105e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201062:	679c                	ld	a5,8(a5)
ffffffffc0201064:	397d                	addiw	s2,s2,-1
ffffffffc0201066:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201068:	fe879be3          	bne	a5,s0,ffffffffc020105e <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc020106c:	26091463          	bnez	s2,ffffffffc02012d4 <default_check+0x522>
    assert(total == 0);
ffffffffc0201070:	46049263          	bnez	s1,ffffffffc02014d4 <default_check+0x722>
}
ffffffffc0201074:	60a6                	ld	ra,72(sp)
ffffffffc0201076:	6406                	ld	s0,64(sp)
ffffffffc0201078:	74e2                	ld	s1,56(sp)
ffffffffc020107a:	7942                	ld	s2,48(sp)
ffffffffc020107c:	79a2                	ld	s3,40(sp)
ffffffffc020107e:	7a02                	ld	s4,32(sp)
ffffffffc0201080:	6ae2                	ld	s5,24(sp)
ffffffffc0201082:	6b42                	ld	s6,16(sp)
ffffffffc0201084:	6ba2                	ld	s7,8(sp)
ffffffffc0201086:	6c02                	ld	s8,0(sp)
ffffffffc0201088:	6161                	addi	sp,sp,80
ffffffffc020108a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020108c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020108e:	4481                	li	s1,0
ffffffffc0201090:	4901                	li	s2,0
ffffffffc0201092:	b38d                	j	ffffffffc0200df4 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201094:	00003697          	auipc	a3,0x3
ffffffffc0201098:	79468693          	addi	a3,a3,1940 # ffffffffc0204828 <etext+0x9c6>
ffffffffc020109c:	00003617          	auipc	a2,0x3
ffffffffc02010a0:	79c60613          	addi	a2,a2,1948 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02010a4:	0f000593          	li	a1,240
ffffffffc02010a8:	00003517          	auipc	a0,0x3
ffffffffc02010ac:	7a850513          	addi	a0,a0,1960 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02010b0:	b96ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010b4:	00004697          	auipc	a3,0x4
ffffffffc02010b8:	83468693          	addi	a3,a3,-1996 # ffffffffc02048e8 <etext+0xa86>
ffffffffc02010bc:	00003617          	auipc	a2,0x3
ffffffffc02010c0:	77c60613          	addi	a2,a2,1916 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02010c4:	0bd00593          	li	a1,189
ffffffffc02010c8:	00003517          	auipc	a0,0x3
ffffffffc02010cc:	78850513          	addi	a0,a0,1928 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02010d0:	b76ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02010d4:	00004697          	auipc	a3,0x4
ffffffffc02010d8:	83c68693          	addi	a3,a3,-1988 # ffffffffc0204910 <etext+0xaae>
ffffffffc02010dc:	00003617          	auipc	a2,0x3
ffffffffc02010e0:	75c60613          	addi	a2,a2,1884 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02010e4:	0be00593          	li	a1,190
ffffffffc02010e8:	00003517          	auipc	a0,0x3
ffffffffc02010ec:	76850513          	addi	a0,a0,1896 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02010f0:	b56ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010f4:	00004697          	auipc	a3,0x4
ffffffffc02010f8:	85c68693          	addi	a3,a3,-1956 # ffffffffc0204950 <etext+0xaee>
ffffffffc02010fc:	00003617          	auipc	a2,0x3
ffffffffc0201100:	73c60613          	addi	a2,a2,1852 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201104:	0c000593          	li	a1,192
ffffffffc0201108:	00003517          	auipc	a0,0x3
ffffffffc020110c:	74850513          	addi	a0,a0,1864 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201110:	b36ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201114:	00004697          	auipc	a3,0x4
ffffffffc0201118:	8c468693          	addi	a3,a3,-1852 # ffffffffc02049d8 <etext+0xb76>
ffffffffc020111c:	00003617          	auipc	a2,0x3
ffffffffc0201120:	71c60613          	addi	a2,a2,1820 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201124:	0d900593          	li	a1,217
ffffffffc0201128:	00003517          	auipc	a0,0x3
ffffffffc020112c:	72850513          	addi	a0,a0,1832 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201130:	b16ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201134:	00003697          	auipc	a3,0x3
ffffffffc0201138:	75468693          	addi	a3,a3,1876 # ffffffffc0204888 <etext+0xa26>
ffffffffc020113c:	00003617          	auipc	a2,0x3
ffffffffc0201140:	6fc60613          	addi	a2,a2,1788 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201144:	0d200593          	li	a1,210
ffffffffc0201148:	00003517          	auipc	a0,0x3
ffffffffc020114c:	70850513          	addi	a0,a0,1800 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201150:	af6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 3);
ffffffffc0201154:	00004697          	auipc	a3,0x4
ffffffffc0201158:	87468693          	addi	a3,a3,-1932 # ffffffffc02049c8 <etext+0xb66>
ffffffffc020115c:	00003617          	auipc	a2,0x3
ffffffffc0201160:	6dc60613          	addi	a2,a2,1756 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201164:	0d000593          	li	a1,208
ffffffffc0201168:	00003517          	auipc	a0,0x3
ffffffffc020116c:	6e850513          	addi	a0,a0,1768 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201170:	ad6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201174:	00004697          	auipc	a3,0x4
ffffffffc0201178:	83c68693          	addi	a3,a3,-1988 # ffffffffc02049b0 <etext+0xb4e>
ffffffffc020117c:	00003617          	auipc	a2,0x3
ffffffffc0201180:	6bc60613          	addi	a2,a2,1724 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201184:	0cb00593          	li	a1,203
ffffffffc0201188:	00003517          	auipc	a0,0x3
ffffffffc020118c:	6c850513          	addi	a0,a0,1736 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201190:	ab6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201194:	00003697          	auipc	a3,0x3
ffffffffc0201198:	7fc68693          	addi	a3,a3,2044 # ffffffffc0204990 <etext+0xb2e>
ffffffffc020119c:	00003617          	auipc	a2,0x3
ffffffffc02011a0:	69c60613          	addi	a2,a2,1692 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02011a4:	0c200593          	li	a1,194
ffffffffc02011a8:	00003517          	auipc	a0,0x3
ffffffffc02011ac:	6a850513          	addi	a0,a0,1704 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02011b0:	a96ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != NULL);
ffffffffc02011b4:	00004697          	auipc	a3,0x4
ffffffffc02011b8:	86c68693          	addi	a3,a3,-1940 # ffffffffc0204a20 <etext+0xbbe>
ffffffffc02011bc:	00003617          	auipc	a2,0x3
ffffffffc02011c0:	67c60613          	addi	a2,a2,1660 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02011c4:	0f800593          	li	a1,248
ffffffffc02011c8:	00003517          	auipc	a0,0x3
ffffffffc02011cc:	68850513          	addi	a0,a0,1672 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02011d0:	a76ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02011d4:	00004697          	auipc	a3,0x4
ffffffffc02011d8:	83c68693          	addi	a3,a3,-1988 # ffffffffc0204a10 <etext+0xbae>
ffffffffc02011dc:	00003617          	auipc	a2,0x3
ffffffffc02011e0:	65c60613          	addi	a2,a2,1628 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02011e4:	0df00593          	li	a1,223
ffffffffc02011e8:	00003517          	auipc	a0,0x3
ffffffffc02011ec:	66850513          	addi	a0,a0,1640 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02011f0:	a56ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011f4:	00003697          	auipc	a3,0x3
ffffffffc02011f8:	7bc68693          	addi	a3,a3,1980 # ffffffffc02049b0 <etext+0xb4e>
ffffffffc02011fc:	00003617          	auipc	a2,0x3
ffffffffc0201200:	63c60613          	addi	a2,a2,1596 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201204:	0dd00593          	li	a1,221
ffffffffc0201208:	00003517          	auipc	a0,0x3
ffffffffc020120c:	64850513          	addi	a0,a0,1608 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201210:	a36ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201214:	00003697          	auipc	a3,0x3
ffffffffc0201218:	7dc68693          	addi	a3,a3,2012 # ffffffffc02049f0 <etext+0xb8e>
ffffffffc020121c:	00003617          	auipc	a2,0x3
ffffffffc0201220:	61c60613          	addi	a2,a2,1564 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201224:	0dc00593          	li	a1,220
ffffffffc0201228:	00003517          	auipc	a0,0x3
ffffffffc020122c:	62850513          	addi	a0,a0,1576 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201230:	a16ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201234:	00003697          	auipc	a3,0x3
ffffffffc0201238:	65468693          	addi	a3,a3,1620 # ffffffffc0204888 <etext+0xa26>
ffffffffc020123c:	00003617          	auipc	a2,0x3
ffffffffc0201240:	5fc60613          	addi	a2,a2,1532 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201244:	0b900593          	li	a1,185
ffffffffc0201248:	00003517          	auipc	a0,0x3
ffffffffc020124c:	60850513          	addi	a0,a0,1544 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201250:	9f6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201254:	00003697          	auipc	a3,0x3
ffffffffc0201258:	75c68693          	addi	a3,a3,1884 # ffffffffc02049b0 <etext+0xb4e>
ffffffffc020125c:	00003617          	auipc	a2,0x3
ffffffffc0201260:	5dc60613          	addi	a2,a2,1500 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201264:	0d600593          	li	a1,214
ffffffffc0201268:	00003517          	auipc	a0,0x3
ffffffffc020126c:	5e850513          	addi	a0,a0,1512 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201270:	9d6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201274:	00003697          	auipc	a3,0x3
ffffffffc0201278:	65468693          	addi	a3,a3,1620 # ffffffffc02048c8 <etext+0xa66>
ffffffffc020127c:	00003617          	auipc	a2,0x3
ffffffffc0201280:	5bc60613          	addi	a2,a2,1468 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201284:	0d400593          	li	a1,212
ffffffffc0201288:	00003517          	auipc	a0,0x3
ffffffffc020128c:	5c850513          	addi	a0,a0,1480 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201290:	9b6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201294:	00003697          	auipc	a3,0x3
ffffffffc0201298:	61468693          	addi	a3,a3,1556 # ffffffffc02048a8 <etext+0xa46>
ffffffffc020129c:	00003617          	auipc	a2,0x3
ffffffffc02012a0:	59c60613          	addi	a2,a2,1436 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02012a4:	0d300593          	li	a1,211
ffffffffc02012a8:	00003517          	auipc	a0,0x3
ffffffffc02012ac:	5a850513          	addi	a0,a0,1448 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02012b0:	996ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02012b4:	00003697          	auipc	a3,0x3
ffffffffc02012b8:	61468693          	addi	a3,a3,1556 # ffffffffc02048c8 <etext+0xa66>
ffffffffc02012bc:	00003617          	auipc	a2,0x3
ffffffffc02012c0:	57c60613          	addi	a2,a2,1404 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02012c4:	0bb00593          	li	a1,187
ffffffffc02012c8:	00003517          	auipc	a0,0x3
ffffffffc02012cc:	58850513          	addi	a0,a0,1416 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02012d0:	976ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(count == 0);
ffffffffc02012d4:	00004697          	auipc	a3,0x4
ffffffffc02012d8:	89c68693          	addi	a3,a3,-1892 # ffffffffc0204b70 <etext+0xd0e>
ffffffffc02012dc:	00003617          	auipc	a2,0x3
ffffffffc02012e0:	55c60613          	addi	a2,a2,1372 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02012e4:	12500593          	li	a1,293
ffffffffc02012e8:	00003517          	auipc	a0,0x3
ffffffffc02012ec:	56850513          	addi	a0,a0,1384 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02012f0:	956ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02012f4:	00003697          	auipc	a3,0x3
ffffffffc02012f8:	71c68693          	addi	a3,a3,1820 # ffffffffc0204a10 <etext+0xbae>
ffffffffc02012fc:	00003617          	auipc	a2,0x3
ffffffffc0201300:	53c60613          	addi	a2,a2,1340 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201304:	11a00593          	li	a1,282
ffffffffc0201308:	00003517          	auipc	a0,0x3
ffffffffc020130c:	54850513          	addi	a0,a0,1352 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201310:	936ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201314:	00003697          	auipc	a3,0x3
ffffffffc0201318:	69c68693          	addi	a3,a3,1692 # ffffffffc02049b0 <etext+0xb4e>
ffffffffc020131c:	00003617          	auipc	a2,0x3
ffffffffc0201320:	51c60613          	addi	a2,a2,1308 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201324:	11800593          	li	a1,280
ffffffffc0201328:	00003517          	auipc	a0,0x3
ffffffffc020132c:	52850513          	addi	a0,a0,1320 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201330:	916ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201334:	00003697          	auipc	a3,0x3
ffffffffc0201338:	63c68693          	addi	a3,a3,1596 # ffffffffc0204970 <etext+0xb0e>
ffffffffc020133c:	00003617          	auipc	a2,0x3
ffffffffc0201340:	4fc60613          	addi	a2,a2,1276 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201344:	0c100593          	li	a1,193
ffffffffc0201348:	00003517          	auipc	a0,0x3
ffffffffc020134c:	50850513          	addi	a0,a0,1288 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201350:	8f6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201354:	00003697          	auipc	a3,0x3
ffffffffc0201358:	7dc68693          	addi	a3,a3,2012 # ffffffffc0204b30 <etext+0xcce>
ffffffffc020135c:	00003617          	auipc	a2,0x3
ffffffffc0201360:	4dc60613          	addi	a2,a2,1244 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201364:	11200593          	li	a1,274
ffffffffc0201368:	00003517          	auipc	a0,0x3
ffffffffc020136c:	4e850513          	addi	a0,a0,1256 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201370:	8d6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201374:	00003697          	auipc	a3,0x3
ffffffffc0201378:	79c68693          	addi	a3,a3,1948 # ffffffffc0204b10 <etext+0xcae>
ffffffffc020137c:	00003617          	auipc	a2,0x3
ffffffffc0201380:	4bc60613          	addi	a2,a2,1212 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201384:	11000593          	li	a1,272
ffffffffc0201388:	00003517          	auipc	a0,0x3
ffffffffc020138c:	4c850513          	addi	a0,a0,1224 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201390:	8b6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201394:	00003697          	auipc	a3,0x3
ffffffffc0201398:	75468693          	addi	a3,a3,1876 # ffffffffc0204ae8 <etext+0xc86>
ffffffffc020139c:	00003617          	auipc	a2,0x3
ffffffffc02013a0:	49c60613          	addi	a2,a2,1180 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02013a4:	10e00593          	li	a1,270
ffffffffc02013a8:	00003517          	auipc	a0,0x3
ffffffffc02013ac:	4a850513          	addi	a0,a0,1192 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02013b0:	896ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02013b4:	00003697          	auipc	a3,0x3
ffffffffc02013b8:	70c68693          	addi	a3,a3,1804 # ffffffffc0204ac0 <etext+0xc5e>
ffffffffc02013bc:	00003617          	auipc	a2,0x3
ffffffffc02013c0:	47c60613          	addi	a2,a2,1148 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02013c4:	10d00593          	li	a1,269
ffffffffc02013c8:	00003517          	auipc	a0,0x3
ffffffffc02013cc:	48850513          	addi	a0,a0,1160 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02013d0:	876ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02013d4:	00003697          	auipc	a3,0x3
ffffffffc02013d8:	6dc68693          	addi	a3,a3,1756 # ffffffffc0204ab0 <etext+0xc4e>
ffffffffc02013dc:	00003617          	auipc	a2,0x3
ffffffffc02013e0:	45c60613          	addi	a2,a2,1116 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02013e4:	10800593          	li	a1,264
ffffffffc02013e8:	00003517          	auipc	a0,0x3
ffffffffc02013ec:	46850513          	addi	a0,a0,1128 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02013f0:	856ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013f4:	00003697          	auipc	a3,0x3
ffffffffc02013f8:	5bc68693          	addi	a3,a3,1468 # ffffffffc02049b0 <etext+0xb4e>
ffffffffc02013fc:	00003617          	auipc	a2,0x3
ffffffffc0201400:	43c60613          	addi	a2,a2,1084 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201404:	10700593          	li	a1,263
ffffffffc0201408:	00003517          	auipc	a0,0x3
ffffffffc020140c:	44850513          	addi	a0,a0,1096 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201410:	836ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201414:	00003697          	auipc	a3,0x3
ffffffffc0201418:	67c68693          	addi	a3,a3,1660 # ffffffffc0204a90 <etext+0xc2e>
ffffffffc020141c:	00003617          	auipc	a2,0x3
ffffffffc0201420:	41c60613          	addi	a2,a2,1052 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201424:	10600593          	li	a1,262
ffffffffc0201428:	00003517          	auipc	a0,0x3
ffffffffc020142c:	42850513          	addi	a0,a0,1064 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201430:	816ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201434:	00003697          	auipc	a3,0x3
ffffffffc0201438:	62c68693          	addi	a3,a3,1580 # ffffffffc0204a60 <etext+0xbfe>
ffffffffc020143c:	00003617          	auipc	a2,0x3
ffffffffc0201440:	3fc60613          	addi	a2,a2,1020 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201444:	10500593          	li	a1,261
ffffffffc0201448:	00003517          	auipc	a0,0x3
ffffffffc020144c:	40850513          	addi	a0,a0,1032 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201450:	ff7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201454:	00003697          	auipc	a3,0x3
ffffffffc0201458:	5f468693          	addi	a3,a3,1524 # ffffffffc0204a48 <etext+0xbe6>
ffffffffc020145c:	00003617          	auipc	a2,0x3
ffffffffc0201460:	3dc60613          	addi	a2,a2,988 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201464:	10400593          	li	a1,260
ffffffffc0201468:	00003517          	auipc	a0,0x3
ffffffffc020146c:	3e850513          	addi	a0,a0,1000 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201470:	fd7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201474:	00003697          	auipc	a3,0x3
ffffffffc0201478:	53c68693          	addi	a3,a3,1340 # ffffffffc02049b0 <etext+0xb4e>
ffffffffc020147c:	00003617          	auipc	a2,0x3
ffffffffc0201480:	3bc60613          	addi	a2,a2,956 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201484:	0fe00593          	li	a1,254
ffffffffc0201488:	00003517          	auipc	a0,0x3
ffffffffc020148c:	3c850513          	addi	a0,a0,968 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201490:	fb7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201494:	00003697          	auipc	a3,0x3
ffffffffc0201498:	59c68693          	addi	a3,a3,1436 # ffffffffc0204a30 <etext+0xbce>
ffffffffc020149c:	00003617          	auipc	a2,0x3
ffffffffc02014a0:	39c60613          	addi	a2,a2,924 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02014a4:	0f900593          	li	a1,249
ffffffffc02014a8:	00003517          	auipc	a0,0x3
ffffffffc02014ac:	3a850513          	addi	a0,a0,936 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02014b0:	f97fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02014b4:	00003697          	auipc	a3,0x3
ffffffffc02014b8:	69c68693          	addi	a3,a3,1692 # ffffffffc0204b50 <etext+0xcee>
ffffffffc02014bc:	00003617          	auipc	a2,0x3
ffffffffc02014c0:	37c60613          	addi	a2,a2,892 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02014c4:	11700593          	li	a1,279
ffffffffc02014c8:	00003517          	auipc	a0,0x3
ffffffffc02014cc:	38850513          	addi	a0,a0,904 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02014d0:	f77fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == 0);
ffffffffc02014d4:	00003697          	auipc	a3,0x3
ffffffffc02014d8:	6ac68693          	addi	a3,a3,1708 # ffffffffc0204b80 <etext+0xd1e>
ffffffffc02014dc:	00003617          	auipc	a2,0x3
ffffffffc02014e0:	35c60613          	addi	a2,a2,860 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02014e4:	12600593          	li	a1,294
ffffffffc02014e8:	00003517          	auipc	a0,0x3
ffffffffc02014ec:	36850513          	addi	a0,a0,872 # ffffffffc0204850 <etext+0x9ee>
ffffffffc02014f0:	f57fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == nr_free_pages());
ffffffffc02014f4:	00003697          	auipc	a3,0x3
ffffffffc02014f8:	37468693          	addi	a3,a3,884 # ffffffffc0204868 <etext+0xa06>
ffffffffc02014fc:	00003617          	auipc	a2,0x3
ffffffffc0201500:	33c60613          	addi	a2,a2,828 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201504:	0f300593          	li	a1,243
ffffffffc0201508:	00003517          	auipc	a0,0x3
ffffffffc020150c:	34850513          	addi	a0,a0,840 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201510:	f37fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201514:	00003697          	auipc	a3,0x3
ffffffffc0201518:	39468693          	addi	a3,a3,916 # ffffffffc02048a8 <etext+0xa46>
ffffffffc020151c:	00003617          	auipc	a2,0x3
ffffffffc0201520:	31c60613          	addi	a2,a2,796 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201524:	0ba00593          	li	a1,186
ffffffffc0201528:	00003517          	auipc	a0,0x3
ffffffffc020152c:	32850513          	addi	a0,a0,808 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201530:	f17fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201534 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201534:	1141                	addi	sp,sp,-16
ffffffffc0201536:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201538:	14058463          	beqz	a1,ffffffffc0201680 <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc020153c:	00659713          	slli	a4,a1,0x6
ffffffffc0201540:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201544:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201546:	c30d                	beqz	a4,ffffffffc0201568 <default_free_pages+0x34>
ffffffffc0201548:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020154a:	8b05                	andi	a4,a4,1
ffffffffc020154c:	10071a63          	bnez	a4,ffffffffc0201660 <default_free_pages+0x12c>
ffffffffc0201550:	6798                	ld	a4,8(a5)
ffffffffc0201552:	8b09                	andi	a4,a4,2
ffffffffc0201554:	10071663          	bnez	a4,ffffffffc0201660 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201558:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc020155c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201560:	04078793          	addi	a5,a5,64
ffffffffc0201564:	fed792e3          	bne	a5,a3,ffffffffc0201548 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201568:	2581                	sext.w	a1,a1
ffffffffc020156a:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020156c:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201570:	4789                	li	a5,2
ffffffffc0201572:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201576:	00008697          	auipc	a3,0x8
ffffffffc020157a:	eba68693          	addi	a3,a3,-326 # ffffffffc0209430 <free_area>
ffffffffc020157e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201580:	669c                	ld	a5,8(a3)
ffffffffc0201582:	9f2d                	addw	a4,a4,a1
ffffffffc0201584:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201586:	0ad78163          	beq	a5,a3,ffffffffc0201628 <default_free_pages+0xf4>
            struct Page* page = le2page(le, page_link);
ffffffffc020158a:	fe878713          	addi	a4,a5,-24
ffffffffc020158e:	4581                	li	a1,0
ffffffffc0201590:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201594:	00e56a63          	bltu	a0,a4,ffffffffc02015a8 <default_free_pages+0x74>
    return listelm->next;
ffffffffc0201598:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020159a:	04d70c63          	beq	a4,a3,ffffffffc02015f2 <default_free_pages+0xbe>
    struct Page *p = base;
ffffffffc020159e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02015a0:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02015a4:	fee57ae3          	bgeu	a0,a4,ffffffffc0201598 <default_free_pages+0x64>
ffffffffc02015a8:	c199                	beqz	a1,ffffffffc02015ae <default_free_pages+0x7a>
ffffffffc02015aa:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02015ae:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02015b0:	e390                	sd	a2,0(a5)
ffffffffc02015b2:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02015b4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015b6:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02015b8:	00d70d63          	beq	a4,a3,ffffffffc02015d2 <default_free_pages+0x9e>
        if (p + p->property == base) {
ffffffffc02015bc:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02015c0:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc02015c4:	02059813          	slli	a6,a1,0x20
ffffffffc02015c8:	01a85793          	srli	a5,a6,0x1a
ffffffffc02015cc:	97b2                	add	a5,a5,a2
ffffffffc02015ce:	02f50c63          	beq	a0,a5,ffffffffc0201606 <default_free_pages+0xd2>
    return listelm->next;
ffffffffc02015d2:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc02015d4:	00d78c63          	beq	a5,a3,ffffffffc02015ec <default_free_pages+0xb8>
        if (base + base->property == p) {
ffffffffc02015d8:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02015da:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc02015de:	02061593          	slli	a1,a2,0x20
ffffffffc02015e2:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02015e6:	972a                	add	a4,a4,a0
ffffffffc02015e8:	04e68c63          	beq	a3,a4,ffffffffc0201640 <default_free_pages+0x10c>
}
ffffffffc02015ec:	60a2                	ld	ra,8(sp)
ffffffffc02015ee:	0141                	addi	sp,sp,16
ffffffffc02015f0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02015f2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015f4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02015f6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02015f8:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02015fa:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015fc:	02d70f63          	beq	a4,a3,ffffffffc020163a <default_free_pages+0x106>
ffffffffc0201600:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201602:	87ba                	mv	a5,a4
ffffffffc0201604:	bf71                	j	ffffffffc02015a0 <default_free_pages+0x6c>
            p->property += base->property;
ffffffffc0201606:	491c                	lw	a5,16(a0)
ffffffffc0201608:	9fad                	addw	a5,a5,a1
ffffffffc020160a:	fef72c23          	sw	a5,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020160e:	57f5                	li	a5,-3
ffffffffc0201610:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201614:	01853803          	ld	a6,24(a0)
ffffffffc0201618:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020161a:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020161c:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201620:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201622:	0105b023          	sd	a6,0(a1)
ffffffffc0201626:	b77d                	j	ffffffffc02015d4 <default_free_pages+0xa0>
}
ffffffffc0201628:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020162a:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020162e:	e398                	sd	a4,0(a5)
ffffffffc0201630:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201632:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201634:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201636:	0141                	addi	sp,sp,16
ffffffffc0201638:	8082                	ret
ffffffffc020163a:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020163c:	873e                	mv	a4,a5
ffffffffc020163e:	bfad                	j	ffffffffc02015b8 <default_free_pages+0x84>
            base->property += p->property;
ffffffffc0201640:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201644:	ff078693          	addi	a3,a5,-16
ffffffffc0201648:	9f31                	addw	a4,a4,a2
ffffffffc020164a:	c918                	sw	a4,16(a0)
ffffffffc020164c:	5775                	li	a4,-3
ffffffffc020164e:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201652:	6398                	ld	a4,0(a5)
ffffffffc0201654:	679c                	ld	a5,8(a5)
}
ffffffffc0201656:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201658:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020165a:	e398                	sd	a4,0(a5)
ffffffffc020165c:	0141                	addi	sp,sp,16
ffffffffc020165e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201660:	00003697          	auipc	a3,0x3
ffffffffc0201664:	53868693          	addi	a3,a3,1336 # ffffffffc0204b98 <etext+0xd36>
ffffffffc0201668:	00003617          	auipc	a2,0x3
ffffffffc020166c:	1d060613          	addi	a2,a2,464 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201670:	08300593          	li	a1,131
ffffffffc0201674:	00003517          	auipc	a0,0x3
ffffffffc0201678:	1dc50513          	addi	a0,a0,476 # ffffffffc0204850 <etext+0x9ee>
ffffffffc020167c:	dcbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201680:	00003697          	auipc	a3,0x3
ffffffffc0201684:	51068693          	addi	a3,a3,1296 # ffffffffc0204b90 <etext+0xd2e>
ffffffffc0201688:	00003617          	auipc	a2,0x3
ffffffffc020168c:	1b060613          	addi	a2,a2,432 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201690:	08000593          	li	a1,128
ffffffffc0201694:	00003517          	auipc	a0,0x3
ffffffffc0201698:	1bc50513          	addi	a0,a0,444 # ffffffffc0204850 <etext+0x9ee>
ffffffffc020169c:	dabfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02016a0 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02016a0:	c949                	beqz	a0,ffffffffc0201732 <default_alloc_pages+0x92>
    if (n > nr_free) {
ffffffffc02016a2:	00008617          	auipc	a2,0x8
ffffffffc02016a6:	d8e60613          	addi	a2,a2,-626 # ffffffffc0209430 <free_area>
ffffffffc02016aa:	4a0c                	lw	a1,16(a2)
ffffffffc02016ac:	872a                	mv	a4,a0
ffffffffc02016ae:	02059793          	slli	a5,a1,0x20
ffffffffc02016b2:	9381                	srli	a5,a5,0x20
ffffffffc02016b4:	00a7eb63          	bltu	a5,a0,ffffffffc02016ca <default_alloc_pages+0x2a>
    list_entry_t *le = &free_list;
ffffffffc02016b8:	87b2                	mv	a5,a2
ffffffffc02016ba:	a029                	j	ffffffffc02016c4 <default_alloc_pages+0x24>
        if (p->property >= n) {
ffffffffc02016bc:	ff87e683          	lwu	a3,-8(a5)
ffffffffc02016c0:	00e6f763          	bgeu	a3,a4,ffffffffc02016ce <default_alloc_pages+0x2e>
    return listelm->next;
ffffffffc02016c4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02016c6:	fec79be3          	bne	a5,a2,ffffffffc02016bc <default_alloc_pages+0x1c>
        return NULL;
ffffffffc02016ca:	4501                	li	a0,0
}
ffffffffc02016cc:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc02016ce:	0087b883          	ld	a7,8(a5)
        if (page->property > n) {
ffffffffc02016d2:	ff87a803          	lw	a6,-8(a5)
    return listelm->prev;
ffffffffc02016d6:	6394                	ld	a3,0(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02016d8:	fe878513          	addi	a0,a5,-24
        if (page->property > n) {
ffffffffc02016dc:	02081313          	slli	t1,a6,0x20
    prev->next = next;
ffffffffc02016e0:	0116b423          	sd	a7,8(a3)
    next->prev = prev;
ffffffffc02016e4:	00d8b023          	sd	a3,0(a7)
ffffffffc02016e8:	02035313          	srli	t1,t1,0x20
            p->property = page->property - n;
ffffffffc02016ec:	0007089b          	sext.w	a7,a4
        if (page->property > n) {
ffffffffc02016f0:	02677963          	bgeu	a4,t1,ffffffffc0201722 <default_alloc_pages+0x82>
            struct Page *p = page + n;
ffffffffc02016f4:	071a                	slli	a4,a4,0x6
ffffffffc02016f6:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02016f8:	4118083b          	subw	a6,a6,a7
ffffffffc02016fc:	01072823          	sw	a6,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201700:	4589                	li	a1,2
ffffffffc0201702:	00870813          	addi	a6,a4,8
ffffffffc0201706:	40b8302f          	amoor.d	zero,a1,(a6)
    __list_add(elm, listelm, listelm->next);
ffffffffc020170a:	0086b803          	ld	a6,8(a3)
            list_add(prev, &(p->page_link));
ffffffffc020170e:	01870313          	addi	t1,a4,24
        nr_free -= n;
ffffffffc0201712:	4a0c                	lw	a1,16(a2)
    prev->next = next->prev = elm;
ffffffffc0201714:	00683023          	sd	t1,0(a6)
ffffffffc0201718:	0066b423          	sd	t1,8(a3)
    elm->next = next;
ffffffffc020171c:	03073023          	sd	a6,32(a4)
    elm->prev = prev;
ffffffffc0201720:	ef14                	sd	a3,24(a4)
ffffffffc0201722:	411585bb          	subw	a1,a1,a7
ffffffffc0201726:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201728:	5775                	li	a4,-3
ffffffffc020172a:	17c1                	addi	a5,a5,-16
ffffffffc020172c:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201730:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201732:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201734:	00003697          	auipc	a3,0x3
ffffffffc0201738:	45c68693          	addi	a3,a3,1116 # ffffffffc0204b90 <etext+0xd2e>
ffffffffc020173c:	00003617          	auipc	a2,0x3
ffffffffc0201740:	0fc60613          	addi	a2,a2,252 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201744:	06200593          	li	a1,98
ffffffffc0201748:	00003517          	auipc	a0,0x3
ffffffffc020174c:	10850513          	addi	a0,a0,264 # ffffffffc0204850 <etext+0x9ee>
default_alloc_pages(size_t n) {
ffffffffc0201750:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201752:	cf5fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201756 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201756:	1141                	addi	sp,sp,-16
ffffffffc0201758:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020175a:	c5f1                	beqz	a1,ffffffffc0201826 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc020175c:	00659713          	slli	a4,a1,0x6
ffffffffc0201760:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201764:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201766:	cf11                	beqz	a4,ffffffffc0201782 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201768:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020176a:	8b05                	andi	a4,a4,1
ffffffffc020176c:	cf49                	beqz	a4,ffffffffc0201806 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc020176e:	0007a823          	sw	zero,16(a5)
ffffffffc0201772:	0007b423          	sd	zero,8(a5)
ffffffffc0201776:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020177a:	04078793          	addi	a5,a5,64
ffffffffc020177e:	fed795e3          	bne	a5,a3,ffffffffc0201768 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201782:	2581                	sext.w	a1,a1
ffffffffc0201784:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201786:	4789                	li	a5,2
ffffffffc0201788:	00850713          	addi	a4,a0,8
ffffffffc020178c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201790:	00008697          	auipc	a3,0x8
ffffffffc0201794:	ca068693          	addi	a3,a3,-864 # ffffffffc0209430 <free_area>
ffffffffc0201798:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020179a:	669c                	ld	a5,8(a3)
ffffffffc020179c:	9f2d                	addw	a4,a4,a1
ffffffffc020179e:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02017a0:	04d78663          	beq	a5,a3,ffffffffc02017ec <default_init_memmap+0x96>
            struct Page* page = le2page(le, page_link);
ffffffffc02017a4:	fe878713          	addi	a4,a5,-24
ffffffffc02017a8:	4581                	li	a1,0
ffffffffc02017aa:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02017ae:	00e56a63          	bltu	a0,a4,ffffffffc02017c2 <default_init_memmap+0x6c>
    return listelm->next;
ffffffffc02017b2:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02017b4:	02d70263          	beq	a4,a3,ffffffffc02017d8 <default_init_memmap+0x82>
    struct Page *p = base;
ffffffffc02017b8:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02017ba:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02017be:	fee57ae3          	bgeu	a0,a4,ffffffffc02017b2 <default_init_memmap+0x5c>
ffffffffc02017c2:	c199                	beqz	a1,ffffffffc02017c8 <default_init_memmap+0x72>
ffffffffc02017c4:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017c8:	6398                	ld	a4,0(a5)
}
ffffffffc02017ca:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02017cc:	e390                	sd	a2,0(a5)
ffffffffc02017ce:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02017d0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017d2:	ed18                	sd	a4,24(a0)
ffffffffc02017d4:	0141                	addi	sp,sp,16
ffffffffc02017d6:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017d8:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017da:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017dc:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02017de:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02017e0:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02017e2:	00d70e63          	beq	a4,a3,ffffffffc02017fe <default_init_memmap+0xa8>
ffffffffc02017e6:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02017e8:	87ba                	mv	a5,a4
ffffffffc02017ea:	bfc1                	j	ffffffffc02017ba <default_init_memmap+0x64>
}
ffffffffc02017ec:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02017ee:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02017f2:	e398                	sd	a4,0(a5)
ffffffffc02017f4:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02017f6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017f8:	ed1c                	sd	a5,24(a0)
}
ffffffffc02017fa:	0141                	addi	sp,sp,16
ffffffffc02017fc:	8082                	ret
ffffffffc02017fe:	60a2                	ld	ra,8(sp)
ffffffffc0201800:	e290                	sd	a2,0(a3)
ffffffffc0201802:	0141                	addi	sp,sp,16
ffffffffc0201804:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201806:	00003697          	auipc	a3,0x3
ffffffffc020180a:	3ba68693          	addi	a3,a3,954 # ffffffffc0204bc0 <etext+0xd5e>
ffffffffc020180e:	00003617          	auipc	a2,0x3
ffffffffc0201812:	02a60613          	addi	a2,a2,42 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201816:	04900593          	li	a1,73
ffffffffc020181a:	00003517          	auipc	a0,0x3
ffffffffc020181e:	03650513          	addi	a0,a0,54 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201822:	c25fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201826:	00003697          	auipc	a3,0x3
ffffffffc020182a:	36a68693          	addi	a3,a3,874 # ffffffffc0204b90 <etext+0xd2e>
ffffffffc020182e:	00003617          	auipc	a2,0x3
ffffffffc0201832:	00a60613          	addi	a2,a2,10 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201836:	04600593          	li	a1,70
ffffffffc020183a:	00003517          	auipc	a0,0x3
ffffffffc020183e:	01650513          	addi	a0,a0,22 # ffffffffc0204850 <etext+0x9ee>
ffffffffc0201842:	c05fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201846 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201846:	cd49                	beqz	a0,ffffffffc02018e0 <slob_free+0x9a>
{
ffffffffc0201848:	1141                	addi	sp,sp,-16
ffffffffc020184a:	e022                	sd	s0,0(sp)
ffffffffc020184c:	e406                	sd	ra,8(sp)
ffffffffc020184e:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201850:	eda1                	bnez	a1,ffffffffc02018a8 <slob_free+0x62>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201852:	100027f3          	csrr	a5,sstatus
ffffffffc0201856:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201858:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020185a:	efb9                	bnez	a5,ffffffffc02018b8 <slob_free+0x72>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020185c:	00007617          	auipc	a2,0x7
ffffffffc0201860:	7c460613          	addi	a2,a2,1988 # ffffffffc0209020 <slobfree>
ffffffffc0201864:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201866:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201868:	0287fa63          	bgeu	a5,s0,ffffffffc020189c <slob_free+0x56>
ffffffffc020186c:	00e46463          	bltu	s0,a4,ffffffffc0201874 <slob_free+0x2e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201870:	02e7ea63          	bltu	a5,a4,ffffffffc02018a4 <slob_free+0x5e>
			break;

	if (b + b->units == cur->next)
ffffffffc0201874:	400c                	lw	a1,0(s0)
ffffffffc0201876:	00459693          	slli	a3,a1,0x4
ffffffffc020187a:	96a2                	add	a3,a3,s0
ffffffffc020187c:	04d70d63          	beq	a4,a3,ffffffffc02018d6 <slob_free+0x90>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201880:	438c                	lw	a1,0(a5)
ffffffffc0201882:	e418                	sd	a4,8(s0)
ffffffffc0201884:	00459693          	slli	a3,a1,0x4
ffffffffc0201888:	96be                	add	a3,a3,a5
ffffffffc020188a:	04d40063          	beq	s0,a3,ffffffffc02018ca <slob_free+0x84>
ffffffffc020188e:	e780                	sd	s0,8(a5)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc0201890:	e21c                	sd	a5,0(a2)
    if (flag) {
ffffffffc0201892:	e51d                	bnez	a0,ffffffffc02018c0 <slob_free+0x7a>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201894:	60a2                	ld	ra,8(sp)
ffffffffc0201896:	6402                	ld	s0,0(sp)
ffffffffc0201898:	0141                	addi	sp,sp,16
ffffffffc020189a:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020189c:	00e7e463          	bltu	a5,a4,ffffffffc02018a4 <slob_free+0x5e>
ffffffffc02018a0:	fce46ae3          	bltu	s0,a4,ffffffffc0201874 <slob_free+0x2e>
        return 1;
ffffffffc02018a4:	87ba                	mv	a5,a4
ffffffffc02018a6:	b7c1                	j	ffffffffc0201866 <slob_free+0x20>
		b->units = SLOB_UNITS(size);
ffffffffc02018a8:	25bd                	addiw	a1,a1,15
ffffffffc02018aa:	8191                	srli	a1,a1,0x4
ffffffffc02018ac:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018ae:	100027f3          	csrr	a5,sstatus
ffffffffc02018b2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02018b4:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018b6:	d3dd                	beqz	a5,ffffffffc020185c <slob_free+0x16>
        intr_disable();
ffffffffc02018b8:	832ff0ef          	jal	ffffffffc02008ea <intr_disable>
        return 1;
ffffffffc02018bc:	4505                	li	a0,1
ffffffffc02018be:	bf79                	j	ffffffffc020185c <slob_free+0x16>
}
ffffffffc02018c0:	6402                	ld	s0,0(sp)
ffffffffc02018c2:	60a2                	ld	ra,8(sp)
ffffffffc02018c4:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02018c6:	81eff06f          	j	ffffffffc02008e4 <intr_enable>
		cur->units += b->units;
ffffffffc02018ca:	4014                	lw	a3,0(s0)
		cur->next = b->next;
ffffffffc02018cc:	843a                	mv	s0,a4
		cur->units += b->units;
ffffffffc02018ce:	00b6873b          	addw	a4,a3,a1
ffffffffc02018d2:	c398                	sw	a4,0(a5)
		cur->next = b->next;
ffffffffc02018d4:	bf6d                	j	ffffffffc020188e <slob_free+0x48>
		b->units += cur->next->units;
ffffffffc02018d6:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02018d8:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc02018da:	9ead                	addw	a3,a3,a1
ffffffffc02018dc:	c014                	sw	a3,0(s0)
		b->next = cur->next->next;
ffffffffc02018de:	b74d                	j	ffffffffc0201880 <slob_free+0x3a>
ffffffffc02018e0:	8082                	ret

ffffffffc02018e2 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc02018e2:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02018e4:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc02018e6:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02018ea:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc02018ec:	348000ef          	jal	ffffffffc0201c34 <alloc_pages>
	if (!page)
ffffffffc02018f0:	c91d                	beqz	a0,ffffffffc0201926 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc02018f2:	0000c797          	auipc	a5,0xc
ffffffffc02018f6:	bd67b783          	ld	a5,-1066(a5) # ffffffffc020d4c8 <pages>
ffffffffc02018fa:	8d1d                	sub	a0,a0,a5
ffffffffc02018fc:	8519                	srai	a0,a0,0x6
ffffffffc02018fe:	00004797          	auipc	a5,0x4
ffffffffc0201902:	0ba7b783          	ld	a5,186(a5) # ffffffffc02059b8 <nbase>
ffffffffc0201906:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201908:	00c51793          	slli	a5,a0,0xc
ffffffffc020190c:	83b1                	srli	a5,a5,0xc
ffffffffc020190e:	0000c717          	auipc	a4,0xc
ffffffffc0201912:	bb273703          	ld	a4,-1102(a4) # ffffffffc020d4c0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201916:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201918:	00e7fa63          	bgeu	a5,a4,ffffffffc020192c <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc020191c:	0000c797          	auipc	a5,0xc
ffffffffc0201920:	b9c7b783          	ld	a5,-1124(a5) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201924:	953e                	add	a0,a0,a5
}
ffffffffc0201926:	60a2                	ld	ra,8(sp)
ffffffffc0201928:	0141                	addi	sp,sp,16
ffffffffc020192a:	8082                	ret
ffffffffc020192c:	86aa                	mv	a3,a0
ffffffffc020192e:	00003617          	auipc	a2,0x3
ffffffffc0201932:	2ba60613          	addi	a2,a2,698 # ffffffffc0204be8 <etext+0xd86>
ffffffffc0201936:	07100593          	li	a1,113
ffffffffc020193a:	00003517          	auipc	a0,0x3
ffffffffc020193e:	2d650513          	addi	a0,a0,726 # ffffffffc0204c10 <etext+0xdae>
ffffffffc0201942:	b05fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201946 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201946:	1101                	addi	sp,sp,-32
ffffffffc0201948:	ec06                	sd	ra,24(sp)
ffffffffc020194a:	e822                	sd	s0,16(sp)
ffffffffc020194c:	e426                	sd	s1,8(sp)
ffffffffc020194e:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201950:	01050713          	addi	a4,a0,16
ffffffffc0201954:	6785                	lui	a5,0x1
ffffffffc0201956:	0cf77363          	bgeu	a4,a5,ffffffffc0201a1c <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc020195a:	00f50493          	addi	s1,a0,15
ffffffffc020195e:	8091                	srli	s1,s1,0x4
ffffffffc0201960:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201962:	10002673          	csrr	a2,sstatus
ffffffffc0201966:	8a09                	andi	a2,a2,2
ffffffffc0201968:	e25d                	bnez	a2,ffffffffc0201a0e <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc020196a:	00007917          	auipc	s2,0x7
ffffffffc020196e:	6b690913          	addi	s2,s2,1718 # ffffffffc0209020 <slobfree>
ffffffffc0201972:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201976:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201978:	4398                	lw	a4,0(a5)
ffffffffc020197a:	08975e63          	bge	a4,s1,ffffffffc0201a16 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc020197e:	00f68b63          	beq	a3,a5,ffffffffc0201994 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201982:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201984:	4018                	lw	a4,0(s0)
ffffffffc0201986:	02975a63          	bge	a4,s1,ffffffffc02019ba <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc020198a:	00093683          	ld	a3,0(s2)
ffffffffc020198e:	87a2                	mv	a5,s0
ffffffffc0201990:	fef699e3          	bne	a3,a5,ffffffffc0201982 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc0201994:	ee31                	bnez	a2,ffffffffc02019f0 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201996:	4501                	li	a0,0
ffffffffc0201998:	f4bff0ef          	jal	ffffffffc02018e2 <__slob_get_free_pages.constprop.0>
ffffffffc020199c:	842a                	mv	s0,a0
			if (!cur)
ffffffffc020199e:	cd05                	beqz	a0,ffffffffc02019d6 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc02019a0:	6585                	lui	a1,0x1
ffffffffc02019a2:	ea5ff0ef          	jal	ffffffffc0201846 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019a6:	10002673          	csrr	a2,sstatus
ffffffffc02019aa:	8a09                	andi	a2,a2,2
ffffffffc02019ac:	ee05                	bnez	a2,ffffffffc02019e4 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc02019ae:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019b2:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc02019b4:	4018                	lw	a4,0(s0)
ffffffffc02019b6:	fc974ae3          	blt	a4,s1,ffffffffc020198a <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc02019ba:	04e48763          	beq	s1,a4,ffffffffc0201a08 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc02019be:	00449693          	slli	a3,s1,0x4
ffffffffc02019c2:	96a2                	add	a3,a3,s0
ffffffffc02019c4:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc02019c6:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc02019c8:	9f05                	subw	a4,a4,s1
ffffffffc02019ca:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc02019cc:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc02019ce:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc02019d0:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc02019d4:	e20d                	bnez	a2,ffffffffc02019f6 <slob_alloc.constprop.0+0xb0>
}
ffffffffc02019d6:	60e2                	ld	ra,24(sp)
ffffffffc02019d8:	8522                	mv	a0,s0
ffffffffc02019da:	6442                	ld	s0,16(sp)
ffffffffc02019dc:	64a2                	ld	s1,8(sp)
ffffffffc02019de:	6902                	ld	s2,0(sp)
ffffffffc02019e0:	6105                	addi	sp,sp,32
ffffffffc02019e2:	8082                	ret
        intr_disable();
ffffffffc02019e4:	f07fe0ef          	jal	ffffffffc02008ea <intr_disable>
			cur = slobfree;
ffffffffc02019e8:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc02019ec:	4605                	li	a2,1
ffffffffc02019ee:	b7d1                	j	ffffffffc02019b2 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc02019f0:	ef5fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc02019f4:	b74d                	j	ffffffffc0201996 <slob_alloc.constprop.0+0x50>
ffffffffc02019f6:	eeffe0ef          	jal	ffffffffc02008e4 <intr_enable>
}
ffffffffc02019fa:	60e2                	ld	ra,24(sp)
ffffffffc02019fc:	8522                	mv	a0,s0
ffffffffc02019fe:	6442                	ld	s0,16(sp)
ffffffffc0201a00:	64a2                	ld	s1,8(sp)
ffffffffc0201a02:	6902                	ld	s2,0(sp)
ffffffffc0201a04:	6105                	addi	sp,sp,32
ffffffffc0201a06:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a08:	6418                	ld	a4,8(s0)
ffffffffc0201a0a:	e798                	sd	a4,8(a5)
ffffffffc0201a0c:	b7d1                	j	ffffffffc02019d0 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201a0e:	eddfe0ef          	jal	ffffffffc02008ea <intr_disable>
        return 1;
ffffffffc0201a12:	4605                	li	a2,1
ffffffffc0201a14:	bf99                	j	ffffffffc020196a <slob_alloc.constprop.0+0x24>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a16:	843e                	mv	s0,a5
	prev = slobfree;
ffffffffc0201a18:	87b6                	mv	a5,a3
ffffffffc0201a1a:	b745                	j	ffffffffc02019ba <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a1c:	00003697          	auipc	a3,0x3
ffffffffc0201a20:	20468693          	addi	a3,a3,516 # ffffffffc0204c20 <etext+0xdbe>
ffffffffc0201a24:	00003617          	auipc	a2,0x3
ffffffffc0201a28:	e1460613          	addi	a2,a2,-492 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0201a2c:	06300593          	li	a1,99
ffffffffc0201a30:	00003517          	auipc	a0,0x3
ffffffffc0201a34:	21050513          	addi	a0,a0,528 # ffffffffc0204c40 <etext+0xdde>
ffffffffc0201a38:	a0ffe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201a3c <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201a3c:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201a3e:	00003517          	auipc	a0,0x3
ffffffffc0201a42:	21a50513          	addi	a0,a0,538 # ffffffffc0204c58 <etext+0xdf6>
{
ffffffffc0201a46:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201a48:	f4cfe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201a4c:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a4e:	00003517          	auipc	a0,0x3
ffffffffc0201a52:	22250513          	addi	a0,a0,546 # ffffffffc0204c70 <etext+0xe0e>
}
ffffffffc0201a56:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a58:	f3cfe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201a5c <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201a5c:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201a5e:	6785                	lui	a5,0x1
{
ffffffffc0201a60:	e822                	sd	s0,16(sp)
ffffffffc0201a62:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201a64:	17bd                	addi	a5,a5,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0201a66:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201a68:	04a7fa63          	bgeu	a5,a0,ffffffffc0201abc <kmalloc+0x60>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201a6c:	4561                	li	a0,24
ffffffffc0201a6e:	e426                	sd	s1,8(sp)
ffffffffc0201a70:	ed7ff0ef          	jal	ffffffffc0201946 <slob_alloc.constprop.0>
ffffffffc0201a74:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201a76:	c549                	beqz	a0,ffffffffc0201b00 <kmalloc+0xa4>
ffffffffc0201a78:	e04a                	sd	s2,0(sp)
	bb->order = find_order(size);
ffffffffc0201a7a:	0004079b          	sext.w	a5,s0
ffffffffc0201a7e:	6905                	lui	s2,0x1
	int order = 0;
ffffffffc0201a80:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201a82:	00f95763          	bge	s2,a5,ffffffffc0201a90 <kmalloc+0x34>
ffffffffc0201a86:	6705                	lui	a4,0x1
ffffffffc0201a88:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201a8a:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201a8c:	fef74ee3          	blt	a4,a5,ffffffffc0201a88 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201a90:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201a92:	e51ff0ef          	jal	ffffffffc02018e2 <__slob_get_free_pages.constprop.0>
ffffffffc0201a96:	e488                	sd	a0,8(s1)
	if (bb->pages)
ffffffffc0201a98:	cd21                	beqz	a0,ffffffffc0201af0 <kmalloc+0x94>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a9a:	100027f3          	csrr	a5,sstatus
ffffffffc0201a9e:	8b89                	andi	a5,a5,2
ffffffffc0201aa0:	e795                	bnez	a5,ffffffffc0201acc <kmalloc+0x70>
		bb->next = bigblocks;
ffffffffc0201aa2:	0000c797          	auipc	a5,0xc
ffffffffc0201aa6:	9f678793          	addi	a5,a5,-1546 # ffffffffc020d498 <bigblocks>
ffffffffc0201aaa:	6398                	ld	a4,0(a5)
ffffffffc0201aac:	6902                	ld	s2,0(sp)
		bigblocks = bb;
ffffffffc0201aae:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201ab0:	e898                	sd	a4,16(s1)
    if (flag) {
ffffffffc0201ab2:	64a2                	ld	s1,8(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201ab4:	60e2                	ld	ra,24(sp)
ffffffffc0201ab6:	6442                	ld	s0,16(sp)
ffffffffc0201ab8:	6105                	addi	sp,sp,32
ffffffffc0201aba:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201abc:	0541                	addi	a0,a0,16
ffffffffc0201abe:	e89ff0ef          	jal	ffffffffc0201946 <slob_alloc.constprop.0>
ffffffffc0201ac2:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201ac4:	0541                	addi	a0,a0,16
ffffffffc0201ac6:	f7fd                	bnez	a5,ffffffffc0201ab4 <kmalloc+0x58>
		return 0;
ffffffffc0201ac8:	4501                	li	a0,0
	return __kmalloc(size, 0);
ffffffffc0201aca:	b7ed                	j	ffffffffc0201ab4 <kmalloc+0x58>
        intr_disable();
ffffffffc0201acc:	e1ffe0ef          	jal	ffffffffc02008ea <intr_disable>
		bb->next = bigblocks;
ffffffffc0201ad0:	0000c797          	auipc	a5,0xc
ffffffffc0201ad4:	9c878793          	addi	a5,a5,-1592 # ffffffffc020d498 <bigblocks>
ffffffffc0201ad8:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201ada:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201adc:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201ade:	e07fe0ef          	jal	ffffffffc02008e4 <intr_enable>
}
ffffffffc0201ae2:	60e2                	ld	ra,24(sp)
ffffffffc0201ae4:	6442                	ld	s0,16(sp)
		return bb->pages;
ffffffffc0201ae6:	6488                	ld	a0,8(s1)
ffffffffc0201ae8:	6902                	ld	s2,0(sp)
ffffffffc0201aea:	64a2                	ld	s1,8(sp)
}
ffffffffc0201aec:	6105                	addi	sp,sp,32
ffffffffc0201aee:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201af0:	8526                	mv	a0,s1
ffffffffc0201af2:	45e1                	li	a1,24
ffffffffc0201af4:	d53ff0ef          	jal	ffffffffc0201846 <slob_free>
		return 0;
ffffffffc0201af8:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201afa:	64a2                	ld	s1,8(sp)
ffffffffc0201afc:	6902                	ld	s2,0(sp)
ffffffffc0201afe:	bf5d                	j	ffffffffc0201ab4 <kmalloc+0x58>
ffffffffc0201b00:	64a2                	ld	s1,8(sp)
		return 0;
ffffffffc0201b02:	4501                	li	a0,0
ffffffffc0201b04:	bf45                	j	ffffffffc0201ab4 <kmalloc+0x58>

ffffffffc0201b06 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b06:	c169                	beqz	a0,ffffffffc0201bc8 <kfree+0xc2>
{
ffffffffc0201b08:	1101                	addi	sp,sp,-32
ffffffffc0201b0a:	e822                	sd	s0,16(sp)
ffffffffc0201b0c:	ec06                	sd	ra,24(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201b0e:	03451793          	slli	a5,a0,0x34
ffffffffc0201b12:	842a                	mv	s0,a0
ffffffffc0201b14:	e7c9                	bnez	a5,ffffffffc0201b9e <kfree+0x98>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b16:	100027f3          	csrr	a5,sstatus
ffffffffc0201b1a:	8b89                	andi	a5,a5,2
ffffffffc0201b1c:	ebc1                	bnez	a5,ffffffffc0201bac <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b1e:	0000c797          	auipc	a5,0xc
ffffffffc0201b22:	97a7b783          	ld	a5,-1670(a5) # ffffffffc020d498 <bigblocks>
    return 0;
ffffffffc0201b26:	4601                	li	a2,0
ffffffffc0201b28:	cbbd                	beqz	a5,ffffffffc0201b9e <kfree+0x98>
ffffffffc0201b2a:	e426                	sd	s1,8(sp)
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b2c:	0000c697          	auipc	a3,0xc
ffffffffc0201b30:	96c68693          	addi	a3,a3,-1684 # ffffffffc020d498 <bigblocks>
ffffffffc0201b34:	a021                	j	ffffffffc0201b3c <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b36:	01048693          	addi	a3,s1,16
ffffffffc0201b3a:	c3a5                	beqz	a5,ffffffffc0201b9a <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201b3c:	6798                	ld	a4,8(a5)
ffffffffc0201b3e:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201b40:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201b42:	fe871ae3          	bne	a4,s0,ffffffffc0201b36 <kfree+0x30>
				*last = bb->next;
ffffffffc0201b46:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201b48:	ee2d                	bnez	a2,ffffffffc0201bc2 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201b4a:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201b4e:	4098                	lw	a4,0(s1)
ffffffffc0201b50:	08f46963          	bltu	s0,a5,ffffffffc0201be2 <kfree+0xdc>
ffffffffc0201b54:	0000c797          	auipc	a5,0xc
ffffffffc0201b58:	9647b783          	ld	a5,-1692(a5) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201b5c:	8c1d                	sub	s0,s0,a5
    if (PPN(pa) >= npage)
ffffffffc0201b5e:	8031                	srli	s0,s0,0xc
ffffffffc0201b60:	0000c797          	auipc	a5,0xc
ffffffffc0201b64:	9607b783          	ld	a5,-1696(a5) # ffffffffc020d4c0 <npage>
ffffffffc0201b68:	06f47163          	bgeu	s0,a5,ffffffffc0201bca <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b6c:	00004797          	auipc	a5,0x4
ffffffffc0201b70:	e4c7b783          	ld	a5,-436(a5) # ffffffffc02059b8 <nbase>
ffffffffc0201b74:	8c1d                	sub	s0,s0,a5
ffffffffc0201b76:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201b78:	0000c517          	auipc	a0,0xc
ffffffffc0201b7c:	95053503          	ld	a0,-1712(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201b80:	4585                	li	a1,1
ffffffffc0201b82:	9522                	add	a0,a0,s0
ffffffffc0201b84:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201b88:	0ea000ef          	jal	ffffffffc0201c72 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201b8c:	6442                	ld	s0,16(sp)
ffffffffc0201b8e:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b90:	8526                	mv	a0,s1
ffffffffc0201b92:	64a2                	ld	s1,8(sp)
ffffffffc0201b94:	45e1                	li	a1,24
}
ffffffffc0201b96:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201b98:	b17d                	j	ffffffffc0201846 <slob_free>
ffffffffc0201b9a:	64a2                	ld	s1,8(sp)
ffffffffc0201b9c:	e205                	bnez	a2,ffffffffc0201bbc <kfree+0xb6>
ffffffffc0201b9e:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201ba2:	6442                	ld	s0,16(sp)
ffffffffc0201ba4:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ba6:	4581                	li	a1,0
}
ffffffffc0201ba8:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201baa:	b971                	j	ffffffffc0201846 <slob_free>
        intr_disable();
ffffffffc0201bac:	d3ffe0ef          	jal	ffffffffc02008ea <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201bb0:	0000c797          	auipc	a5,0xc
ffffffffc0201bb4:	8e87b783          	ld	a5,-1816(a5) # ffffffffc020d498 <bigblocks>
        return 1;
ffffffffc0201bb8:	4605                	li	a2,1
ffffffffc0201bba:	fba5                	bnez	a5,ffffffffc0201b2a <kfree+0x24>
        intr_enable();
ffffffffc0201bbc:	d29fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc0201bc0:	bff9                	j	ffffffffc0201b9e <kfree+0x98>
ffffffffc0201bc2:	d23fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc0201bc6:	b751                	j	ffffffffc0201b4a <kfree+0x44>
ffffffffc0201bc8:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201bca:	00003617          	auipc	a2,0x3
ffffffffc0201bce:	0ee60613          	addi	a2,a2,238 # ffffffffc0204cb8 <etext+0xe56>
ffffffffc0201bd2:	06900593          	li	a1,105
ffffffffc0201bd6:	00003517          	auipc	a0,0x3
ffffffffc0201bda:	03a50513          	addi	a0,a0,58 # ffffffffc0204c10 <etext+0xdae>
ffffffffc0201bde:	869fe0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201be2:	86a2                	mv	a3,s0
ffffffffc0201be4:	00003617          	auipc	a2,0x3
ffffffffc0201be8:	0ac60613          	addi	a2,a2,172 # ffffffffc0204c90 <etext+0xe2e>
ffffffffc0201bec:	07700593          	li	a1,119
ffffffffc0201bf0:	00003517          	auipc	a0,0x3
ffffffffc0201bf4:	02050513          	addi	a0,a0,32 # ffffffffc0204c10 <etext+0xdae>
ffffffffc0201bf8:	84ffe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201bfc <pa2page.part.0>:

    uint64_t mem_begin = get_memory_base();
    uint64_t mem_size  = get_memory_size();
    if (mem_size == 0) {
        panic("DTB memory info not available");
    }
ffffffffc0201bfc:	1141                	addi	sp,sp,-16
    uint64_t mem_end   = mem_begin + mem_size;

    cprintf("physcial memory map:\n");
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201bfe:	00003617          	auipc	a2,0x3
ffffffffc0201c02:	0ba60613          	addi	a2,a2,186 # ffffffffc0204cb8 <etext+0xe56>
ffffffffc0201c06:	06900593          	li	a1,105
ffffffffc0201c0a:	00003517          	auipc	a0,0x3
ffffffffc0201c0e:	00650513          	addi	a0,a0,6 # ffffffffc0204c10 <etext+0xdae>
    }
ffffffffc0201c12:	e406                	sd	ra,8(sp)
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201c14:	833fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201c18 <pte2page.part.0>:
    // BBL has put the initial page table at the first available page after the
    // kernel
    // so stay away from it by adding extra offset to end
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201c18:	1141                	addi	sp,sp,-16
    {
        SetPageReserved(pages + i);
    }

ffffffffc0201c1a:	00003617          	auipc	a2,0x3
ffffffffc0201c1e:	0be60613          	addi	a2,a2,190 # ffffffffc0204cd8 <etext+0xe76>
ffffffffc0201c22:	07f00593          	li	a1,127
ffffffffc0201c26:	00003517          	auipc	a0,0x3
ffffffffc0201c2a:	fea50513          	addi	a0,a0,-22 # ffffffffc0204c10 <etext+0xdae>
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201c2e:	e406                	sd	ra,8(sp)

ffffffffc0201c30:	817fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201c34 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c34:	100027f3          	csrr	a5,sstatus
ffffffffc0201c38:	8b89                	andi	a5,a5,2
ffffffffc0201c3a:	e799                	bnez	a5,ffffffffc0201c48 <alloc_pages+0x14>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c3c:	0000c797          	auipc	a5,0xc
ffffffffc0201c40:	8647b783          	ld	a5,-1948(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201c44:	6f9c                	ld	a5,24(a5)
ffffffffc0201c46:	8782                	jr	a5
{
ffffffffc0201c48:	1141                	addi	sp,sp,-16
ffffffffc0201c4a:	e406                	sd	ra,8(sp)
ffffffffc0201c4c:	e022                	sd	s0,0(sp)
ffffffffc0201c4e:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201c50:	c9bfe0ef          	jal	ffffffffc02008ea <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c54:	0000c797          	auipc	a5,0xc
ffffffffc0201c58:	84c7b783          	ld	a5,-1972(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201c5c:	6f9c                	ld	a5,24(a5)
ffffffffc0201c5e:	8522                	mv	a0,s0
ffffffffc0201c60:	9782                	jalr	a5
ffffffffc0201c62:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201c64:	c81fe0ef          	jal	ffffffffc02008e4 <intr_enable>
}
ffffffffc0201c68:	60a2                	ld	ra,8(sp)
ffffffffc0201c6a:	8522                	mv	a0,s0
ffffffffc0201c6c:	6402                	ld	s0,0(sp)
ffffffffc0201c6e:	0141                	addi	sp,sp,16
ffffffffc0201c70:	8082                	ret

ffffffffc0201c72 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c72:	100027f3          	csrr	a5,sstatus
ffffffffc0201c76:	8b89                	andi	a5,a5,2
ffffffffc0201c78:	e799                	bnez	a5,ffffffffc0201c86 <free_pages+0x14>
        pmm_manager->free_pages(base, n);
ffffffffc0201c7a:	0000c797          	auipc	a5,0xc
ffffffffc0201c7e:	8267b783          	ld	a5,-2010(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201c82:	739c                	ld	a5,32(a5)
ffffffffc0201c84:	8782                	jr	a5
{
ffffffffc0201c86:	1101                	addi	sp,sp,-32
ffffffffc0201c88:	ec06                	sd	ra,24(sp)
ffffffffc0201c8a:	e822                	sd	s0,16(sp)
ffffffffc0201c8c:	e426                	sd	s1,8(sp)
ffffffffc0201c8e:	842a                	mv	s0,a0
ffffffffc0201c90:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201c92:	c59fe0ef          	jal	ffffffffc02008ea <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201c96:	0000c797          	auipc	a5,0xc
ffffffffc0201c9a:	80a7b783          	ld	a5,-2038(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201c9e:	739c                	ld	a5,32(a5)
ffffffffc0201ca0:	85a6                	mv	a1,s1
ffffffffc0201ca2:	8522                	mv	a0,s0
ffffffffc0201ca4:	9782                	jalr	a5
}
ffffffffc0201ca6:	6442                	ld	s0,16(sp)
ffffffffc0201ca8:	60e2                	ld	ra,24(sp)
ffffffffc0201caa:	64a2                	ld	s1,8(sp)
ffffffffc0201cac:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201cae:	c37fe06f          	j	ffffffffc02008e4 <intr_enable>

ffffffffc0201cb2 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201cb2:	100027f3          	csrr	a5,sstatus
ffffffffc0201cb6:	8b89                	andi	a5,a5,2
ffffffffc0201cb8:	e799                	bnez	a5,ffffffffc0201cc6 <nr_free_pages+0x14>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201cba:	0000b797          	auipc	a5,0xb
ffffffffc0201cbe:	7e67b783          	ld	a5,2022(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201cc2:	779c                	ld	a5,40(a5)
ffffffffc0201cc4:	8782                	jr	a5
{
ffffffffc0201cc6:	1141                	addi	sp,sp,-16
ffffffffc0201cc8:	e406                	sd	ra,8(sp)
ffffffffc0201cca:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201ccc:	c1ffe0ef          	jal	ffffffffc02008ea <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201cd0:	0000b797          	auipc	a5,0xb
ffffffffc0201cd4:	7d07b783          	ld	a5,2000(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201cd8:	779c                	ld	a5,40(a5)
ffffffffc0201cda:	9782                	jalr	a5
ffffffffc0201cdc:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201cde:	c07fe0ef          	jal	ffffffffc02008e4 <intr_enable>
}
ffffffffc0201ce2:	60a2                	ld	ra,8(sp)
ffffffffc0201ce4:	8522                	mv	a0,s0
ffffffffc0201ce6:	6402                	ld	s0,0(sp)
ffffffffc0201ce8:	0141                	addi	sp,sp,16
ffffffffc0201cea:	8082                	ret

ffffffffc0201cec <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201cec:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201cf0:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201cf4:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201cf6:	078e                	slli	a5,a5,0x3
{
ffffffffc0201cf8:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201cfa:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201cfe:	6094                	ld	a3,0(s1)
{
ffffffffc0201d00:	f04a                	sd	s2,32(sp)
ffffffffc0201d02:	ec4e                	sd	s3,24(sp)
ffffffffc0201d04:	e852                	sd	s4,16(sp)
ffffffffc0201d06:	fc06                	sd	ra,56(sp)
ffffffffc0201d08:	f822                	sd	s0,48(sp)
ffffffffc0201d0a:	e456                	sd	s5,8(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201d0c:	0016f793          	andi	a5,a3,1
{
ffffffffc0201d10:	892e                	mv	s2,a1
ffffffffc0201d12:	8a32                	mv	s4,a2
ffffffffc0201d14:	0000b997          	auipc	s3,0xb
ffffffffc0201d18:	7ac98993          	addi	s3,s3,1964 # ffffffffc020d4c0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201d1c:	e3c9                	bnez	a5,ffffffffc0201d9e <get_pte+0xb2>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d1e:	14060f63          	beqz	a2,ffffffffc0201e7c <get_pte+0x190>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d22:	100027f3          	csrr	a5,sstatus
ffffffffc0201d26:	8b89                	andi	a5,a5,2
ffffffffc0201d28:	14079c63          	bnez	a5,ffffffffc0201e80 <get_pte+0x194>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d2c:	0000b797          	auipc	a5,0xb
ffffffffc0201d30:	7747b783          	ld	a5,1908(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201d34:	6f9c                	ld	a5,24(a5)
ffffffffc0201d36:	4505                	li	a0,1
ffffffffc0201d38:	9782                	jalr	a5
ffffffffc0201d3a:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d3c:	14040063          	beqz	s0,ffffffffc0201e7c <get_pte+0x190>
    page->ref = val;
ffffffffc0201d40:	e05a                	sd	s6,0(sp)
    return page - pages + nbase;
ffffffffc0201d42:	0000bb17          	auipc	s6,0xb
ffffffffc0201d46:	786b0b13          	addi	s6,s6,1926 # ffffffffc020d4c8 <pages>
ffffffffc0201d4a:	000b3503          	ld	a0,0(s6)
ffffffffc0201d4e:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201d52:	0000b997          	auipc	s3,0xb
ffffffffc0201d56:	76e98993          	addi	s3,s3,1902 # ffffffffc020d4c0 <npage>
ffffffffc0201d5a:	40a40533          	sub	a0,s0,a0
ffffffffc0201d5e:	8519                	srai	a0,a0,0x6
ffffffffc0201d60:	9556                	add	a0,a0,s5
ffffffffc0201d62:	0009b703          	ld	a4,0(s3)
ffffffffc0201d66:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201d6a:	4685                	li	a3,1
ffffffffc0201d6c:	c014                	sw	a3,0(s0)
ffffffffc0201d6e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d70:	0532                	slli	a0,a0,0xc
ffffffffc0201d72:	16e7fb63          	bgeu	a5,a4,ffffffffc0201ee8 <get_pte+0x1fc>
ffffffffc0201d76:	0000b797          	auipc	a5,0xb
ffffffffc0201d7a:	7427b783          	ld	a5,1858(a5) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201d7e:	953e                	add	a0,a0,a5
ffffffffc0201d80:	6605                	lui	a2,0x1
ffffffffc0201d82:	4581                	li	a1,0
ffffffffc0201d84:	090020ef          	jal	ffffffffc0203e14 <memset>
    return page - pages + nbase;
ffffffffc0201d88:	000b3783          	ld	a5,0(s6)
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201d8c:	6b02                	ld	s6,0(sp)
ffffffffc0201d8e:	40f406b3          	sub	a3,s0,a5
ffffffffc0201d92:	8699                	srai	a3,a3,0x6
ffffffffc0201d94:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201d96:	06aa                	slli	a3,a3,0xa
ffffffffc0201d98:	0116e693          	ori	a3,a3,17
ffffffffc0201d9c:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201d9e:	77fd                	lui	a5,0xfffff
ffffffffc0201da0:	068a                	slli	a3,a3,0x2
ffffffffc0201da2:	0009b703          	ld	a4,0(s3)
ffffffffc0201da6:	8efd                	and	a3,a3,a5
ffffffffc0201da8:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201dac:	12e7f163          	bgeu	a5,a4,ffffffffc0201ece <get_pte+0x1e2>
ffffffffc0201db0:	0000ba97          	auipc	s5,0xb
ffffffffc0201db4:	708a8a93          	addi	s5,s5,1800 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201db8:	000ab603          	ld	a2,0(s5)
ffffffffc0201dbc:	01595793          	srli	a5,s2,0x15
ffffffffc0201dc0:	1ff7f793          	andi	a5,a5,511
ffffffffc0201dc4:	96b2                	add	a3,a3,a2
ffffffffc0201dc6:	078e                	slli	a5,a5,0x3
ffffffffc0201dc8:	00f68433          	add	s0,a3,a5
    if (!(*pdep0 & PTE_V))
ffffffffc0201dcc:	6014                	ld	a3,0(s0)
ffffffffc0201dce:	0016f793          	andi	a5,a3,1
ffffffffc0201dd2:	ebbd                	bnez	a5,ffffffffc0201e48 <get_pte+0x15c>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201dd4:	0a0a0463          	beqz	s4,ffffffffc0201e7c <get_pte+0x190>
ffffffffc0201dd8:	100027f3          	csrr	a5,sstatus
ffffffffc0201ddc:	8b89                	andi	a5,a5,2
ffffffffc0201dde:	efd5                	bnez	a5,ffffffffc0201e9a <get_pte+0x1ae>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201de0:	0000b797          	auipc	a5,0xb
ffffffffc0201de4:	6c07b783          	ld	a5,1728(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201de8:	6f9c                	ld	a5,24(a5)
ffffffffc0201dea:	4505                	li	a0,1
ffffffffc0201dec:	9782                	jalr	a5
ffffffffc0201dee:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201df0:	c4d1                	beqz	s1,ffffffffc0201e7c <get_pte+0x190>
    page->ref = val;
ffffffffc0201df2:	e05a                	sd	s6,0(sp)
    return page - pages + nbase;
ffffffffc0201df4:	0000bb17          	auipc	s6,0xb
ffffffffc0201df8:	6d4b0b13          	addi	s6,s6,1748 # ffffffffc020d4c8 <pages>
ffffffffc0201dfc:	000b3683          	ld	a3,0(s6)
ffffffffc0201e00:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e04:	0009b703          	ld	a4,0(s3)
ffffffffc0201e08:	40d486b3          	sub	a3,s1,a3
ffffffffc0201e0c:	8699                	srai	a3,a3,0x6
ffffffffc0201e0e:	96d2                	add	a3,a3,s4
ffffffffc0201e10:	00c69793          	slli	a5,a3,0xc
    page->ref = val;
ffffffffc0201e14:	4605                	li	a2,1
ffffffffc0201e16:	c090                	sw	a2,0(s1)
ffffffffc0201e18:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e1a:	06b2                	slli	a3,a3,0xc
ffffffffc0201e1c:	0ee7f363          	bgeu	a5,a4,ffffffffc0201f02 <get_pte+0x216>
ffffffffc0201e20:	000ab503          	ld	a0,0(s5)
ffffffffc0201e24:	6605                	lui	a2,0x1
ffffffffc0201e26:	4581                	li	a1,0
ffffffffc0201e28:	9536                	add	a0,a0,a3
ffffffffc0201e2a:	7eb010ef          	jal	ffffffffc0203e14 <memset>
    return page - pages + nbase;
ffffffffc0201e2e:	000b3783          	ld	a5,0(s6)
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e32:	6b02                	ld	s6,0(sp)
ffffffffc0201e34:	40f486b3          	sub	a3,s1,a5
ffffffffc0201e38:	8699                	srai	a3,a3,0x6
ffffffffc0201e3a:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e3c:	06aa                	slli	a3,a3,0xa
ffffffffc0201e3e:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e42:	e014                	sd	a3,0(s0)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e44:	0009b703          	ld	a4,0(s3)
ffffffffc0201e48:	77fd                	lui	a5,0xfffff
ffffffffc0201e4a:	068a                	slli	a3,a3,0x2
ffffffffc0201e4c:	8efd                	and	a3,a3,a5
ffffffffc0201e4e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e52:	06e7f163          	bgeu	a5,a4,ffffffffc0201eb4 <get_pte+0x1c8>
ffffffffc0201e56:	000ab783          	ld	a5,0(s5)
ffffffffc0201e5a:	00c95913          	srli	s2,s2,0xc
ffffffffc0201e5e:	1ff97913          	andi	s2,s2,511
ffffffffc0201e62:	96be                	add	a3,a3,a5
ffffffffc0201e64:	090e                	slli	s2,s2,0x3
ffffffffc0201e66:	01268533          	add	a0,a3,s2
}
ffffffffc0201e6a:	70e2                	ld	ra,56(sp)
ffffffffc0201e6c:	7442                	ld	s0,48(sp)
ffffffffc0201e6e:	74a2                	ld	s1,40(sp)
ffffffffc0201e70:	7902                	ld	s2,32(sp)
ffffffffc0201e72:	69e2                	ld	s3,24(sp)
ffffffffc0201e74:	6a42                	ld	s4,16(sp)
ffffffffc0201e76:	6aa2                	ld	s5,8(sp)
ffffffffc0201e78:	6121                	addi	sp,sp,64
ffffffffc0201e7a:	8082                	ret
            return NULL;
ffffffffc0201e7c:	4501                	li	a0,0
ffffffffc0201e7e:	b7f5                	j	ffffffffc0201e6a <get_pte+0x17e>
        intr_disable();
ffffffffc0201e80:	a6bfe0ef          	jal	ffffffffc02008ea <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e84:	0000b797          	auipc	a5,0xb
ffffffffc0201e88:	61c7b783          	ld	a5,1564(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201e8c:	6f9c                	ld	a5,24(a5)
ffffffffc0201e8e:	4505                	li	a0,1
ffffffffc0201e90:	9782                	jalr	a5
ffffffffc0201e92:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201e94:	a51fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc0201e98:	b555                	j	ffffffffc0201d3c <get_pte+0x50>
        intr_disable();
ffffffffc0201e9a:	a51fe0ef          	jal	ffffffffc02008ea <intr_disable>
ffffffffc0201e9e:	0000b797          	auipc	a5,0xb
ffffffffc0201ea2:	6027b783          	ld	a5,1538(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201ea6:	6f9c                	ld	a5,24(a5)
ffffffffc0201ea8:	4505                	li	a0,1
ffffffffc0201eaa:	9782                	jalr	a5
ffffffffc0201eac:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201eae:	a37fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc0201eb2:	bf3d                	j	ffffffffc0201df0 <get_pte+0x104>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201eb4:	00003617          	auipc	a2,0x3
ffffffffc0201eb8:	d3460613          	addi	a2,a2,-716 # ffffffffc0204be8 <etext+0xd86>
ffffffffc0201ebc:	0fb00593          	li	a1,251
ffffffffc0201ec0:	00003517          	auipc	a0,0x3
ffffffffc0201ec4:	e4050513          	addi	a0,a0,-448 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0201ec8:	e05a                	sd	s6,0(sp)
ffffffffc0201eca:	d7cfe0ef          	jal	ffffffffc0200446 <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ece:	00003617          	auipc	a2,0x3
ffffffffc0201ed2:	d1a60613          	addi	a2,a2,-742 # ffffffffc0204be8 <etext+0xd86>
ffffffffc0201ed6:	0ee00593          	li	a1,238
ffffffffc0201eda:	00003517          	auipc	a0,0x3
ffffffffc0201ede:	e2650513          	addi	a0,a0,-474 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0201ee2:	e05a                	sd	s6,0(sp)
ffffffffc0201ee4:	d62fe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ee8:	86aa                	mv	a3,a0
ffffffffc0201eea:	00003617          	auipc	a2,0x3
ffffffffc0201eee:	cfe60613          	addi	a2,a2,-770 # ffffffffc0204be8 <etext+0xd86>
ffffffffc0201ef2:	0eb00593          	li	a1,235
ffffffffc0201ef6:	00003517          	auipc	a0,0x3
ffffffffc0201efa:	e0a50513          	addi	a0,a0,-502 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0201efe:	d48fe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f02:	00003617          	auipc	a2,0x3
ffffffffc0201f06:	ce660613          	addi	a2,a2,-794 # ffffffffc0204be8 <etext+0xd86>
ffffffffc0201f0a:	0f800593          	li	a1,248
ffffffffc0201f0e:	00003517          	auipc	a0,0x3
ffffffffc0201f12:	df250513          	addi	a0,a0,-526 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0201f16:	d30fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201f1a <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201f1a:	1141                	addi	sp,sp,-16
ffffffffc0201f1c:	e022                	sd	s0,0(sp)
ffffffffc0201f1e:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f20:	4601                	li	a2,0
{
ffffffffc0201f22:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f24:	dc9ff0ef          	jal	ffffffffc0201cec <get_pte>
    if (ptep_store != NULL)
ffffffffc0201f28:	c011                	beqz	s0,ffffffffc0201f2c <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201f2a:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f2c:	c511                	beqz	a0,ffffffffc0201f38 <get_page+0x1e>
ffffffffc0201f2e:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f30:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f32:	0017f713          	andi	a4,a5,1
ffffffffc0201f36:	e709                	bnez	a4,ffffffffc0201f40 <get_page+0x26>
}
ffffffffc0201f38:	60a2                	ld	ra,8(sp)
ffffffffc0201f3a:	6402                	ld	s0,0(sp)
ffffffffc0201f3c:	0141                	addi	sp,sp,16
ffffffffc0201f3e:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f40:	078a                	slli	a5,a5,0x2
ffffffffc0201f42:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201f44:	0000b717          	auipc	a4,0xb
ffffffffc0201f48:	57c73703          	ld	a4,1404(a4) # ffffffffc020d4c0 <npage>
ffffffffc0201f4c:	00e7ff63          	bgeu	a5,a4,ffffffffc0201f6a <get_page+0x50>
ffffffffc0201f50:	60a2                	ld	ra,8(sp)
ffffffffc0201f52:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201f54:	fff80737          	lui	a4,0xfff80
ffffffffc0201f58:	97ba                	add	a5,a5,a4
ffffffffc0201f5a:	0000b517          	auipc	a0,0xb
ffffffffc0201f5e:	56e53503          	ld	a0,1390(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201f62:	079a                	slli	a5,a5,0x6
ffffffffc0201f64:	953e                	add	a0,a0,a5
ffffffffc0201f66:	0141                	addi	sp,sp,16
ffffffffc0201f68:	8082                	ret
ffffffffc0201f6a:	c93ff0ef          	jal	ffffffffc0201bfc <pa2page.part.0>

ffffffffc0201f6e <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201f6e:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f70:	4601                	li	a2,0
{
ffffffffc0201f72:	ec26                	sd	s1,24(sp)
ffffffffc0201f74:	f406                	sd	ra,40(sp)
ffffffffc0201f76:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f78:	d75ff0ef          	jal	ffffffffc0201cec <get_pte>
    if (ptep != NULL)
ffffffffc0201f7c:	c901                	beqz	a0,ffffffffc0201f8c <page_remove+0x1e>
    if (*ptep & PTE_V)
ffffffffc0201f7e:	611c                	ld	a5,0(a0)
ffffffffc0201f80:	f022                	sd	s0,32(sp)
ffffffffc0201f82:	842a                	mv	s0,a0
ffffffffc0201f84:	0017f713          	andi	a4,a5,1
ffffffffc0201f88:	e711                	bnez	a4,ffffffffc0201f94 <page_remove+0x26>
ffffffffc0201f8a:	7402                	ld	s0,32(sp)
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201f8c:	70a2                	ld	ra,40(sp)
ffffffffc0201f8e:	64e2                	ld	s1,24(sp)
ffffffffc0201f90:	6145                	addi	sp,sp,48
ffffffffc0201f92:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f94:	078a                	slli	a5,a5,0x2
ffffffffc0201f96:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201f98:	0000b717          	auipc	a4,0xb
ffffffffc0201f9c:	52873703          	ld	a4,1320(a4) # ffffffffc020d4c0 <npage>
ffffffffc0201fa0:	06e7f363          	bgeu	a5,a4,ffffffffc0202006 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201fa4:	fff80737          	lui	a4,0xfff80
ffffffffc0201fa8:	97ba                	add	a5,a5,a4
ffffffffc0201faa:	079a                	slli	a5,a5,0x6
ffffffffc0201fac:	0000b517          	auipc	a0,0xb
ffffffffc0201fb0:	51c53503          	ld	a0,1308(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201fb4:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201fb6:	411c                	lw	a5,0(a0)
ffffffffc0201fb8:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201fbc:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201fbe:	cb11                	beqz	a4,ffffffffc0201fd2 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0201fc0:	00043023          	sd	zero,0(s0)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201fc4:	12048073          	sfence.vma	s1
ffffffffc0201fc8:	7402                	ld	s0,32(sp)
}
ffffffffc0201fca:	70a2                	ld	ra,40(sp)
ffffffffc0201fcc:	64e2                	ld	s1,24(sp)
ffffffffc0201fce:	6145                	addi	sp,sp,48
ffffffffc0201fd0:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201fd2:	100027f3          	csrr	a5,sstatus
ffffffffc0201fd6:	8b89                	andi	a5,a5,2
ffffffffc0201fd8:	eb89                	bnez	a5,ffffffffc0201fea <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0201fda:	0000b797          	auipc	a5,0xb
ffffffffc0201fde:	4c67b783          	ld	a5,1222(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201fe2:	739c                	ld	a5,32(a5)
ffffffffc0201fe4:	4585                	li	a1,1
ffffffffc0201fe6:	9782                	jalr	a5
    if (flag) {
ffffffffc0201fe8:	bfe1                	j	ffffffffc0201fc0 <page_remove+0x52>
        intr_disable();
ffffffffc0201fea:	e42a                	sd	a0,8(sp)
ffffffffc0201fec:	8fffe0ef          	jal	ffffffffc02008ea <intr_disable>
ffffffffc0201ff0:	0000b797          	auipc	a5,0xb
ffffffffc0201ff4:	4b07b783          	ld	a5,1200(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201ff8:	739c                	ld	a5,32(a5)
ffffffffc0201ffa:	6522                	ld	a0,8(sp)
ffffffffc0201ffc:	4585                	li	a1,1
ffffffffc0201ffe:	9782                	jalr	a5
        intr_enable();
ffffffffc0202000:	8e5fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc0202004:	bf75                	j	ffffffffc0201fc0 <page_remove+0x52>
ffffffffc0202006:	bf7ff0ef          	jal	ffffffffc0201bfc <pa2page.part.0>

ffffffffc020200a <page_insert>:
{
ffffffffc020200a:	7139                	addi	sp,sp,-64
ffffffffc020200c:	e852                	sd	s4,16(sp)
ffffffffc020200e:	8a32                	mv	s4,a2
ffffffffc0202010:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202012:	4605                	li	a2,1
{
ffffffffc0202014:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202016:	85d2                	mv	a1,s4
{
ffffffffc0202018:	f426                	sd	s1,40(sp)
ffffffffc020201a:	fc06                	sd	ra,56(sp)
ffffffffc020201c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020201e:	ccfff0ef          	jal	ffffffffc0201cec <get_pte>
    if (ptep == NULL)
ffffffffc0202022:	c971                	beqz	a0,ffffffffc02020f6 <page_insert+0xec>
    page->ref += 1;
ffffffffc0202024:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202026:	611c                	ld	a5,0(a0)
ffffffffc0202028:	ec4e                	sd	s3,24(sp)
ffffffffc020202a:	0016871b          	addiw	a4,a3,1
ffffffffc020202e:	c018                	sw	a4,0(s0)
ffffffffc0202030:	0017f713          	andi	a4,a5,1
ffffffffc0202034:	89aa                	mv	s3,a0
ffffffffc0202036:	eb15                	bnez	a4,ffffffffc020206a <page_insert+0x60>
    return &pages[PPN(pa) - nbase];
ffffffffc0202038:	0000b717          	auipc	a4,0xb
ffffffffc020203c:	49073703          	ld	a4,1168(a4) # ffffffffc020d4c8 <pages>
    return page - pages + nbase;
ffffffffc0202040:	8c19                	sub	s0,s0,a4
ffffffffc0202042:	000807b7          	lui	a5,0x80
ffffffffc0202046:	8419                	srai	s0,s0,0x6
ffffffffc0202048:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020204a:	042a                	slli	s0,s0,0xa
ffffffffc020204c:	8cc1                	or	s1,s1,s0
ffffffffc020204e:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202052:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202056:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc020205a:	69e2                	ld	s3,24(sp)
ffffffffc020205c:	4501                	li	a0,0
}
ffffffffc020205e:	70e2                	ld	ra,56(sp)
ffffffffc0202060:	7442                	ld	s0,48(sp)
ffffffffc0202062:	74a2                	ld	s1,40(sp)
ffffffffc0202064:	6a42                	ld	s4,16(sp)
ffffffffc0202066:	6121                	addi	sp,sp,64
ffffffffc0202068:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020206a:	078a                	slli	a5,a5,0x2
ffffffffc020206c:	f04a                	sd	s2,32(sp)
ffffffffc020206e:	e456                	sd	s5,8(sp)
ffffffffc0202070:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202072:	0000b717          	auipc	a4,0xb
ffffffffc0202076:	44e73703          	ld	a4,1102(a4) # ffffffffc020d4c0 <npage>
ffffffffc020207a:	08e7f063          	bgeu	a5,a4,ffffffffc02020fa <page_insert+0xf0>
    return &pages[PPN(pa) - nbase];
ffffffffc020207e:	0000ba97          	auipc	s5,0xb
ffffffffc0202082:	44aa8a93          	addi	s5,s5,1098 # ffffffffc020d4c8 <pages>
ffffffffc0202086:	000ab703          	ld	a4,0(s5)
ffffffffc020208a:	fff80637          	lui	a2,0xfff80
ffffffffc020208e:	00c78933          	add	s2,a5,a2
ffffffffc0202092:	091a                	slli	s2,s2,0x6
ffffffffc0202094:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0202096:	01240e63          	beq	s0,s2,ffffffffc02020b2 <page_insert+0xa8>
    page->ref -= 1;
ffffffffc020209a:	00092783          	lw	a5,0(s2) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc020209e:	fff7869b          	addiw	a3,a5,-1 # 7ffff <kern_entry-0xffffffffc0180001>
ffffffffc02020a2:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc02020a6:	ca91                	beqz	a3,ffffffffc02020ba <page_insert+0xb0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020a8:	120a0073          	sfence.vma	s4
ffffffffc02020ac:	7902                	ld	s2,32(sp)
ffffffffc02020ae:	6aa2                	ld	s5,8(sp)
}
ffffffffc02020b0:	bf41                	j	ffffffffc0202040 <page_insert+0x36>
    return page->ref;
ffffffffc02020b2:	7902                	ld	s2,32(sp)
ffffffffc02020b4:	6aa2                	ld	s5,8(sp)
    page->ref -= 1;
ffffffffc02020b6:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02020b8:	b761                	j	ffffffffc0202040 <page_insert+0x36>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02020ba:	100027f3          	csrr	a5,sstatus
ffffffffc02020be:	8b89                	andi	a5,a5,2
ffffffffc02020c0:	ef81                	bnez	a5,ffffffffc02020d8 <page_insert+0xce>
        pmm_manager->free_pages(base, n);
ffffffffc02020c2:	0000b797          	auipc	a5,0xb
ffffffffc02020c6:	3de7b783          	ld	a5,990(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc02020ca:	739c                	ld	a5,32(a5)
ffffffffc02020cc:	4585                	li	a1,1
ffffffffc02020ce:	854a                	mv	a0,s2
ffffffffc02020d0:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02020d2:	000ab703          	ld	a4,0(s5)
ffffffffc02020d6:	bfc9                	j	ffffffffc02020a8 <page_insert+0x9e>
        intr_disable();
ffffffffc02020d8:	813fe0ef          	jal	ffffffffc02008ea <intr_disable>
ffffffffc02020dc:	0000b797          	auipc	a5,0xb
ffffffffc02020e0:	3c47b783          	ld	a5,964(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc02020e4:	739c                	ld	a5,32(a5)
ffffffffc02020e6:	4585                	li	a1,1
ffffffffc02020e8:	854a                	mv	a0,s2
ffffffffc02020ea:	9782                	jalr	a5
        intr_enable();
ffffffffc02020ec:	ff8fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc02020f0:	000ab703          	ld	a4,0(s5)
ffffffffc02020f4:	bf55                	j	ffffffffc02020a8 <page_insert+0x9e>
        return -E_NO_MEM;
ffffffffc02020f6:	5571                	li	a0,-4
ffffffffc02020f8:	b79d                	j	ffffffffc020205e <page_insert+0x54>
ffffffffc02020fa:	b03ff0ef          	jal	ffffffffc0201bfc <pa2page.part.0>

ffffffffc02020fe <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02020fe:	00003797          	auipc	a5,0x3
ffffffffc0202102:	6f278793          	addi	a5,a5,1778 # ffffffffc02057f0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202106:	638c                	ld	a1,0(a5)
{
ffffffffc0202108:	7159                	addi	sp,sp,-112
ffffffffc020210a:	f486                	sd	ra,104(sp)
ffffffffc020210c:	e8ca                	sd	s2,80(sp)
ffffffffc020210e:	e4ce                	sd	s3,72(sp)
ffffffffc0202110:	f85a                	sd	s6,48(sp)
ffffffffc0202112:	f0a2                	sd	s0,96(sp)
ffffffffc0202114:	eca6                	sd	s1,88(sp)
ffffffffc0202116:	e0d2                	sd	s4,64(sp)
ffffffffc0202118:	fc56                	sd	s5,56(sp)
ffffffffc020211a:	f45e                	sd	s7,40(sp)
ffffffffc020211c:	f062                	sd	s8,32(sp)
ffffffffc020211e:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202120:	0000bb17          	auipc	s6,0xb
ffffffffc0202124:	380b0b13          	addi	s6,s6,896 # ffffffffc020d4a0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202128:	00003517          	auipc	a0,0x3
ffffffffc020212c:	be850513          	addi	a0,a0,-1048 # ffffffffc0204d10 <etext+0xeae>
    pmm_manager = &default_pmm_manager;
ffffffffc0202130:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202134:	860fe0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202138:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020213c:	0000b997          	auipc	s3,0xb
ffffffffc0202140:	37c98993          	addi	s3,s3,892 # ffffffffc020d4b8 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202144:	679c                	ld	a5,8(a5)
ffffffffc0202146:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202148:	57f5                	li	a5,-3
ffffffffc020214a:	07fa                	slli	a5,a5,0x1e
ffffffffc020214c:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202150:	f80fe0ef          	jal	ffffffffc02008d0 <get_memory_base>
ffffffffc0202154:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0202156:	f84fe0ef          	jal	ffffffffc02008da <get_memory_size>
    if (mem_size == 0) {
ffffffffc020215a:	20050be3          	beqz	a0,ffffffffc0202b70 <pmm_init+0xa72>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020215e:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202160:	00003517          	auipc	a0,0x3
ffffffffc0202164:	be850513          	addi	a0,a0,-1048 # ffffffffc0204d48 <etext+0xee6>
ffffffffc0202168:	82cfe0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020216c:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202170:	864a                	mv	a2,s2
ffffffffc0202172:	fff40693          	addi	a3,s0,-1
ffffffffc0202176:	85a6                	mv	a1,s1
ffffffffc0202178:	00003517          	auipc	a0,0x3
ffffffffc020217c:	be850513          	addi	a0,a0,-1048 # ffffffffc0204d60 <etext+0xefe>
ffffffffc0202180:	814fe0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc0202184:	c80007b7          	lui	a5,0xc8000
ffffffffc0202188:	8622                	mv	a2,s0
ffffffffc020218a:	5487e763          	bltu	a5,s0,ffffffffc02026d8 <pmm_init+0x5da>
ffffffffc020218e:	77fd                	lui	a5,0xfffff
ffffffffc0202190:	0000c697          	auipc	a3,0xc
ffffffffc0202194:	35f68693          	addi	a3,a3,863 # ffffffffc020e4ef <end+0xfff>
ffffffffc0202198:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc020219a:	8231                	srli	a2,a2,0xc
ffffffffc020219c:	0000b497          	auipc	s1,0xb
ffffffffc02021a0:	32448493          	addi	s1,s1,804 # ffffffffc020d4c0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021a4:	0000bb97          	auipc	s7,0xb
ffffffffc02021a8:	324b8b93          	addi	s7,s7,804 # ffffffffc020d4c8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02021ac:	e090                	sd	a2,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021ae:	00dbb023          	sd	a3,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02021b2:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021b6:	8736                	mv	a4,a3
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02021b8:	04f60163          	beq	a2,a5,ffffffffc02021fa <pmm_init+0xfc>
ffffffffc02021bc:	4705                	li	a4,1
ffffffffc02021be:	06a1                	addi	a3,a3,8
ffffffffc02021c0:	40e6b02f          	amoor.d	zero,a4,(a3)
ffffffffc02021c4:	6090                	ld	a2,0(s1)
ffffffffc02021c6:	4505                	li	a0,1
ffffffffc02021c8:	fff805b7          	lui	a1,0xfff80
ffffffffc02021cc:	40f607b3          	sub	a5,a2,a5
ffffffffc02021d0:	02f77063          	bgeu	a4,a5,ffffffffc02021f0 <pmm_init+0xf2>
        SetPageReserved(pages + i);
ffffffffc02021d4:	000bb783          	ld	a5,0(s7)
ffffffffc02021d8:	00671693          	slli	a3,a4,0x6
ffffffffc02021dc:	97b6                	add	a5,a5,a3
ffffffffc02021de:	07a1                	addi	a5,a5,8 # 80008 <kern_entry-0xffffffffc017fff8>
ffffffffc02021e0:	40a7b02f          	amoor.d	zero,a0,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02021e4:	6090                	ld	a2,0(s1)
ffffffffc02021e6:	0705                	addi	a4,a4,1
ffffffffc02021e8:	00b607b3          	add	a5,a2,a1
ffffffffc02021ec:	fef764e3          	bltu	a4,a5,ffffffffc02021d4 <pmm_init+0xd6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02021f0:	000bb703          	ld	a4,0(s7)
ffffffffc02021f4:	079a                	slli	a5,a5,0x6
ffffffffc02021f6:	00f706b3          	add	a3,a4,a5
ffffffffc02021fa:	c02007b7          	lui	a5,0xc0200
ffffffffc02021fe:	2ef6eae3          	bltu	a3,a5,ffffffffc0202cf2 <pmm_init+0xbf4>
ffffffffc0202202:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202206:	77fd                	lui	a5,0xfffff
ffffffffc0202208:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020220a:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc020220c:	5086e963          	bltu	a3,s0,ffffffffc020271e <pmm_init+0x620>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202210:	00003517          	auipc	a0,0x3
ffffffffc0202214:	b7850513          	addi	a0,a0,-1160 # ffffffffc0204d88 <etext+0xf26>
ffffffffc0202218:	f7dfd0ef          	jal	ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc020221c:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202220:	0000b917          	auipc	s2,0xb
ffffffffc0202224:	29090913          	addi	s2,s2,656 # ffffffffc020d4b0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202228:	7b9c                	ld	a5,48(a5)
ffffffffc020222a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020222c:	00003517          	auipc	a0,0x3
ffffffffc0202230:	b7450513          	addi	a0,a0,-1164 # ffffffffc0204da0 <etext+0xf3e>
ffffffffc0202234:	f61fd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202238:	00006697          	auipc	a3,0x6
ffffffffc020223c:	dc868693          	addi	a3,a3,-568 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0202240:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202244:	c02007b7          	lui	a5,0xc0200
ffffffffc0202248:	28f6e9e3          	bltu	a3,a5,ffffffffc0202cda <pmm_init+0xbdc>
ffffffffc020224c:	0009b783          	ld	a5,0(s3)
ffffffffc0202250:	8e9d                	sub	a3,a3,a5
ffffffffc0202252:	0000b797          	auipc	a5,0xb
ffffffffc0202256:	24d7bb23          	sd	a3,598(a5) # ffffffffc020d4a8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020225a:	100027f3          	csrr	a5,sstatus
ffffffffc020225e:	8b89                	andi	a5,a5,2
ffffffffc0202260:	4a079563          	bnez	a5,ffffffffc020270a <pmm_init+0x60c>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202264:	000b3783          	ld	a5,0(s6)
ffffffffc0202268:	779c                	ld	a5,40(a5)
ffffffffc020226a:	9782                	jalr	a5
ffffffffc020226c:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020226e:	6098                	ld	a4,0(s1)
ffffffffc0202270:	c80007b7          	lui	a5,0xc8000
ffffffffc0202274:	83b1                	srli	a5,a5,0xc
ffffffffc0202276:	66e7e163          	bltu	a5,a4,ffffffffc02028d8 <pmm_init+0x7da>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc020227a:	00093503          	ld	a0,0(s2)
ffffffffc020227e:	62050d63          	beqz	a0,ffffffffc02028b8 <pmm_init+0x7ba>
ffffffffc0202282:	03451793          	slli	a5,a0,0x34
ffffffffc0202286:	62079963          	bnez	a5,ffffffffc02028b8 <pmm_init+0x7ba>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020228a:	4601                	li	a2,0
ffffffffc020228c:	4581                	li	a1,0
ffffffffc020228e:	c8dff0ef          	jal	ffffffffc0201f1a <get_page>
ffffffffc0202292:	60051363          	bnez	a0,ffffffffc0202898 <pmm_init+0x79a>
ffffffffc0202296:	100027f3          	csrr	a5,sstatus
ffffffffc020229a:	8b89                	andi	a5,a5,2
ffffffffc020229c:	44079c63          	bnez	a5,ffffffffc02026f4 <pmm_init+0x5f6>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022a0:	000b3783          	ld	a5,0(s6)
ffffffffc02022a4:	4505                	li	a0,1
ffffffffc02022a6:	6f9c                	ld	a5,24(a5)
ffffffffc02022a8:	9782                	jalr	a5
ffffffffc02022aa:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02022ac:	00093503          	ld	a0,0(s2)
ffffffffc02022b0:	4681                	li	a3,0
ffffffffc02022b2:	4601                	li	a2,0
ffffffffc02022b4:	85d2                	mv	a1,s4
ffffffffc02022b6:	d55ff0ef          	jal	ffffffffc020200a <page_insert>
ffffffffc02022ba:	260518e3          	bnez	a0,ffffffffc0202d2a <pmm_init+0xc2c>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02022be:	00093503          	ld	a0,0(s2)
ffffffffc02022c2:	4601                	li	a2,0
ffffffffc02022c4:	4581                	li	a1,0
ffffffffc02022c6:	a27ff0ef          	jal	ffffffffc0201cec <get_pte>
ffffffffc02022ca:	240500e3          	beqz	a0,ffffffffc0202d0a <pmm_init+0xc0c>
    assert(pte2page(*ptep) == p1);
ffffffffc02022ce:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02022d0:	0017f713          	andi	a4,a5,1
ffffffffc02022d4:	5a070063          	beqz	a4,ffffffffc0202874 <pmm_init+0x776>
    if (PPN(pa) >= npage)
ffffffffc02022d8:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02022da:	078a                	slli	a5,a5,0x2
ffffffffc02022dc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02022de:	58e7f963          	bgeu	a5,a4,ffffffffc0202870 <pmm_init+0x772>
    return &pages[PPN(pa) - nbase];
ffffffffc02022e2:	000bb683          	ld	a3,0(s7)
ffffffffc02022e6:	fff80637          	lui	a2,0xfff80
ffffffffc02022ea:	97b2                	add	a5,a5,a2
ffffffffc02022ec:	079a                	slli	a5,a5,0x6
ffffffffc02022ee:	97b6                	add	a5,a5,a3
ffffffffc02022f0:	14fa15e3          	bne	s4,a5,ffffffffc0202c3a <pmm_init+0xb3c>
    assert(page_ref(p1) == 1);
ffffffffc02022f4:	000a2683          	lw	a3,0(s4) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc02022f8:	4785                	li	a5,1
ffffffffc02022fa:	12f690e3          	bne	a3,a5,ffffffffc0202c1a <pmm_init+0xb1c>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02022fe:	00093503          	ld	a0,0(s2)
ffffffffc0202302:	77fd                	lui	a5,0xfffff
ffffffffc0202304:	6114                	ld	a3,0(a0)
ffffffffc0202306:	068a                	slli	a3,a3,0x2
ffffffffc0202308:	8efd                	and	a3,a3,a5
ffffffffc020230a:	00c6d613          	srli	a2,a3,0xc
ffffffffc020230e:	0ee67ae3          	bgeu	a2,a4,ffffffffc0202c02 <pmm_init+0xb04>
ffffffffc0202312:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202316:	96e2                	add	a3,a3,s8
ffffffffc0202318:	0006ba83          	ld	s5,0(a3)
ffffffffc020231c:	0a8a                	slli	s5,s5,0x2
ffffffffc020231e:	00fafab3          	and	s5,s5,a5
ffffffffc0202322:	00cad793          	srli	a5,s5,0xc
ffffffffc0202326:	0ce7f1e3          	bgeu	a5,a4,ffffffffc0202be8 <pmm_init+0xaea>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020232a:	4601                	li	a2,0
ffffffffc020232c:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020232e:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202330:	9bdff0ef          	jal	ffffffffc0201cec <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202334:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202336:	55851163          	bne	a0,s8,ffffffffc0202878 <pmm_init+0x77a>
ffffffffc020233a:	100027f3          	csrr	a5,sstatus
ffffffffc020233e:	8b89                	andi	a5,a5,2
ffffffffc0202340:	38079f63          	bnez	a5,ffffffffc02026de <pmm_init+0x5e0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202344:	000b3783          	ld	a5,0(s6)
ffffffffc0202348:	4505                	li	a0,1
ffffffffc020234a:	6f9c                	ld	a5,24(a5)
ffffffffc020234c:	9782                	jalr	a5
ffffffffc020234e:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202350:	00093503          	ld	a0,0(s2)
ffffffffc0202354:	46d1                	li	a3,20
ffffffffc0202356:	6605                	lui	a2,0x1
ffffffffc0202358:	85e2                	mv	a1,s8
ffffffffc020235a:	cb1ff0ef          	jal	ffffffffc020200a <page_insert>
ffffffffc020235e:	060515e3          	bnez	a0,ffffffffc0202bc8 <pmm_init+0xaca>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202362:	00093503          	ld	a0,0(s2)
ffffffffc0202366:	4601                	li	a2,0
ffffffffc0202368:	6585                	lui	a1,0x1
ffffffffc020236a:	983ff0ef          	jal	ffffffffc0201cec <get_pte>
ffffffffc020236e:	02050de3          	beqz	a0,ffffffffc0202ba8 <pmm_init+0xaaa>
    assert(*ptep & PTE_U);
ffffffffc0202372:	611c                	ld	a5,0(a0)
ffffffffc0202374:	0107f713          	andi	a4,a5,16
ffffffffc0202378:	7c070c63          	beqz	a4,ffffffffc0202b50 <pmm_init+0xa52>
    assert(*ptep & PTE_W);
ffffffffc020237c:	8b91                	andi	a5,a5,4
ffffffffc020237e:	7a078963          	beqz	a5,ffffffffc0202b30 <pmm_init+0xa32>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202382:	00093503          	ld	a0,0(s2)
ffffffffc0202386:	611c                	ld	a5,0(a0)
ffffffffc0202388:	8bc1                	andi	a5,a5,16
ffffffffc020238a:	78078363          	beqz	a5,ffffffffc0202b10 <pmm_init+0xa12>
    assert(page_ref(p2) == 1);
ffffffffc020238e:	000c2703          	lw	a4,0(s8)
ffffffffc0202392:	4785                	li	a5,1
ffffffffc0202394:	74f71e63          	bne	a4,a5,ffffffffc0202af0 <pmm_init+0x9f2>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202398:	4681                	li	a3,0
ffffffffc020239a:	6605                	lui	a2,0x1
ffffffffc020239c:	85d2                	mv	a1,s4
ffffffffc020239e:	c6dff0ef          	jal	ffffffffc020200a <page_insert>
ffffffffc02023a2:	72051763          	bnez	a0,ffffffffc0202ad0 <pmm_init+0x9d2>
    assert(page_ref(p1) == 2);
ffffffffc02023a6:	000a2703          	lw	a4,0(s4)
ffffffffc02023aa:	4789                	li	a5,2
ffffffffc02023ac:	70f71263          	bne	a4,a5,ffffffffc0202ab0 <pmm_init+0x9b2>
    assert(page_ref(p2) == 0);
ffffffffc02023b0:	000c2783          	lw	a5,0(s8)
ffffffffc02023b4:	6c079e63          	bnez	a5,ffffffffc0202a90 <pmm_init+0x992>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023b8:	00093503          	ld	a0,0(s2)
ffffffffc02023bc:	4601                	li	a2,0
ffffffffc02023be:	6585                	lui	a1,0x1
ffffffffc02023c0:	92dff0ef          	jal	ffffffffc0201cec <get_pte>
ffffffffc02023c4:	6a050663          	beqz	a0,ffffffffc0202a70 <pmm_init+0x972>
    assert(pte2page(*ptep) == p1);
ffffffffc02023c8:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc02023ca:	00177793          	andi	a5,a4,1
ffffffffc02023ce:	4a078363          	beqz	a5,ffffffffc0202874 <pmm_init+0x776>
    if (PPN(pa) >= npage)
ffffffffc02023d2:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02023d4:	00271793          	slli	a5,a4,0x2
ffffffffc02023d8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02023da:	48d7fb63          	bgeu	a5,a3,ffffffffc0202870 <pmm_init+0x772>
    return &pages[PPN(pa) - nbase];
ffffffffc02023de:	000bb683          	ld	a3,0(s7)
ffffffffc02023e2:	fff80ab7          	lui	s5,0xfff80
ffffffffc02023e6:	97d6                	add	a5,a5,s5
ffffffffc02023e8:	079a                	slli	a5,a5,0x6
ffffffffc02023ea:	97b6                	add	a5,a5,a3
ffffffffc02023ec:	66fa1263          	bne	s4,a5,ffffffffc0202a50 <pmm_init+0x952>
    assert((*ptep & PTE_U) == 0);
ffffffffc02023f0:	8b41                	andi	a4,a4,16
ffffffffc02023f2:	62071f63          	bnez	a4,ffffffffc0202a30 <pmm_init+0x932>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc02023f6:	00093503          	ld	a0,0(s2)
ffffffffc02023fa:	4581                	li	a1,0
ffffffffc02023fc:	b73ff0ef          	jal	ffffffffc0201f6e <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202400:	000a2c83          	lw	s9,0(s4)
ffffffffc0202404:	4785                	li	a5,1
ffffffffc0202406:	60fc9563          	bne	s9,a5,ffffffffc0202a10 <pmm_init+0x912>
    assert(page_ref(p2) == 0);
ffffffffc020240a:	000c2783          	lw	a5,0(s8)
ffffffffc020240e:	5e079163          	bnez	a5,ffffffffc02029f0 <pmm_init+0x8f2>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202412:	00093503          	ld	a0,0(s2)
ffffffffc0202416:	6585                	lui	a1,0x1
ffffffffc0202418:	b57ff0ef          	jal	ffffffffc0201f6e <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc020241c:	000a2783          	lw	a5,0(s4)
ffffffffc0202420:	52079863          	bnez	a5,ffffffffc0202950 <pmm_init+0x852>
    assert(page_ref(p2) == 0);
ffffffffc0202424:	000c2783          	lw	a5,0(s8)
ffffffffc0202428:	50079463          	bnez	a5,ffffffffc0202930 <pmm_init+0x832>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc020242c:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202430:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202432:	000a3783          	ld	a5,0(s4)
ffffffffc0202436:	078a                	slli	a5,a5,0x2
ffffffffc0202438:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020243a:	42e7fb63          	bgeu	a5,a4,ffffffffc0202870 <pmm_init+0x772>
    return &pages[PPN(pa) - nbase];
ffffffffc020243e:	000bb503          	ld	a0,0(s7)
ffffffffc0202442:	97d6                	add	a5,a5,s5
ffffffffc0202444:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202446:	00f506b3          	add	a3,a0,a5
ffffffffc020244a:	4294                	lw	a3,0(a3)
ffffffffc020244c:	4d969263          	bne	a3,s9,ffffffffc0202910 <pmm_init+0x812>
    return page - pages + nbase;
ffffffffc0202450:	8799                	srai	a5,a5,0x6
ffffffffc0202452:	00080637          	lui	a2,0x80
ffffffffc0202456:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202458:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020245c:	48e7fe63          	bgeu	a5,a4,ffffffffc02028f8 <pmm_init+0x7fa>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202460:	0009b783          	ld	a5,0(s3)
ffffffffc0202464:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202466:	639c                	ld	a5,0(a5)
ffffffffc0202468:	078a                	slli	a5,a5,0x2
ffffffffc020246a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020246c:	40e7f263          	bgeu	a5,a4,ffffffffc0202870 <pmm_init+0x772>
    return &pages[PPN(pa) - nbase];
ffffffffc0202470:	8f91                	sub	a5,a5,a2
ffffffffc0202472:	079a                	slli	a5,a5,0x6
ffffffffc0202474:	953e                	add	a0,a0,a5
ffffffffc0202476:	100027f3          	csrr	a5,sstatus
ffffffffc020247a:	8b89                	andi	a5,a5,2
ffffffffc020247c:	30079963          	bnez	a5,ffffffffc020278e <pmm_init+0x690>
        pmm_manager->free_pages(base, n);
ffffffffc0202480:	000b3783          	ld	a5,0(s6)
ffffffffc0202484:	4585                	li	a1,1
ffffffffc0202486:	739c                	ld	a5,32(a5)
ffffffffc0202488:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020248a:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc020248e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202490:	078a                	slli	a5,a5,0x2
ffffffffc0202492:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202494:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202870 <pmm_init+0x772>
    return &pages[PPN(pa) - nbase];
ffffffffc0202498:	000bb503          	ld	a0,0(s7)
ffffffffc020249c:	fff80737          	lui	a4,0xfff80
ffffffffc02024a0:	97ba                	add	a5,a5,a4
ffffffffc02024a2:	079a                	slli	a5,a5,0x6
ffffffffc02024a4:	953e                	add	a0,a0,a5
ffffffffc02024a6:	100027f3          	csrr	a5,sstatus
ffffffffc02024aa:	8b89                	andi	a5,a5,2
ffffffffc02024ac:	2c079563          	bnez	a5,ffffffffc0202776 <pmm_init+0x678>
ffffffffc02024b0:	000b3783          	ld	a5,0(s6)
ffffffffc02024b4:	4585                	li	a1,1
ffffffffc02024b6:	739c                	ld	a5,32(a5)
ffffffffc02024b8:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02024ba:	00093783          	ld	a5,0(s2)
ffffffffc02024be:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b10>
    asm volatile("sfence.vma");
ffffffffc02024c2:	12000073          	sfence.vma
ffffffffc02024c6:	100027f3          	csrr	a5,sstatus
ffffffffc02024ca:	8b89                	andi	a5,a5,2
ffffffffc02024cc:	28079b63          	bnez	a5,ffffffffc0202762 <pmm_init+0x664>
        ret = pmm_manager->nr_free_pages();
ffffffffc02024d0:	000b3783          	ld	a5,0(s6)
ffffffffc02024d4:	779c                	ld	a5,40(a5)
ffffffffc02024d6:	9782                	jalr	a5
ffffffffc02024d8:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02024da:	4b441b63          	bne	s0,s4,ffffffffc0202990 <pmm_init+0x892>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02024de:	00003517          	auipc	a0,0x3
ffffffffc02024e2:	bea50513          	addi	a0,a0,-1046 # ffffffffc02050c8 <etext+0x1266>
ffffffffc02024e6:	caffd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc02024ea:	100027f3          	csrr	a5,sstatus
ffffffffc02024ee:	8b89                	andi	a5,a5,2
ffffffffc02024f0:	24079f63          	bnez	a5,ffffffffc020274e <pmm_init+0x650>
        ret = pmm_manager->nr_free_pages();
ffffffffc02024f4:	000b3783          	ld	a5,0(s6)
ffffffffc02024f8:	779c                	ld	a5,40(a5)
ffffffffc02024fa:	9782                	jalr	a5
ffffffffc02024fc:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02024fe:	6098                	ld	a4,0(s1)
ffffffffc0202500:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202504:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202506:	00c71793          	slli	a5,a4,0xc
ffffffffc020250a:	6a05                	lui	s4,0x1
ffffffffc020250c:	02f47c63          	bgeu	s0,a5,ffffffffc0202544 <pmm_init+0x446>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202510:	00c45793          	srli	a5,s0,0xc
ffffffffc0202514:	00093503          	ld	a0,0(s2)
ffffffffc0202518:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202816 <pmm_init+0x718>
ffffffffc020251c:	0009b583          	ld	a1,0(s3)
ffffffffc0202520:	4601                	li	a2,0
ffffffffc0202522:	95a2                	add	a1,a1,s0
ffffffffc0202524:	fc8ff0ef          	jal	ffffffffc0201cec <get_pte>
ffffffffc0202528:	32050463          	beqz	a0,ffffffffc0202850 <pmm_init+0x752>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020252c:	611c                	ld	a5,0(a0)
ffffffffc020252e:	078a                	slli	a5,a5,0x2
ffffffffc0202530:	0157f7b3          	and	a5,a5,s5
ffffffffc0202534:	2e879e63          	bne	a5,s0,ffffffffc0202830 <pmm_init+0x732>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202538:	6098                	ld	a4,0(s1)
ffffffffc020253a:	9452                	add	s0,s0,s4
ffffffffc020253c:	00c71793          	slli	a5,a4,0xc
ffffffffc0202540:	fcf468e3          	bltu	s0,a5,ffffffffc0202510 <pmm_init+0x412>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202544:	00093783          	ld	a5,0(s2)
ffffffffc0202548:	639c                	ld	a5,0(a5)
ffffffffc020254a:	42079363          	bnez	a5,ffffffffc0202970 <pmm_init+0x872>
ffffffffc020254e:	100027f3          	csrr	a5,sstatus
ffffffffc0202552:	8b89                	andi	a5,a5,2
ffffffffc0202554:	24079963          	bnez	a5,ffffffffc02027a6 <pmm_init+0x6a8>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202558:	000b3783          	ld	a5,0(s6)
ffffffffc020255c:	4505                	li	a0,1
ffffffffc020255e:	6f9c                	ld	a5,24(a5)
ffffffffc0202560:	9782                	jalr	a5
ffffffffc0202562:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202564:	00093503          	ld	a0,0(s2)
ffffffffc0202568:	4699                	li	a3,6
ffffffffc020256a:	10000613          	li	a2,256
ffffffffc020256e:	85a2                	mv	a1,s0
ffffffffc0202570:	a9bff0ef          	jal	ffffffffc020200a <page_insert>
ffffffffc0202574:	44051e63          	bnez	a0,ffffffffc02029d0 <pmm_init+0x8d2>
    assert(page_ref(p) == 1);
ffffffffc0202578:	4018                	lw	a4,0(s0)
ffffffffc020257a:	4785                	li	a5,1
ffffffffc020257c:	42f71a63          	bne	a4,a5,ffffffffc02029b0 <pmm_init+0x8b2>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202580:	00093503          	ld	a0,0(s2)
ffffffffc0202584:	6605                	lui	a2,0x1
ffffffffc0202586:	4699                	li	a3,6
ffffffffc0202588:	10060613          	addi	a2,a2,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc020258c:	85a2                	mv	a1,s0
ffffffffc020258e:	a7dff0ef          	jal	ffffffffc020200a <page_insert>
ffffffffc0202592:	72051463          	bnez	a0,ffffffffc0202cba <pmm_init+0xbbc>
    assert(page_ref(p) == 2);
ffffffffc0202596:	4018                	lw	a4,0(s0)
ffffffffc0202598:	4789                	li	a5,2
ffffffffc020259a:	70f71063          	bne	a4,a5,ffffffffc0202c9a <pmm_init+0xb9c>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc020259e:	00003597          	auipc	a1,0x3
ffffffffc02025a2:	c7258593          	addi	a1,a1,-910 # ffffffffc0205210 <etext+0x13ae>
ffffffffc02025a6:	10000513          	li	a0,256
ffffffffc02025aa:	7e2010ef          	jal	ffffffffc0203d8c <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02025ae:	6585                	lui	a1,0x1
ffffffffc02025b0:	10058593          	addi	a1,a1,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025b4:	10000513          	li	a0,256
ffffffffc02025b8:	7e6010ef          	jal	ffffffffc0203d9e <strcmp>
ffffffffc02025bc:	6a051f63          	bnez	a0,ffffffffc0202c7a <pmm_init+0xb7c>
    return page - pages + nbase;
ffffffffc02025c0:	000bb683          	ld	a3,0(s7)
ffffffffc02025c4:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc02025c8:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc02025ca:	40d406b3          	sub	a3,s0,a3
ffffffffc02025ce:	8699                	srai	a3,a3,0x6
ffffffffc02025d0:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02025d2:	00c69793          	slli	a5,a3,0xc
ffffffffc02025d6:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02025d8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02025da:	30e7ff63          	bgeu	a5,a4,ffffffffc02028f8 <pmm_init+0x7fa>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02025de:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02025e2:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02025e6:	97b6                	add	a5,a5,a3
ffffffffc02025e8:	10078023          	sb	zero,256(a5) # 80100 <kern_entry-0xffffffffc017ff00>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02025ec:	76a010ef          	jal	ffffffffc0203d56 <strlen>
ffffffffc02025f0:	66051563          	bnez	a0,ffffffffc0202c5a <pmm_init+0xb5c>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc02025f4:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc02025f8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02025fa:	000a3783          	ld	a5,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02025fe:	078a                	slli	a5,a5,0x2
ffffffffc0202600:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202602:	26e7f763          	bgeu	a5,a4,ffffffffc0202870 <pmm_init+0x772>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202606:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020260a:	2ee7f763          	bgeu	a5,a4,ffffffffc02028f8 <pmm_init+0x7fa>
ffffffffc020260e:	0009b783          	ld	a5,0(s3)
ffffffffc0202612:	00f689b3          	add	s3,a3,a5
ffffffffc0202616:	100027f3          	csrr	a5,sstatus
ffffffffc020261a:	8b89                	andi	a5,a5,2
ffffffffc020261c:	1e079263          	bnez	a5,ffffffffc0202800 <pmm_init+0x702>
        pmm_manager->free_pages(base, n);
ffffffffc0202620:	000b3783          	ld	a5,0(s6)
ffffffffc0202624:	4585                	li	a1,1
ffffffffc0202626:	8522                	mv	a0,s0
ffffffffc0202628:	739c                	ld	a5,32(a5)
ffffffffc020262a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020262c:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202630:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202632:	078a                	slli	a5,a5,0x2
ffffffffc0202634:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202636:	22e7fd63          	bgeu	a5,a4,ffffffffc0202870 <pmm_init+0x772>
    return &pages[PPN(pa) - nbase];
ffffffffc020263a:	000bb503          	ld	a0,0(s7)
ffffffffc020263e:	fff80737          	lui	a4,0xfff80
ffffffffc0202642:	97ba                	add	a5,a5,a4
ffffffffc0202644:	079a                	slli	a5,a5,0x6
ffffffffc0202646:	953e                	add	a0,a0,a5
ffffffffc0202648:	100027f3          	csrr	a5,sstatus
ffffffffc020264c:	8b89                	andi	a5,a5,2
ffffffffc020264e:	18079d63          	bnez	a5,ffffffffc02027e8 <pmm_init+0x6ea>
ffffffffc0202652:	000b3783          	ld	a5,0(s6)
ffffffffc0202656:	4585                	li	a1,1
ffffffffc0202658:	739c                	ld	a5,32(a5)
ffffffffc020265a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020265c:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202660:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202662:	078a                	slli	a5,a5,0x2
ffffffffc0202664:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202666:	20e7f563          	bgeu	a5,a4,ffffffffc0202870 <pmm_init+0x772>
    return &pages[PPN(pa) - nbase];
ffffffffc020266a:	000bb503          	ld	a0,0(s7)
ffffffffc020266e:	fff80737          	lui	a4,0xfff80
ffffffffc0202672:	97ba                	add	a5,a5,a4
ffffffffc0202674:	079a                	slli	a5,a5,0x6
ffffffffc0202676:	953e                	add	a0,a0,a5
ffffffffc0202678:	100027f3          	csrr	a5,sstatus
ffffffffc020267c:	8b89                	andi	a5,a5,2
ffffffffc020267e:	14079963          	bnez	a5,ffffffffc02027d0 <pmm_init+0x6d2>
ffffffffc0202682:	000b3783          	ld	a5,0(s6)
ffffffffc0202686:	4585                	li	a1,1
ffffffffc0202688:	739c                	ld	a5,32(a5)
ffffffffc020268a:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc020268c:	00093783          	ld	a5,0(s2)
ffffffffc0202690:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202694:	12000073          	sfence.vma
ffffffffc0202698:	100027f3          	csrr	a5,sstatus
ffffffffc020269c:	8b89                	andi	a5,a5,2
ffffffffc020269e:	10079f63          	bnez	a5,ffffffffc02027bc <pmm_init+0x6be>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026a2:	000b3783          	ld	a5,0(s6)
ffffffffc02026a6:	779c                	ld	a5,40(a5)
ffffffffc02026a8:	9782                	jalr	a5
ffffffffc02026aa:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02026ac:	4c8c1e63          	bne	s8,s0,ffffffffc0202b88 <pmm_init+0xa8a>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02026b0:	00003517          	auipc	a0,0x3
ffffffffc02026b4:	bd850513          	addi	a0,a0,-1064 # ffffffffc0205288 <etext+0x1426>
ffffffffc02026b8:	addfd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc02026bc:	7406                	ld	s0,96(sp)
ffffffffc02026be:	70a6                	ld	ra,104(sp)
ffffffffc02026c0:	64e6                	ld	s1,88(sp)
ffffffffc02026c2:	6946                	ld	s2,80(sp)
ffffffffc02026c4:	69a6                	ld	s3,72(sp)
ffffffffc02026c6:	6a06                	ld	s4,64(sp)
ffffffffc02026c8:	7ae2                	ld	s5,56(sp)
ffffffffc02026ca:	7b42                	ld	s6,48(sp)
ffffffffc02026cc:	7ba2                	ld	s7,40(sp)
ffffffffc02026ce:	7c02                	ld	s8,32(sp)
ffffffffc02026d0:	6ce2                	ld	s9,24(sp)
ffffffffc02026d2:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc02026d4:	b68ff06f          	j	ffffffffc0201a3c <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc02026d8:	c8000637          	lui	a2,0xc8000
ffffffffc02026dc:	bc4d                	j	ffffffffc020218e <pmm_init+0x90>
        intr_disable();
ffffffffc02026de:	a0cfe0ef          	jal	ffffffffc02008ea <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02026e2:	000b3783          	ld	a5,0(s6)
ffffffffc02026e6:	4505                	li	a0,1
ffffffffc02026e8:	6f9c                	ld	a5,24(a5)
ffffffffc02026ea:	9782                	jalr	a5
ffffffffc02026ec:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02026ee:	9f6fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc02026f2:	b9b9                	j	ffffffffc0202350 <pmm_init+0x252>
        intr_disable();
ffffffffc02026f4:	9f6fe0ef          	jal	ffffffffc02008ea <intr_disable>
ffffffffc02026f8:	000b3783          	ld	a5,0(s6)
ffffffffc02026fc:	4505                	li	a0,1
ffffffffc02026fe:	6f9c                	ld	a5,24(a5)
ffffffffc0202700:	9782                	jalr	a5
ffffffffc0202702:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202704:	9e0fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc0202708:	b655                	j	ffffffffc02022ac <pmm_init+0x1ae>
        intr_disable();
ffffffffc020270a:	9e0fe0ef          	jal	ffffffffc02008ea <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020270e:	000b3783          	ld	a5,0(s6)
ffffffffc0202712:	779c                	ld	a5,40(a5)
ffffffffc0202714:	9782                	jalr	a5
ffffffffc0202716:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202718:	9ccfe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc020271c:	be89                	j	ffffffffc020226e <pmm_init+0x170>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020271e:	6585                	lui	a1,0x1
ffffffffc0202720:	15fd                	addi	a1,a1,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0202722:	96ae                	add	a3,a3,a1
ffffffffc0202724:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202726:	00c7d693          	srli	a3,a5,0xc
ffffffffc020272a:	14c6f363          	bgeu	a3,a2,ffffffffc0202870 <pmm_init+0x772>
    pmm_manager->init_memmap(base, n);
ffffffffc020272e:	000b3603          	ld	a2,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202732:	fff805b7          	lui	a1,0xfff80
ffffffffc0202736:	96ae                	add	a3,a3,a1
ffffffffc0202738:	6a10                	ld	a2,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020273a:	8c1d                	sub	s0,s0,a5
ffffffffc020273c:	00669513          	slli	a0,a3,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202740:	00c45593          	srli	a1,s0,0xc
ffffffffc0202744:	953a                	add	a0,a0,a4
ffffffffc0202746:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202748:	0009b583          	ld	a1,0(s3)
}
ffffffffc020274c:	b4d1                	j	ffffffffc0202210 <pmm_init+0x112>
        intr_disable();
ffffffffc020274e:	99cfe0ef          	jal	ffffffffc02008ea <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202752:	000b3783          	ld	a5,0(s6)
ffffffffc0202756:	779c                	ld	a5,40(a5)
ffffffffc0202758:	9782                	jalr	a5
ffffffffc020275a:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020275c:	988fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc0202760:	bb79                	j	ffffffffc02024fe <pmm_init+0x400>
        intr_disable();
ffffffffc0202762:	988fe0ef          	jal	ffffffffc02008ea <intr_disable>
ffffffffc0202766:	000b3783          	ld	a5,0(s6)
ffffffffc020276a:	779c                	ld	a5,40(a5)
ffffffffc020276c:	9782                	jalr	a5
ffffffffc020276e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202770:	974fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc0202774:	b39d                	j	ffffffffc02024da <pmm_init+0x3dc>
ffffffffc0202776:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202778:	972fe0ef          	jal	ffffffffc02008ea <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020277c:	000b3783          	ld	a5,0(s6)
ffffffffc0202780:	6522                	ld	a0,8(sp)
ffffffffc0202782:	4585                	li	a1,1
ffffffffc0202784:	739c                	ld	a5,32(a5)
ffffffffc0202786:	9782                	jalr	a5
        intr_enable();
ffffffffc0202788:	95cfe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc020278c:	b33d                	j	ffffffffc02024ba <pmm_init+0x3bc>
ffffffffc020278e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202790:	95afe0ef          	jal	ffffffffc02008ea <intr_disable>
ffffffffc0202794:	000b3783          	ld	a5,0(s6)
ffffffffc0202798:	6522                	ld	a0,8(sp)
ffffffffc020279a:	4585                	li	a1,1
ffffffffc020279c:	739c                	ld	a5,32(a5)
ffffffffc020279e:	9782                	jalr	a5
        intr_enable();
ffffffffc02027a0:	944fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc02027a4:	b1dd                	j	ffffffffc020248a <pmm_init+0x38c>
        intr_disable();
ffffffffc02027a6:	944fe0ef          	jal	ffffffffc02008ea <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027aa:	000b3783          	ld	a5,0(s6)
ffffffffc02027ae:	4505                	li	a0,1
ffffffffc02027b0:	6f9c                	ld	a5,24(a5)
ffffffffc02027b2:	9782                	jalr	a5
ffffffffc02027b4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02027b6:	92efe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc02027ba:	b36d                	j	ffffffffc0202564 <pmm_init+0x466>
        intr_disable();
ffffffffc02027bc:	92efe0ef          	jal	ffffffffc02008ea <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02027c0:	000b3783          	ld	a5,0(s6)
ffffffffc02027c4:	779c                	ld	a5,40(a5)
ffffffffc02027c6:	9782                	jalr	a5
ffffffffc02027c8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02027ca:	91afe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc02027ce:	bdf9                	j	ffffffffc02026ac <pmm_init+0x5ae>
ffffffffc02027d0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027d2:	918fe0ef          	jal	ffffffffc02008ea <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027d6:	000b3783          	ld	a5,0(s6)
ffffffffc02027da:	6522                	ld	a0,8(sp)
ffffffffc02027dc:	4585                	li	a1,1
ffffffffc02027de:	739c                	ld	a5,32(a5)
ffffffffc02027e0:	9782                	jalr	a5
        intr_enable();
ffffffffc02027e2:	902fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc02027e6:	b55d                	j	ffffffffc020268c <pmm_init+0x58e>
ffffffffc02027e8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027ea:	900fe0ef          	jal	ffffffffc02008ea <intr_disable>
ffffffffc02027ee:	000b3783          	ld	a5,0(s6)
ffffffffc02027f2:	6522                	ld	a0,8(sp)
ffffffffc02027f4:	4585                	li	a1,1
ffffffffc02027f6:	739c                	ld	a5,32(a5)
ffffffffc02027f8:	9782                	jalr	a5
        intr_enable();
ffffffffc02027fa:	8eafe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc02027fe:	bdb9                	j	ffffffffc020265c <pmm_init+0x55e>
        intr_disable();
ffffffffc0202800:	8eafe0ef          	jal	ffffffffc02008ea <intr_disable>
ffffffffc0202804:	000b3783          	ld	a5,0(s6)
ffffffffc0202808:	4585                	li	a1,1
ffffffffc020280a:	8522                	mv	a0,s0
ffffffffc020280c:	739c                	ld	a5,32(a5)
ffffffffc020280e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202810:	8d4fe0ef          	jal	ffffffffc02008e4 <intr_enable>
ffffffffc0202814:	bd21                	j	ffffffffc020262c <pmm_init+0x52e>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202816:	86a2                	mv	a3,s0
ffffffffc0202818:	00002617          	auipc	a2,0x2
ffffffffc020281c:	3d060613          	addi	a2,a2,976 # ffffffffc0204be8 <etext+0xd86>
ffffffffc0202820:	1a400593          	li	a1,420
ffffffffc0202824:	00002517          	auipc	a0,0x2
ffffffffc0202828:	4dc50513          	addi	a0,a0,1244 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc020282c:	c1bfd0ef          	jal	ffffffffc0200446 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202830:	00003697          	auipc	a3,0x3
ffffffffc0202834:	8f868693          	addi	a3,a3,-1800 # ffffffffc0205128 <etext+0x12c6>
ffffffffc0202838:	00002617          	auipc	a2,0x2
ffffffffc020283c:	00060613          	mv	a2,a2
ffffffffc0202840:	1a500593          	li	a1,421
ffffffffc0202844:	00002517          	auipc	a0,0x2
ffffffffc0202848:	4bc50513          	addi	a0,a0,1212 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc020284c:	bfbfd0ef          	jal	ffffffffc0200446 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202850:	00003697          	auipc	a3,0x3
ffffffffc0202854:	89868693          	addi	a3,a3,-1896 # ffffffffc02050e8 <etext+0x1286>
ffffffffc0202858:	00002617          	auipc	a2,0x2
ffffffffc020285c:	fe060613          	addi	a2,a2,-32 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202860:	1a400593          	li	a1,420
ffffffffc0202864:	00002517          	auipc	a0,0x2
ffffffffc0202868:	49c50513          	addi	a0,a0,1180 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc020286c:	bdbfd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202870:	b8cff0ef          	jal	ffffffffc0201bfc <pa2page.part.0>
ffffffffc0202874:	ba4ff0ef          	jal	ffffffffc0201c18 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202878:	00002697          	auipc	a3,0x2
ffffffffc020287c:	66868693          	addi	a3,a3,1640 # ffffffffc0204ee0 <etext+0x107e>
ffffffffc0202880:	00002617          	auipc	a2,0x2
ffffffffc0202884:	fb860613          	addi	a2,a2,-72 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202888:	17400593          	li	a1,372
ffffffffc020288c:	00002517          	auipc	a0,0x2
ffffffffc0202890:	47450513          	addi	a0,a0,1140 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202894:	bb3fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202898:	00002697          	auipc	a3,0x2
ffffffffc020289c:	58868693          	addi	a3,a3,1416 # ffffffffc0204e20 <etext+0xfbe>
ffffffffc02028a0:	00002617          	auipc	a2,0x2
ffffffffc02028a4:	f9860613          	addi	a2,a2,-104 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02028a8:	16700593          	li	a1,359
ffffffffc02028ac:	00002517          	auipc	a0,0x2
ffffffffc02028b0:	45450513          	addi	a0,a0,1108 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc02028b4:	b93fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028b8:	00002697          	auipc	a3,0x2
ffffffffc02028bc:	52868693          	addi	a3,a3,1320 # ffffffffc0204de0 <etext+0xf7e>
ffffffffc02028c0:	00002617          	auipc	a2,0x2
ffffffffc02028c4:	f7860613          	addi	a2,a2,-136 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02028c8:	16600593          	li	a1,358
ffffffffc02028cc:	00002517          	auipc	a0,0x2
ffffffffc02028d0:	43450513          	addi	a0,a0,1076 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc02028d4:	b73fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02028d8:	00002697          	auipc	a3,0x2
ffffffffc02028dc:	4e868693          	addi	a3,a3,1256 # ffffffffc0204dc0 <etext+0xf5e>
ffffffffc02028e0:	00002617          	auipc	a2,0x2
ffffffffc02028e4:	f5860613          	addi	a2,a2,-168 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02028e8:	16500593          	li	a1,357
ffffffffc02028ec:	00002517          	auipc	a0,0x2
ffffffffc02028f0:	41450513          	addi	a0,a0,1044 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc02028f4:	b53fd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc02028f8:	00002617          	auipc	a2,0x2
ffffffffc02028fc:	2f060613          	addi	a2,a2,752 # ffffffffc0204be8 <etext+0xd86>
ffffffffc0202900:	07100593          	li	a1,113
ffffffffc0202904:	00002517          	auipc	a0,0x2
ffffffffc0202908:	30c50513          	addi	a0,a0,780 # ffffffffc0204c10 <etext+0xdae>
ffffffffc020290c:	b3bfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202910:	00002697          	auipc	a3,0x2
ffffffffc0202914:	76068693          	addi	a3,a3,1888 # ffffffffc0205070 <etext+0x120e>
ffffffffc0202918:	00002617          	auipc	a2,0x2
ffffffffc020291c:	f2060613          	addi	a2,a2,-224 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202920:	18d00593          	li	a1,397
ffffffffc0202924:	00002517          	auipc	a0,0x2
ffffffffc0202928:	3dc50513          	addi	a0,a0,988 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc020292c:	b1bfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202930:	00002697          	auipc	a3,0x2
ffffffffc0202934:	6f868693          	addi	a3,a3,1784 # ffffffffc0205028 <etext+0x11c6>
ffffffffc0202938:	00002617          	auipc	a2,0x2
ffffffffc020293c:	f0060613          	addi	a2,a2,-256 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202940:	18b00593          	li	a1,395
ffffffffc0202944:	00002517          	auipc	a0,0x2
ffffffffc0202948:	3bc50513          	addi	a0,a0,956 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc020294c:	afbfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202950:	00002697          	auipc	a3,0x2
ffffffffc0202954:	70868693          	addi	a3,a3,1800 # ffffffffc0205058 <etext+0x11f6>
ffffffffc0202958:	00002617          	auipc	a2,0x2
ffffffffc020295c:	ee060613          	addi	a2,a2,-288 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202960:	18a00593          	li	a1,394
ffffffffc0202964:	00002517          	auipc	a0,0x2
ffffffffc0202968:	39c50513          	addi	a0,a0,924 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc020296c:	adbfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202970:	00002697          	auipc	a3,0x2
ffffffffc0202974:	7d068693          	addi	a3,a3,2000 # ffffffffc0205140 <etext+0x12de>
ffffffffc0202978:	00002617          	auipc	a2,0x2
ffffffffc020297c:	ec060613          	addi	a2,a2,-320 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202980:	1a800593          	li	a1,424
ffffffffc0202984:	00002517          	auipc	a0,0x2
ffffffffc0202988:	37c50513          	addi	a0,a0,892 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc020298c:	abbfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202990:	00002697          	auipc	a3,0x2
ffffffffc0202994:	71068693          	addi	a3,a3,1808 # ffffffffc02050a0 <etext+0x123e>
ffffffffc0202998:	00002617          	auipc	a2,0x2
ffffffffc020299c:	ea060613          	addi	a2,a2,-352 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02029a0:	19500593          	li	a1,405
ffffffffc02029a4:	00002517          	auipc	a0,0x2
ffffffffc02029a8:	35c50513          	addi	a0,a0,860 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc02029ac:	a9bfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 1);
ffffffffc02029b0:	00002697          	auipc	a3,0x2
ffffffffc02029b4:	7e868693          	addi	a3,a3,2024 # ffffffffc0205198 <etext+0x1336>
ffffffffc02029b8:	00002617          	auipc	a2,0x2
ffffffffc02029bc:	e8060613          	addi	a2,a2,-384 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02029c0:	1ad00593          	li	a1,429
ffffffffc02029c4:	00002517          	auipc	a0,0x2
ffffffffc02029c8:	33c50513          	addi	a0,a0,828 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc02029cc:	a7bfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02029d0:	00002697          	auipc	a3,0x2
ffffffffc02029d4:	78868693          	addi	a3,a3,1928 # ffffffffc0205158 <etext+0x12f6>
ffffffffc02029d8:	00002617          	auipc	a2,0x2
ffffffffc02029dc:	e6060613          	addi	a2,a2,-416 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02029e0:	1ac00593          	li	a1,428
ffffffffc02029e4:	00002517          	auipc	a0,0x2
ffffffffc02029e8:	31c50513          	addi	a0,a0,796 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc02029ec:	a5bfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02029f0:	00002697          	auipc	a3,0x2
ffffffffc02029f4:	63868693          	addi	a3,a3,1592 # ffffffffc0205028 <etext+0x11c6>
ffffffffc02029f8:	00002617          	auipc	a2,0x2
ffffffffc02029fc:	e4060613          	addi	a2,a2,-448 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202a00:	18700593          	li	a1,391
ffffffffc0202a04:	00002517          	auipc	a0,0x2
ffffffffc0202a08:	2fc50513          	addi	a0,a0,764 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202a0c:	a3bfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202a10:	00002697          	auipc	a3,0x2
ffffffffc0202a14:	4b868693          	addi	a3,a3,1208 # ffffffffc0204ec8 <etext+0x1066>
ffffffffc0202a18:	00002617          	auipc	a2,0x2
ffffffffc0202a1c:	e2060613          	addi	a2,a2,-480 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202a20:	18600593          	li	a1,390
ffffffffc0202a24:	00002517          	auipc	a0,0x2
ffffffffc0202a28:	2dc50513          	addi	a0,a0,732 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202a2c:	a1bfd0ef          	jal	ffffffffc0200446 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a30:	00002697          	auipc	a3,0x2
ffffffffc0202a34:	61068693          	addi	a3,a3,1552 # ffffffffc0205040 <etext+0x11de>
ffffffffc0202a38:	00002617          	auipc	a2,0x2
ffffffffc0202a3c:	e0060613          	addi	a2,a2,-512 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202a40:	18300593          	li	a1,387
ffffffffc0202a44:	00002517          	auipc	a0,0x2
ffffffffc0202a48:	2bc50513          	addi	a0,a0,700 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202a4c:	9fbfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a50:	00002697          	auipc	a3,0x2
ffffffffc0202a54:	46068693          	addi	a3,a3,1120 # ffffffffc0204eb0 <etext+0x104e>
ffffffffc0202a58:	00002617          	auipc	a2,0x2
ffffffffc0202a5c:	de060613          	addi	a2,a2,-544 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202a60:	18200593          	li	a1,386
ffffffffc0202a64:	00002517          	auipc	a0,0x2
ffffffffc0202a68:	29c50513          	addi	a0,a0,668 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202a6c:	9dbfd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a70:	00002697          	auipc	a3,0x2
ffffffffc0202a74:	4e068693          	addi	a3,a3,1248 # ffffffffc0204f50 <etext+0x10ee>
ffffffffc0202a78:	00002617          	auipc	a2,0x2
ffffffffc0202a7c:	dc060613          	addi	a2,a2,-576 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202a80:	18100593          	li	a1,385
ffffffffc0202a84:	00002517          	auipc	a0,0x2
ffffffffc0202a88:	27c50513          	addi	a0,a0,636 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202a8c:	9bbfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a90:	00002697          	auipc	a3,0x2
ffffffffc0202a94:	59868693          	addi	a3,a3,1432 # ffffffffc0205028 <etext+0x11c6>
ffffffffc0202a98:	00002617          	auipc	a2,0x2
ffffffffc0202a9c:	da060613          	addi	a2,a2,-608 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202aa0:	18000593          	li	a1,384
ffffffffc0202aa4:	00002517          	auipc	a0,0x2
ffffffffc0202aa8:	25c50513          	addi	a0,a0,604 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202aac:	99bfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202ab0:	00002697          	auipc	a3,0x2
ffffffffc0202ab4:	56068693          	addi	a3,a3,1376 # ffffffffc0205010 <etext+0x11ae>
ffffffffc0202ab8:	00002617          	auipc	a2,0x2
ffffffffc0202abc:	d8060613          	addi	a2,a2,-640 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202ac0:	17f00593          	li	a1,383
ffffffffc0202ac4:	00002517          	auipc	a0,0x2
ffffffffc0202ac8:	23c50513          	addi	a0,a0,572 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202acc:	97bfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202ad0:	00002697          	auipc	a3,0x2
ffffffffc0202ad4:	51068693          	addi	a3,a3,1296 # ffffffffc0204fe0 <etext+0x117e>
ffffffffc0202ad8:	00002617          	auipc	a2,0x2
ffffffffc0202adc:	d6060613          	addi	a2,a2,-672 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202ae0:	17e00593          	li	a1,382
ffffffffc0202ae4:	00002517          	auipc	a0,0x2
ffffffffc0202ae8:	21c50513          	addi	a0,a0,540 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202aec:	95bfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202af0:	00002697          	auipc	a3,0x2
ffffffffc0202af4:	4d868693          	addi	a3,a3,1240 # ffffffffc0204fc8 <etext+0x1166>
ffffffffc0202af8:	00002617          	auipc	a2,0x2
ffffffffc0202afc:	d4060613          	addi	a2,a2,-704 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202b00:	17c00593          	li	a1,380
ffffffffc0202b04:	00002517          	auipc	a0,0x2
ffffffffc0202b08:	1fc50513          	addi	a0,a0,508 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202b0c:	93bfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b10:	00002697          	auipc	a3,0x2
ffffffffc0202b14:	49868693          	addi	a3,a3,1176 # ffffffffc0204fa8 <etext+0x1146>
ffffffffc0202b18:	00002617          	auipc	a2,0x2
ffffffffc0202b1c:	d2060613          	addi	a2,a2,-736 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202b20:	17b00593          	li	a1,379
ffffffffc0202b24:	00002517          	auipc	a0,0x2
ffffffffc0202b28:	1dc50513          	addi	a0,a0,476 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202b2c:	91bfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202b30:	00002697          	auipc	a3,0x2
ffffffffc0202b34:	46868693          	addi	a3,a3,1128 # ffffffffc0204f98 <etext+0x1136>
ffffffffc0202b38:	00002617          	auipc	a2,0x2
ffffffffc0202b3c:	d0060613          	addi	a2,a2,-768 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202b40:	17a00593          	li	a1,378
ffffffffc0202b44:	00002517          	auipc	a0,0x2
ffffffffc0202b48:	1bc50513          	addi	a0,a0,444 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202b4c:	8fbfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202b50:	00002697          	auipc	a3,0x2
ffffffffc0202b54:	43868693          	addi	a3,a3,1080 # ffffffffc0204f88 <etext+0x1126>
ffffffffc0202b58:	00002617          	auipc	a2,0x2
ffffffffc0202b5c:	ce060613          	addi	a2,a2,-800 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202b60:	17900593          	li	a1,377
ffffffffc0202b64:	00002517          	auipc	a0,0x2
ffffffffc0202b68:	19c50513          	addi	a0,a0,412 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202b6c:	8dbfd0ef          	jal	ffffffffc0200446 <__panic>
        panic("DTB memory info not available");
ffffffffc0202b70:	00002617          	auipc	a2,0x2
ffffffffc0202b74:	1b860613          	addi	a2,a2,440 # ffffffffc0204d28 <etext+0xec6>
ffffffffc0202b78:	06400593          	li	a1,100
ffffffffc0202b7c:	00002517          	auipc	a0,0x2
ffffffffc0202b80:	18450513          	addi	a0,a0,388 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202b84:	8c3fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202b88:	00002697          	auipc	a3,0x2
ffffffffc0202b8c:	51868693          	addi	a3,a3,1304 # ffffffffc02050a0 <etext+0x123e>
ffffffffc0202b90:	00002617          	auipc	a2,0x2
ffffffffc0202b94:	ca860613          	addi	a2,a2,-856 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202b98:	1bf00593          	li	a1,447
ffffffffc0202b9c:	00002517          	auipc	a0,0x2
ffffffffc0202ba0:	16450513          	addi	a0,a0,356 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202ba4:	8a3fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202ba8:	00002697          	auipc	a3,0x2
ffffffffc0202bac:	3a868693          	addi	a3,a3,936 # ffffffffc0204f50 <etext+0x10ee>
ffffffffc0202bb0:	00002617          	auipc	a2,0x2
ffffffffc0202bb4:	c8860613          	addi	a2,a2,-888 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202bb8:	17800593          	li	a1,376
ffffffffc0202bbc:	00002517          	auipc	a0,0x2
ffffffffc0202bc0:	14450513          	addi	a0,a0,324 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202bc4:	883fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202bc8:	00002697          	auipc	a3,0x2
ffffffffc0202bcc:	34868693          	addi	a3,a3,840 # ffffffffc0204f10 <etext+0x10ae>
ffffffffc0202bd0:	00002617          	auipc	a2,0x2
ffffffffc0202bd4:	c6860613          	addi	a2,a2,-920 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202bd8:	17700593          	li	a1,375
ffffffffc0202bdc:	00002517          	auipc	a0,0x2
ffffffffc0202be0:	12450513          	addi	a0,a0,292 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202be4:	863fd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202be8:	86d6                	mv	a3,s5
ffffffffc0202bea:	00002617          	auipc	a2,0x2
ffffffffc0202bee:	ffe60613          	addi	a2,a2,-2 # ffffffffc0204be8 <etext+0xd86>
ffffffffc0202bf2:	17300593          	li	a1,371
ffffffffc0202bf6:	00002517          	auipc	a0,0x2
ffffffffc0202bfa:	10a50513          	addi	a0,a0,266 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202bfe:	849fd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202c02:	00002617          	auipc	a2,0x2
ffffffffc0202c06:	fe660613          	addi	a2,a2,-26 # ffffffffc0204be8 <etext+0xd86>
ffffffffc0202c0a:	17200593          	li	a1,370
ffffffffc0202c0e:	00002517          	auipc	a0,0x2
ffffffffc0202c12:	0f250513          	addi	a0,a0,242 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202c16:	831fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202c1a:	00002697          	auipc	a3,0x2
ffffffffc0202c1e:	2ae68693          	addi	a3,a3,686 # ffffffffc0204ec8 <etext+0x1066>
ffffffffc0202c22:	00002617          	auipc	a2,0x2
ffffffffc0202c26:	c1660613          	addi	a2,a2,-1002 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202c2a:	17000593          	li	a1,368
ffffffffc0202c2e:	00002517          	auipc	a0,0x2
ffffffffc0202c32:	0d250513          	addi	a0,a0,210 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202c36:	811fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c3a:	00002697          	auipc	a3,0x2
ffffffffc0202c3e:	27668693          	addi	a3,a3,630 # ffffffffc0204eb0 <etext+0x104e>
ffffffffc0202c42:	00002617          	auipc	a2,0x2
ffffffffc0202c46:	bf660613          	addi	a2,a2,-1034 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202c4a:	16f00593          	li	a1,367
ffffffffc0202c4e:	00002517          	auipc	a0,0x2
ffffffffc0202c52:	0b250513          	addi	a0,a0,178 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202c56:	ff0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c5a:	00002697          	auipc	a3,0x2
ffffffffc0202c5e:	60668693          	addi	a3,a3,1542 # ffffffffc0205260 <etext+0x13fe>
ffffffffc0202c62:	00002617          	auipc	a2,0x2
ffffffffc0202c66:	bd660613          	addi	a2,a2,-1066 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202c6a:	1b600593          	li	a1,438
ffffffffc0202c6e:	00002517          	auipc	a0,0x2
ffffffffc0202c72:	09250513          	addi	a0,a0,146 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202c76:	fd0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c7a:	00002697          	auipc	a3,0x2
ffffffffc0202c7e:	5ae68693          	addi	a3,a3,1454 # ffffffffc0205228 <etext+0x13c6>
ffffffffc0202c82:	00002617          	auipc	a2,0x2
ffffffffc0202c86:	bb660613          	addi	a2,a2,-1098 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202c8a:	1b300593          	li	a1,435
ffffffffc0202c8e:	00002517          	auipc	a0,0x2
ffffffffc0202c92:	07250513          	addi	a0,a0,114 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202c96:	fb0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202c9a:	00002697          	auipc	a3,0x2
ffffffffc0202c9e:	55e68693          	addi	a3,a3,1374 # ffffffffc02051f8 <etext+0x1396>
ffffffffc0202ca2:	00002617          	auipc	a2,0x2
ffffffffc0202ca6:	b9660613          	addi	a2,a2,-1130 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202caa:	1af00593          	li	a1,431
ffffffffc0202cae:	00002517          	auipc	a0,0x2
ffffffffc0202cb2:	05250513          	addi	a0,a0,82 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202cb6:	f90fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202cba:	00002697          	auipc	a3,0x2
ffffffffc0202cbe:	4f668693          	addi	a3,a3,1270 # ffffffffc02051b0 <etext+0x134e>
ffffffffc0202cc2:	00002617          	auipc	a2,0x2
ffffffffc0202cc6:	b7660613          	addi	a2,a2,-1162 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202cca:	1ae00593          	li	a1,430
ffffffffc0202cce:	00002517          	auipc	a0,0x2
ffffffffc0202cd2:	03250513          	addi	a0,a0,50 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202cd6:	f70fd0ef          	jal	ffffffffc0200446 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202cda:	00002617          	auipc	a2,0x2
ffffffffc0202cde:	fb660613          	addi	a2,a2,-74 # ffffffffc0204c90 <etext+0xe2e>
ffffffffc0202ce2:	0cb00593          	li	a1,203
ffffffffc0202ce6:	00002517          	auipc	a0,0x2
ffffffffc0202cea:	01a50513          	addi	a0,a0,26 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202cee:	f58fd0ef          	jal	ffffffffc0200446 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202cf2:	00002617          	auipc	a2,0x2
ffffffffc0202cf6:	f9e60613          	addi	a2,a2,-98 # ffffffffc0204c90 <etext+0xe2e>
ffffffffc0202cfa:	08000593          	li	a1,128
ffffffffc0202cfe:	00002517          	auipc	a0,0x2
ffffffffc0202d02:	00250513          	addi	a0,a0,2 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202d06:	f40fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202d0a:	00002697          	auipc	a3,0x2
ffffffffc0202d0e:	17668693          	addi	a3,a3,374 # ffffffffc0204e80 <etext+0x101e>
ffffffffc0202d12:	00002617          	auipc	a2,0x2
ffffffffc0202d16:	b2660613          	addi	a2,a2,-1242 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202d1a:	16e00593          	li	a1,366
ffffffffc0202d1e:	00002517          	auipc	a0,0x2
ffffffffc0202d22:	fe250513          	addi	a0,a0,-30 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202d26:	f20fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d2a:	00002697          	auipc	a3,0x2
ffffffffc0202d2e:	12668693          	addi	a3,a3,294 # ffffffffc0204e50 <etext+0xfee>
ffffffffc0202d32:	00002617          	auipc	a2,0x2
ffffffffc0202d36:	b0660613          	addi	a2,a2,-1274 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202d3a:	16b00593          	li	a1,363
ffffffffc0202d3e:	00002517          	auipc	a0,0x2
ffffffffc0202d42:	fc250513          	addi	a0,a0,-62 # ffffffffc0204d00 <etext+0xe9e>
ffffffffc0202d46:	f00fd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0202d4a <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202d4a:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202d4c:	00002697          	auipc	a3,0x2
ffffffffc0202d50:	55c68693          	addi	a3,a3,1372 # ffffffffc02052a8 <etext+0x1446>
ffffffffc0202d54:	00002617          	auipc	a2,0x2
ffffffffc0202d58:	ae460613          	addi	a2,a2,-1308 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202d5c:	08800593          	li	a1,136
ffffffffc0202d60:	00002517          	auipc	a0,0x2
ffffffffc0202d64:	56850513          	addi	a0,a0,1384 # ffffffffc02052c8 <etext+0x1466>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202d68:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202d6a:	edcfd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0202d6e <find_vma>:
{
ffffffffc0202d6e:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0202d70:	c505                	beqz	a0,ffffffffc0202d98 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0202d72:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202d74:	c501                	beqz	a0,ffffffffc0202d7c <find_vma+0xe>
ffffffffc0202d76:	651c                	ld	a5,8(a0)
ffffffffc0202d78:	02f5f663          	bgeu	a1,a5,ffffffffc0202da4 <find_vma+0x36>
    return listelm->next;
ffffffffc0202d7c:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0202d7e:	00f68d63          	beq	a3,a5,ffffffffc0202d98 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202d82:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202d86:	00e5e663          	bltu	a1,a4,ffffffffc0202d92 <find_vma+0x24>
ffffffffc0202d8a:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202d8e:	00e5e763          	bltu	a1,a4,ffffffffc0202d9c <find_vma+0x2e>
ffffffffc0202d92:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202d94:	fef697e3          	bne	a3,a5,ffffffffc0202d82 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0202d98:	4501                	li	a0,0
}
ffffffffc0202d9a:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202d9c:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202da0:	ea88                	sd	a0,16(a3)
ffffffffc0202da2:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202da4:	691c                	ld	a5,16(a0)
ffffffffc0202da6:	fcf5fbe3          	bgeu	a1,a5,ffffffffc0202d7c <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0202daa:	ea88                	sd	a0,16(a3)
ffffffffc0202dac:	8082                	ret

ffffffffc0202dae <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202dae:	6590                	ld	a2,8(a1)
ffffffffc0202db0:	0105b803          	ld	a6,16(a1) # fffffffffff80010 <end+0x3fd72b20>
{
ffffffffc0202db4:	1141                	addi	sp,sp,-16
ffffffffc0202db6:	e406                	sd	ra,8(sp)
ffffffffc0202db8:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202dba:	01066763          	bltu	a2,a6,ffffffffc0202dc8 <insert_vma_struct+0x1a>
ffffffffc0202dbe:	a085                	j	ffffffffc0202e1e <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202dc0:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202dc4:	04e66863          	bltu	a2,a4,ffffffffc0202e14 <insert_vma_struct+0x66>
ffffffffc0202dc8:	86be                	mv	a3,a5
ffffffffc0202dca:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202dcc:	fef51ae3          	bne	a0,a5,ffffffffc0202dc0 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202dd0:	02a68463          	beq	a3,a0,ffffffffc0202df8 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202dd4:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202dd8:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202ddc:	08e8f163          	bgeu	a7,a4,ffffffffc0202e5e <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202de0:	04e66f63          	bltu	a2,a4,ffffffffc0202e3e <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0202de4:	00f50a63          	beq	a0,a5,ffffffffc0202df8 <insert_vma_struct+0x4a>
ffffffffc0202de8:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202dec:	05076963          	bltu	a4,a6,ffffffffc0202e3e <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0202df0:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202df4:	02c77363          	bgeu	a4,a2,ffffffffc0202e1a <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202df8:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202dfa:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202dfc:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202e00:	e390                	sd	a2,0(a5)
ffffffffc0202e02:	e690                	sd	a2,8(a3)
}
ffffffffc0202e04:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202e06:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202e08:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202e0a:	0017079b          	addiw	a5,a4,1 # fffffffffff80001 <end+0x3fd72b11>
ffffffffc0202e0e:	d11c                	sw	a5,32(a0)
}
ffffffffc0202e10:	0141                	addi	sp,sp,16
ffffffffc0202e12:	8082                	ret
    if (le_prev != list)
ffffffffc0202e14:	fca690e3          	bne	a3,a0,ffffffffc0202dd4 <insert_vma_struct+0x26>
ffffffffc0202e18:	bfd1                	j	ffffffffc0202dec <insert_vma_struct+0x3e>
ffffffffc0202e1a:	f31ff0ef          	jal	ffffffffc0202d4a <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e1e:	00002697          	auipc	a3,0x2
ffffffffc0202e22:	4ba68693          	addi	a3,a3,1210 # ffffffffc02052d8 <etext+0x1476>
ffffffffc0202e26:	00002617          	auipc	a2,0x2
ffffffffc0202e2a:	a1260613          	addi	a2,a2,-1518 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202e2e:	08e00593          	li	a1,142
ffffffffc0202e32:	00002517          	auipc	a0,0x2
ffffffffc0202e36:	49650513          	addi	a0,a0,1174 # ffffffffc02052c8 <etext+0x1466>
ffffffffc0202e3a:	e0cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e3e:	00002697          	auipc	a3,0x2
ffffffffc0202e42:	4da68693          	addi	a3,a3,1242 # ffffffffc0205318 <etext+0x14b6>
ffffffffc0202e46:	00002617          	auipc	a2,0x2
ffffffffc0202e4a:	9f260613          	addi	a2,a2,-1550 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202e4e:	08700593          	li	a1,135
ffffffffc0202e52:	00002517          	auipc	a0,0x2
ffffffffc0202e56:	47650513          	addi	a0,a0,1142 # ffffffffc02052c8 <etext+0x1466>
ffffffffc0202e5a:	decfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e5e:	00002697          	auipc	a3,0x2
ffffffffc0202e62:	49a68693          	addi	a3,a3,1178 # ffffffffc02052f8 <etext+0x1496>
ffffffffc0202e66:	00002617          	auipc	a2,0x2
ffffffffc0202e6a:	9d260613          	addi	a2,a2,-1582 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0202e6e:	08600593          	li	a1,134
ffffffffc0202e72:	00002517          	auipc	a0,0x2
ffffffffc0202e76:	45650513          	addi	a0,a0,1110 # ffffffffc02052c8 <etext+0x1466>
ffffffffc0202e7a:	dccfd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0202e7e <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202e7e:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202e80:	03000513          	li	a0,48
{
ffffffffc0202e84:	fc06                	sd	ra,56(sp)
ffffffffc0202e86:	f822                	sd	s0,48(sp)
ffffffffc0202e88:	f426                	sd	s1,40(sp)
ffffffffc0202e8a:	f04a                	sd	s2,32(sp)
ffffffffc0202e8c:	ec4e                	sd	s3,24(sp)
ffffffffc0202e8e:	e852                	sd	s4,16(sp)
ffffffffc0202e90:	e456                	sd	s5,8(sp)
ffffffffc0202e92:	e05a                	sd	s6,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202e94:	bc9fe0ef          	jal	ffffffffc0201a5c <kmalloc>
    if (mm != NULL)
ffffffffc0202e98:	18050e63          	beqz	a0,ffffffffc0203034 <vmm_init+0x1b6>
ffffffffc0202e9c:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0202e9e:	e508                	sd	a0,8(a0)
ffffffffc0202ea0:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202ea2:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202ea6:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202eaa:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202eae:	02053423          	sd	zero,40(a0)
ffffffffc0202eb2:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202eb6:	03000513          	li	a0,48
ffffffffc0202eba:	ba3fe0ef          	jal	ffffffffc0201a5c <kmalloc>
ffffffffc0202ebe:	00248913          	addi	s2,s1,2
ffffffffc0202ec2:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0202ec4:	14050863          	beqz	a0,ffffffffc0203014 <vmm_init+0x196>
        vma->vm_start = vm_start;
ffffffffc0202ec8:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202eca:	01253823          	sd	s2,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202ece:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0202ed2:	14ed                	addi	s1,s1,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202ed4:	8522                	mv	a0,s0
ffffffffc0202ed6:	ed9ff0ef          	jal	ffffffffc0202dae <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202eda:	fcf1                	bnez	s1,ffffffffc0202eb6 <vmm_init+0x38>
ffffffffc0202edc:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202ee0:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202ee4:	03000513          	li	a0,48
ffffffffc0202ee8:	b75fe0ef          	jal	ffffffffc0201a5c <kmalloc>
ffffffffc0202eec:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0202eee:	16050363          	beqz	a0,ffffffffc0203054 <vmm_init+0x1d6>
        vma->vm_end = vm_end;
ffffffffc0202ef2:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0202ef6:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202ef8:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202efa:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202efe:	0495                	addi	s1,s1,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f00:	8522                	mv	a0,s0
ffffffffc0202f02:	eadff0ef          	jal	ffffffffc0202dae <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f06:	fd249fe3          	bne	s1,s2,ffffffffc0202ee4 <vmm_init+0x66>
    return listelm->next;
ffffffffc0202f0a:	00843a03          	ld	s4,8(s0) # ffffffffc0200008 <kern_entry+0x8>

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202f0e:	1c8a0363          	beq	s4,s0,ffffffffc02030d4 <vmm_init+0x256>
    list_entry_t *le = list_next(&(mm->mmap_list));
ffffffffc0202f12:	87d2                	mv	a5,s4
        assert(le != &(mm->mmap_list));
ffffffffc0202f14:	4715                	li	a4,5
    for (i = 1; i <= step2; i++)
ffffffffc0202f16:	1f400593          	li	a1,500
ffffffffc0202f1a:	a021                	j	ffffffffc0202f22 <vmm_init+0xa4>
        assert(le != &(mm->mmap_list));
ffffffffc0202f1c:	0715                	addi	a4,a4,5
ffffffffc0202f1e:	1a878b63          	beq	a5,s0,ffffffffc02030d4 <vmm_init+0x256>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202f22:	fe87b683          	ld	a3,-24(a5)
ffffffffc0202f26:	18e69763          	bne	a3,a4,ffffffffc02030b4 <vmm_init+0x236>
ffffffffc0202f2a:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202f2e:	00270693          	addi	a3,a4,2
ffffffffc0202f32:	18d61163          	bne	a2,a3,ffffffffc02030b4 <vmm_init+0x236>
ffffffffc0202f36:	679c                	ld	a5,8(a5)
    for (i = 1; i <= step2; i++)
ffffffffc0202f38:	feb712e3          	bne	a4,a1,ffffffffc0202f1c <vmm_init+0x9e>
ffffffffc0202f3c:	4a9d                	li	s5,7
ffffffffc0202f3e:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202f40:	1f900b13          	li	s6,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202f44:	85a6                	mv	a1,s1
ffffffffc0202f46:	8522                	mv	a0,s0
ffffffffc0202f48:	e27ff0ef          	jal	ffffffffc0202d6e <find_vma>
ffffffffc0202f4c:	89aa                	mv	s3,a0
        assert(vma1 != NULL);
ffffffffc0202f4e:	1c050363          	beqz	a0,ffffffffc0203114 <vmm_init+0x296>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202f52:	00148593          	addi	a1,s1,1
ffffffffc0202f56:	8522                	mv	a0,s0
ffffffffc0202f58:	e17ff0ef          	jal	ffffffffc0202d6e <find_vma>
ffffffffc0202f5c:	892a                	mv	s2,a0
        assert(vma2 != NULL);
ffffffffc0202f5e:	18050b63          	beqz	a0,ffffffffc02030f4 <vmm_init+0x276>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202f62:	85d6                	mv	a1,s5
ffffffffc0202f64:	8522                	mv	a0,s0
ffffffffc0202f66:	e09ff0ef          	jal	ffffffffc0202d6e <find_vma>
        assert(vma3 == NULL);
ffffffffc0202f6a:	20051563          	bnez	a0,ffffffffc0203174 <vmm_init+0x2f6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202f6e:	00348593          	addi	a1,s1,3
ffffffffc0202f72:	8522                	mv	a0,s0
ffffffffc0202f74:	dfbff0ef          	jal	ffffffffc0202d6e <find_vma>
        assert(vma4 == NULL);
ffffffffc0202f78:	1c051e63          	bnez	a0,ffffffffc0203154 <vmm_init+0x2d6>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202f7c:	00448593          	addi	a1,s1,4
ffffffffc0202f80:	8522                	mv	a0,s0
ffffffffc0202f82:	dedff0ef          	jal	ffffffffc0202d6e <find_vma>
        assert(vma5 == NULL);
ffffffffc0202f86:	1a051763          	bnez	a0,ffffffffc0203134 <vmm_init+0x2b6>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202f8a:	0089b783          	ld	a5,8(s3)
ffffffffc0202f8e:	10979363          	bne	a5,s1,ffffffffc0203094 <vmm_init+0x216>
ffffffffc0202f92:	0109b783          	ld	a5,16(s3)
ffffffffc0202f96:	0f579f63          	bne	a5,s5,ffffffffc0203094 <vmm_init+0x216>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202f9a:	00893783          	ld	a5,8(s2)
ffffffffc0202f9e:	0c979b63          	bne	a5,s1,ffffffffc0203074 <vmm_init+0x1f6>
ffffffffc0202fa2:	01093783          	ld	a5,16(s2)
ffffffffc0202fa6:	0d579763          	bne	a5,s5,ffffffffc0203074 <vmm_init+0x1f6>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202faa:	0495                	addi	s1,s1,5
ffffffffc0202fac:	0a95                	addi	s5,s5,5 # fffffffffffff005 <end+0x3fdf1b15>
ffffffffc0202fae:	f9649be3          	bne	s1,s6,ffffffffc0202f44 <vmm_init+0xc6>
ffffffffc0202fb2:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0202fb4:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0202fb6:	85a6                	mv	a1,s1
ffffffffc0202fb8:	8522                	mv	a0,s0
ffffffffc0202fba:	db5ff0ef          	jal	ffffffffc0202d6e <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0202fbe:	1c051b63          	bnez	a0,ffffffffc0203194 <vmm_init+0x316>
    for (i = 4; i >= 0; i--)
ffffffffc0202fc2:	14fd                	addi	s1,s1,-1
ffffffffc0202fc4:	ff2499e3          	bne	s1,s2,ffffffffc0202fb6 <vmm_init+0x138>
    __list_del(listelm->prev, listelm->next);
ffffffffc0202fc8:	000a3703          	ld	a4,0(s4)
ffffffffc0202fcc:	008a3783          	ld	a5,8(s4)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0202fd0:	fe0a0513          	addi	a0,s4,-32
    prev->next = next;
ffffffffc0202fd4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202fd6:	e398                	sd	a4,0(a5)
ffffffffc0202fd8:	b2ffe0ef          	jal	ffffffffc0201b06 <kfree>
    return listelm->next;
ffffffffc0202fdc:	00843a03          	ld	s4,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0202fe0:	ff4414e3          	bne	s0,s4,ffffffffc0202fc8 <vmm_init+0x14a>
    kfree(mm); // kfree mm
ffffffffc0202fe4:	8522                	mv	a0,s0
ffffffffc0202fe6:	b21fe0ef          	jal	ffffffffc0201b06 <kfree>
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0202fea:	00002517          	auipc	a0,0x2
ffffffffc0202fee:	4ae50513          	addi	a0,a0,1198 # ffffffffc0205498 <etext+0x1636>
ffffffffc0202ff2:	9a2fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0202ff6:	7442                	ld	s0,48(sp)
ffffffffc0202ff8:	70e2                	ld	ra,56(sp)
ffffffffc0202ffa:	74a2                	ld	s1,40(sp)
ffffffffc0202ffc:	7902                	ld	s2,32(sp)
ffffffffc0202ffe:	69e2                	ld	s3,24(sp)
ffffffffc0203000:	6a42                	ld	s4,16(sp)
ffffffffc0203002:	6aa2                	ld	s5,8(sp)
ffffffffc0203004:	6b02                	ld	s6,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203006:	00002517          	auipc	a0,0x2
ffffffffc020300a:	4b250513          	addi	a0,a0,1202 # ffffffffc02054b8 <etext+0x1656>
}
ffffffffc020300e:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203010:	984fd06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc0203014:	00002697          	auipc	a3,0x2
ffffffffc0203018:	33468693          	addi	a3,a3,820 # ffffffffc0205348 <etext+0x14e6>
ffffffffc020301c:	00002617          	auipc	a2,0x2
ffffffffc0203020:	81c60613          	addi	a2,a2,-2020 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0203024:	0da00593          	li	a1,218
ffffffffc0203028:	00002517          	auipc	a0,0x2
ffffffffc020302c:	2a050513          	addi	a0,a0,672 # ffffffffc02052c8 <etext+0x1466>
ffffffffc0203030:	c16fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(mm != NULL);
ffffffffc0203034:	00002697          	auipc	a3,0x2
ffffffffc0203038:	30468693          	addi	a3,a3,772 # ffffffffc0205338 <etext+0x14d6>
ffffffffc020303c:	00001617          	auipc	a2,0x1
ffffffffc0203040:	7fc60613          	addi	a2,a2,2044 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0203044:	0d200593          	li	a1,210
ffffffffc0203048:	00002517          	auipc	a0,0x2
ffffffffc020304c:	28050513          	addi	a0,a0,640 # ffffffffc02052c8 <etext+0x1466>
ffffffffc0203050:	bf6fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma != NULL);
ffffffffc0203054:	00002697          	auipc	a3,0x2
ffffffffc0203058:	2f468693          	addi	a3,a3,756 # ffffffffc0205348 <etext+0x14e6>
ffffffffc020305c:	00001617          	auipc	a2,0x1
ffffffffc0203060:	7dc60613          	addi	a2,a2,2012 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0203064:	0e100593          	li	a1,225
ffffffffc0203068:	00002517          	auipc	a0,0x2
ffffffffc020306c:	26050513          	addi	a0,a0,608 # ffffffffc02052c8 <etext+0x1466>
ffffffffc0203070:	bd6fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203074:	00002697          	auipc	a3,0x2
ffffffffc0203078:	3b468693          	addi	a3,a3,948 # ffffffffc0205428 <etext+0x15c6>
ffffffffc020307c:	00001617          	auipc	a2,0x1
ffffffffc0203080:	7bc60613          	addi	a2,a2,1980 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0203084:	0fd00593          	li	a1,253
ffffffffc0203088:	00002517          	auipc	a0,0x2
ffffffffc020308c:	24050513          	addi	a0,a0,576 # ffffffffc02052c8 <etext+0x1466>
ffffffffc0203090:	bb6fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203094:	00002697          	auipc	a3,0x2
ffffffffc0203098:	36468693          	addi	a3,a3,868 # ffffffffc02053f8 <etext+0x1596>
ffffffffc020309c:	00001617          	auipc	a2,0x1
ffffffffc02030a0:	79c60613          	addi	a2,a2,1948 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02030a4:	0fc00593          	li	a1,252
ffffffffc02030a8:	00002517          	auipc	a0,0x2
ffffffffc02030ac:	22050513          	addi	a0,a0,544 # ffffffffc02052c8 <etext+0x1466>
ffffffffc02030b0:	b96fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02030b4:	00002697          	auipc	a3,0x2
ffffffffc02030b8:	2bc68693          	addi	a3,a3,700 # ffffffffc0205370 <etext+0x150e>
ffffffffc02030bc:	00001617          	auipc	a2,0x1
ffffffffc02030c0:	77c60613          	addi	a2,a2,1916 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02030c4:	0eb00593          	li	a1,235
ffffffffc02030c8:	00002517          	auipc	a0,0x2
ffffffffc02030cc:	20050513          	addi	a0,a0,512 # ffffffffc02052c8 <etext+0x1466>
ffffffffc02030d0:	b76fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02030d4:	00002697          	auipc	a3,0x2
ffffffffc02030d8:	28468693          	addi	a3,a3,644 # ffffffffc0205358 <etext+0x14f6>
ffffffffc02030dc:	00001617          	auipc	a2,0x1
ffffffffc02030e0:	75c60613          	addi	a2,a2,1884 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02030e4:	0e900593          	li	a1,233
ffffffffc02030e8:	00002517          	auipc	a0,0x2
ffffffffc02030ec:	1e050513          	addi	a0,a0,480 # ffffffffc02052c8 <etext+0x1466>
ffffffffc02030f0:	b56fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2 != NULL);
ffffffffc02030f4:	00002697          	auipc	a3,0x2
ffffffffc02030f8:	2c468693          	addi	a3,a3,708 # ffffffffc02053b8 <etext+0x1556>
ffffffffc02030fc:	00001617          	auipc	a2,0x1
ffffffffc0203100:	73c60613          	addi	a2,a2,1852 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0203104:	0f400593          	li	a1,244
ffffffffc0203108:	00002517          	auipc	a0,0x2
ffffffffc020310c:	1c050513          	addi	a0,a0,448 # ffffffffc02052c8 <etext+0x1466>
ffffffffc0203110:	b36fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1 != NULL);
ffffffffc0203114:	00002697          	auipc	a3,0x2
ffffffffc0203118:	29468693          	addi	a3,a3,660 # ffffffffc02053a8 <etext+0x1546>
ffffffffc020311c:	00001617          	auipc	a2,0x1
ffffffffc0203120:	71c60613          	addi	a2,a2,1820 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0203124:	0f200593          	li	a1,242
ffffffffc0203128:	00002517          	auipc	a0,0x2
ffffffffc020312c:	1a050513          	addi	a0,a0,416 # ffffffffc02052c8 <etext+0x1466>
ffffffffc0203130:	b16fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma5 == NULL);
ffffffffc0203134:	00002697          	auipc	a3,0x2
ffffffffc0203138:	2b468693          	addi	a3,a3,692 # ffffffffc02053e8 <etext+0x1586>
ffffffffc020313c:	00001617          	auipc	a2,0x1
ffffffffc0203140:	6fc60613          	addi	a2,a2,1788 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0203144:	0fa00593          	li	a1,250
ffffffffc0203148:	00002517          	auipc	a0,0x2
ffffffffc020314c:	18050513          	addi	a0,a0,384 # ffffffffc02052c8 <etext+0x1466>
ffffffffc0203150:	af6fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma4 == NULL);
ffffffffc0203154:	00002697          	auipc	a3,0x2
ffffffffc0203158:	28468693          	addi	a3,a3,644 # ffffffffc02053d8 <etext+0x1576>
ffffffffc020315c:	00001617          	auipc	a2,0x1
ffffffffc0203160:	6dc60613          	addi	a2,a2,1756 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0203164:	0f800593          	li	a1,248
ffffffffc0203168:	00002517          	auipc	a0,0x2
ffffffffc020316c:	16050513          	addi	a0,a0,352 # ffffffffc02052c8 <etext+0x1466>
ffffffffc0203170:	ad6fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma3 == NULL);
ffffffffc0203174:	00002697          	auipc	a3,0x2
ffffffffc0203178:	25468693          	addi	a3,a3,596 # ffffffffc02053c8 <etext+0x1566>
ffffffffc020317c:	00001617          	auipc	a2,0x1
ffffffffc0203180:	6bc60613          	addi	a2,a2,1724 # ffffffffc0204838 <etext+0x9d6>
ffffffffc0203184:	0f600593          	li	a1,246
ffffffffc0203188:	00002517          	auipc	a0,0x2
ffffffffc020318c:	14050513          	addi	a0,a0,320 # ffffffffc02052c8 <etext+0x1466>
ffffffffc0203190:	ab6fd0ef          	jal	ffffffffc0200446 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203194:	6914                	ld	a3,16(a0)
ffffffffc0203196:	6510                	ld	a2,8(a0)
ffffffffc0203198:	0004859b          	sext.w	a1,s1
ffffffffc020319c:	00002517          	auipc	a0,0x2
ffffffffc02031a0:	2bc50513          	addi	a0,a0,700 # ffffffffc0205458 <etext+0x15f6>
ffffffffc02031a4:	ff1fc0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc02031a8:	00002697          	auipc	a3,0x2
ffffffffc02031ac:	2d868693          	addi	a3,a3,728 # ffffffffc0205480 <etext+0x161e>
ffffffffc02031b0:	00001617          	auipc	a2,0x1
ffffffffc02031b4:	68860613          	addi	a2,a2,1672 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02031b8:	10700593          	li	a1,263
ffffffffc02031bc:	00002517          	auipc	a0,0x2
ffffffffc02031c0:	10c50513          	addi	a0,a0,268 # ffffffffc02052c8 <etext+0x1466>
ffffffffc02031c4:	a82fd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02031c8 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc02031c8:	8526                	mv	a0,s1
	jalr s0
ffffffffc02031ca:	9402                	jalr	s0

	jal do_exit
ffffffffc02031cc:	3da000ef          	jal	ffffffffc02035a6 <do_exit>

ffffffffc02031d0 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc02031d0:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02031d2:	0e800513          	li	a0,232
{
ffffffffc02031d6:	e022                	sd	s0,0(sp)
ffffffffc02031d8:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02031da:	883fe0ef          	jal	ffffffffc0201a5c <kmalloc>
ffffffffc02031de:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc02031e0:	c929                	beqz	a0,ffffffffc0203232 <alloc_proc+0x62>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
 	proc->state = PROC_UNINIT;
ffffffffc02031e2:	57fd                	li	a5,-1
ffffffffc02031e4:	1782                	slli	a5,a5,0x20
ffffffffc02031e6:	e11c                	sd	a5,0(a0)
        proc->pid = -1;
        proc->runs = 0;
ffffffffc02031e8:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc02031ec:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc02031f0:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;
ffffffffc02031f4:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc02031f8:	02053423          	sd	zero,40(a0)

        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc02031fc:	07000613          	li	a2,112
ffffffffc0203200:	4581                	li	a1,0
ffffffffc0203202:	03050513          	addi	a0,a0,48
ffffffffc0203206:	40f000ef          	jal	ffffffffc0203e14 <memset>

        proc->tf = NULL;
        proc->pgdir = 0;

        proc->flags = 0;
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc020320a:	4641                	li	a2,16
        proc->tf = NULL;
ffffffffc020320c:	0a043023          	sd	zero,160(s0)
        proc->pgdir = 0;
ffffffffc0203210:	0a043423          	sd	zero,168(s0)
        proc->flags = 0;
ffffffffc0203214:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203218:	4581                	li	a1,0
ffffffffc020321a:	0b440513          	addi	a0,s0,180
ffffffffc020321e:	3f7000ef          	jal	ffffffffc0203e14 <memset>

        // 链表初始化
        list_init(&(proc->list_link));
ffffffffc0203222:	0c840713          	addi	a4,s0,200
        list_init(&(proc->hash_link));
ffffffffc0203226:	0d840793          	addi	a5,s0,216
    elm->prev = elm->next = elm;
ffffffffc020322a:	e878                	sd	a4,208(s0)
ffffffffc020322c:	e478                	sd	a4,200(s0)
ffffffffc020322e:	f07c                	sd	a5,224(s0)
ffffffffc0203230:	ec7c                	sd	a5,216(s0)
        
    }
    return proc;
}
ffffffffc0203232:	60a2                	ld	ra,8(sp)
ffffffffc0203234:	8522                	mv	a0,s0
ffffffffc0203236:	6402                	ld	s0,0(sp)
ffffffffc0203238:	0141                	addi	sp,sp,16
ffffffffc020323a:	8082                	ret

ffffffffc020323c <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc020323c:	0000a797          	auipc	a5,0xa
ffffffffc0203240:	29c7b783          	ld	a5,668(a5) # ffffffffc020d4d8 <current>
ffffffffc0203244:	73c8                	ld	a0,160(a5)
ffffffffc0203246:	b4bfd06f          	j	ffffffffc0200d90 <forkrets>

ffffffffc020324a <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc020324a:	1101                	addi	sp,sp,-32
ffffffffc020324c:	e822                	sd	s0,16(sp)
ffffffffc020324e:	e426                	sd	s1,8(sp)
ffffffffc0203250:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203252:	0000a497          	auipc	s1,0xa
ffffffffc0203256:	2864b483          	ld	s1,646(s1) # ffffffffc020d4d8 <current>
    memset(name, 0, sizeof(name));
ffffffffc020325a:	4641                	li	a2,16
ffffffffc020325c:	4581                	li	a1,0
ffffffffc020325e:	00006517          	auipc	a0,0x6
ffffffffc0203262:	1ea50513          	addi	a0,a0,490 # ffffffffc0209448 <name.2>
{
ffffffffc0203266:	ec06                	sd	ra,24(sp)
ffffffffc0203268:	e04a                	sd	s2,0(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020326a:	0044a903          	lw	s2,4(s1)
    memset(name, 0, sizeof(name));
ffffffffc020326e:	3a7000ef          	jal	ffffffffc0203e14 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc0203272:	0b448593          	addi	a1,s1,180
ffffffffc0203276:	463d                	li	a2,15
ffffffffc0203278:	00006517          	auipc	a0,0x6
ffffffffc020327c:	1d050513          	addi	a0,a0,464 # ffffffffc0209448 <name.2>
ffffffffc0203280:	3a7000ef          	jal	ffffffffc0203e26 <memcpy>
ffffffffc0203284:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203286:	85ca                	mv	a1,s2
ffffffffc0203288:	00002517          	auipc	a0,0x2
ffffffffc020328c:	24850513          	addi	a0,a0,584 # ffffffffc02054d0 <etext+0x166e>
ffffffffc0203290:	f05fc0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc0203294:	85a2                	mv	a1,s0
ffffffffc0203296:	00002517          	auipc	a0,0x2
ffffffffc020329a:	26250513          	addi	a0,a0,610 # ffffffffc02054f8 <etext+0x1696>
ffffffffc020329e:	ef7fc0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc02032a2:	00002517          	auipc	a0,0x2
ffffffffc02032a6:	26650513          	addi	a0,a0,614 # ffffffffc0205508 <etext+0x16a6>
ffffffffc02032aa:	eebfc0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02032ae:	60e2                	ld	ra,24(sp)
ffffffffc02032b0:	6442                	ld	s0,16(sp)
ffffffffc02032b2:	64a2                	ld	s1,8(sp)
ffffffffc02032b4:	6902                	ld	s2,0(sp)
ffffffffc02032b6:	4501                	li	a0,0
ffffffffc02032b8:	6105                	addi	sp,sp,32
ffffffffc02032ba:	8082                	ret

ffffffffc02032bc <proc_run>:
{
ffffffffc02032bc:	7179                	addi	sp,sp,-48
ffffffffc02032be:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc02032c0:	0000a917          	auipc	s2,0xa
ffffffffc02032c4:	21890913          	addi	s2,s2,536 # ffffffffc020d4d8 <current>
{
ffffffffc02032c8:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc02032ca:	00093483          	ld	s1,0(s2)
{
ffffffffc02032ce:	f406                	sd	ra,40(sp)
    if (proc != current)
ffffffffc02032d0:	02a48b63          	beq	s1,a0,ffffffffc0203306 <proc_run+0x4a>
ffffffffc02032d4:	e84e                	sd	s3,16(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02032d6:	100027f3          	csrr	a5,sstatus
ffffffffc02032da:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02032dc:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02032de:	e3a1                	bnez	a5,ffffffffc020331e <proc_run+0x62>
            lsatp(proc->pgdir);
ffffffffc02032e0:	755c                	ld	a5,168(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc02032e2:	80000737          	lui	a4,0x80000
            current = proc;
ffffffffc02032e6:	00a93023          	sd	a0,0(s2)
ffffffffc02032ea:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc02032ee:	8fd9                	or	a5,a5,a4
ffffffffc02032f0:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(proc->context));
ffffffffc02032f4:	03050593          	addi	a1,a0,48
ffffffffc02032f8:	03048513          	addi	a0,s1,48
ffffffffc02032fc:	52c000ef          	jal	ffffffffc0203828 <switch_to>
    if (flag) {
ffffffffc0203300:	00099863          	bnez	s3,ffffffffc0203310 <proc_run+0x54>
ffffffffc0203304:	69c2                	ld	s3,16(sp)
}
ffffffffc0203306:	70a2                	ld	ra,40(sp)
ffffffffc0203308:	7482                	ld	s1,32(sp)
ffffffffc020330a:	6962                	ld	s2,24(sp)
ffffffffc020330c:	6145                	addi	sp,sp,48
ffffffffc020330e:	8082                	ret
        intr_enable();
ffffffffc0203310:	69c2                	ld	s3,16(sp)
ffffffffc0203312:	70a2                	ld	ra,40(sp)
ffffffffc0203314:	7482                	ld	s1,32(sp)
ffffffffc0203316:	6962                	ld	s2,24(sp)
ffffffffc0203318:	6145                	addi	sp,sp,48
ffffffffc020331a:	dcafd06f          	j	ffffffffc02008e4 <intr_enable>
ffffffffc020331e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203320:	dcafd0ef          	jal	ffffffffc02008ea <intr_disable>
        return 1;
ffffffffc0203324:	6522                	ld	a0,8(sp)
ffffffffc0203326:	4985                	li	s3,1
ffffffffc0203328:	bf65                	j	ffffffffc02032e0 <proc_run+0x24>

ffffffffc020332a <do_fork>:
{
ffffffffc020332a:	7179                	addi	sp,sp,-48
ffffffffc020332c:	ec26                	sd	s1,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020332e:	0000a497          	auipc	s1,0xa
ffffffffc0203332:	1a248493          	addi	s1,s1,418 # ffffffffc020d4d0 <nr_process>
ffffffffc0203336:	4098                	lw	a4,0(s1)
{
ffffffffc0203338:	f406                	sd	ra,40(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020333a:	6785                	lui	a5,0x1
ffffffffc020333c:	1cf75f63          	bge	a4,a5,ffffffffc020351a <do_fork+0x1f0>
ffffffffc0203340:	f022                	sd	s0,32(sp)
ffffffffc0203342:	e84a                	sd	s2,16(sp)
ffffffffc0203344:	e44e                	sd	s3,8(sp)
ffffffffc0203346:	892e                	mv	s2,a1
ffffffffc0203348:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc020334a:	e87ff0ef          	jal	ffffffffc02031d0 <alloc_proc>
ffffffffc020334e:	89aa                	mv	s3,a0
ffffffffc0203350:	1c050063          	beqz	a0,ffffffffc0203510 <do_fork+0x1e6>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203354:	4509                	li	a0,2
ffffffffc0203356:	8dffe0ef          	jal	ffffffffc0201c34 <alloc_pages>
    if (page != NULL)
ffffffffc020335a:	1a050863          	beqz	a0,ffffffffc020350a <do_fork+0x1e0>
    return page - pages + nbase;
ffffffffc020335e:	0000a797          	auipc	a5,0xa
ffffffffc0203362:	16a7b783          	ld	a5,362(a5) # ffffffffc020d4c8 <pages>
ffffffffc0203366:	40f506b3          	sub	a3,a0,a5
ffffffffc020336a:	8699                	srai	a3,a3,0x6
ffffffffc020336c:	00002797          	auipc	a5,0x2
ffffffffc0203370:	64c7b783          	ld	a5,1612(a5) # ffffffffc02059b8 <nbase>
ffffffffc0203374:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0203376:	00c69793          	slli	a5,a3,0xc
ffffffffc020337a:	83b1                	srli	a5,a5,0xc
ffffffffc020337c:	0000a717          	auipc	a4,0xa
ffffffffc0203380:	14473703          	ld	a4,324(a4) # ffffffffc020d4c0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0203384:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203386:	1ae7fc63          	bgeu	a5,a4,ffffffffc020353e <do_fork+0x214>
    assert(current->mm == NULL);
ffffffffc020338a:	0000a317          	auipc	t1,0xa
ffffffffc020338e:	14e33303          	ld	t1,334(t1) # ffffffffc020d4d8 <current>
ffffffffc0203392:	02833783          	ld	a5,40(t1)
ffffffffc0203396:	0000a717          	auipc	a4,0xa
ffffffffc020339a:	12273703          	ld	a4,290(a4) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc020339e:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02033a0:	00d9b823          	sd	a3,16(s3)
    assert(current->mm == NULL);
ffffffffc02033a4:	16079d63          	bnez	a5,ffffffffc020351e <do_fork+0x1f4>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033a8:	6789                	lui	a5,0x2
ffffffffc02033aa:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc02033ae:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02033b0:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033b2:	0ad9b023          	sd	a3,160(s3)
    *(proc->tf) = *tf;
ffffffffc02033b6:	87b6                	mv	a5,a3
ffffffffc02033b8:	12040893          	addi	a7,s0,288
ffffffffc02033bc:	00063803          	ld	a6,0(a2)
ffffffffc02033c0:	6608                	ld	a0,8(a2)
ffffffffc02033c2:	6a0c                	ld	a1,16(a2)
ffffffffc02033c4:	6e18                	ld	a4,24(a2)
ffffffffc02033c6:	0107b023          	sd	a6,0(a5)
ffffffffc02033ca:	e788                	sd	a0,8(a5)
ffffffffc02033cc:	eb8c                	sd	a1,16(a5)
ffffffffc02033ce:	ef98                	sd	a4,24(a5)
ffffffffc02033d0:	02060613          	addi	a2,a2,32
ffffffffc02033d4:	02078793          	addi	a5,a5,32
ffffffffc02033d8:	ff1612e3          	bne	a2,a7,ffffffffc02033bc <do_fork+0x92>
    proc->tf->gpr.a0 = 0;
ffffffffc02033dc:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02033e0:	10090d63          	beqz	s2,ffffffffc02034fa <do_fork+0x1d0>
    if (++last_pid >= MAX_PID)
ffffffffc02033e4:	00006817          	auipc	a6,0x6
ffffffffc02033e8:	c4880813          	addi	a6,a6,-952 # ffffffffc020902c <last_pid.1>
ffffffffc02033ec:	00082783          	lw	a5,0(a6)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02033f0:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02033f4:	00000717          	auipc	a4,0x0
ffffffffc02033f8:	e4870713          	addi	a4,a4,-440 # ffffffffc020323c <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc02033fc:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203400:	02e9b823          	sd	a4,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203404:	02d9bc23          	sd	a3,56(s3)
    if (++last_pid >= MAX_PID)
ffffffffc0203408:	00a82023          	sw	a0,0(a6)
ffffffffc020340c:	6789                	lui	a5,0x2
ffffffffc020340e:	08f55063          	bge	a0,a5,ffffffffc020348e <do_fork+0x164>
    if (last_pid >= next_safe)
ffffffffc0203412:	00006e17          	auipc	t3,0x6
ffffffffc0203416:	c16e0e13          	addi	t3,t3,-1002 # ffffffffc0209028 <next_safe.0>
ffffffffc020341a:	000e2783          	lw	a5,0(t3)
ffffffffc020341e:	0000a417          	auipc	s0,0xa
ffffffffc0203422:	03a40413          	addi	s0,s0,58 # ffffffffc020d458 <proc_list>
ffffffffc0203426:	06f55c63          	bge	a0,a5,ffffffffc020349e <do_fork+0x174>
    proc->pid = get_pid();
ffffffffc020342a:	00a9a223          	sw	a0,4(s3)
    proc->parent = current;
ffffffffc020342e:	0269b023          	sd	t1,32(s3)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203432:	45a9                	li	a1,10
ffffffffc0203434:	2501                	sext.w	a0,a0
ffffffffc0203436:	522000ef          	jal	ffffffffc0203958 <hash32>
ffffffffc020343a:	02051793          	slli	a5,a0,0x20
ffffffffc020343e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0203442:	00006797          	auipc	a5,0x6
ffffffffc0203446:	01678793          	addi	a5,a5,22 # ffffffffc0209458 <hash_list>
ffffffffc020344a:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020344c:	6510                	ld	a2,8(a0)
ffffffffc020344e:	0d898793          	addi	a5,s3,216
ffffffffc0203452:	6414                	ld	a3,8(s0)
    prev->next = next->prev = elm;
ffffffffc0203454:	e21c                	sd	a5,0(a2)
ffffffffc0203456:	e51c                	sd	a5,8(a0)
    nr_process++;
ffffffffc0203458:	409c                	lw	a5,0(s1)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020345a:	0c898713          	addi	a4,s3,200
    elm->prev = prev;
ffffffffc020345e:	0ca9bc23          	sd	a0,216(s3)
    elm->next = next;
ffffffffc0203462:	0ec9b023          	sd	a2,224(s3)
    prev->next = next->prev = elm;
ffffffffc0203466:	e298                	sd	a4,0(a3)
    elm->prev = prev;
ffffffffc0203468:	0c89b423          	sd	s0,200(s3)
    wakeup_proc(proc);
ffffffffc020346c:	854e                	mv	a0,s3
    nr_process++;
ffffffffc020346e:	2785                	addiw	a5,a5,1
    elm->next = next;
ffffffffc0203470:	0cd9b823          	sd	a3,208(s3)
    prev->next = next->prev = elm;
ffffffffc0203474:	e418                	sd	a4,8(s0)
ffffffffc0203476:	c09c                	sw	a5,0(s1)
    wakeup_proc(proc);
ffffffffc0203478:	41a000ef          	jal	ffffffffc0203892 <wakeup_proc>
    ret = proc->pid;
ffffffffc020347c:	0049a503          	lw	a0,4(s3)
ffffffffc0203480:	7402                	ld	s0,32(sp)
ffffffffc0203482:	6942                	ld	s2,16(sp)
ffffffffc0203484:	69a2                	ld	s3,8(sp)
}
ffffffffc0203486:	70a2                	ld	ra,40(sp)
ffffffffc0203488:	64e2                	ld	s1,24(sp)
ffffffffc020348a:	6145                	addi	sp,sp,48
ffffffffc020348c:	8082                	ret
        last_pid = 1;
ffffffffc020348e:	4785                	li	a5,1
ffffffffc0203490:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc0203494:	4505                	li	a0,1
ffffffffc0203496:	00006e17          	auipc	t3,0x6
ffffffffc020349a:	b92e0e13          	addi	t3,t3,-1134 # ffffffffc0209028 <next_safe.0>
    return listelm->next;
ffffffffc020349e:	0000a417          	auipc	s0,0xa
ffffffffc02034a2:	fba40413          	addi	s0,s0,-70 # ffffffffc020d458 <proc_list>
ffffffffc02034a6:	00843e83          	ld	t4,8(s0)
        next_safe = MAX_PID;
ffffffffc02034aa:	6789                	lui	a5,0x2
ffffffffc02034ac:	00fe2023          	sw	a5,0(t3)
ffffffffc02034b0:	86aa                	mv	a3,a0
ffffffffc02034b2:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02034b4:	028e8e63          	beq	t4,s0,ffffffffc02034f0 <do_fork+0x1c6>
ffffffffc02034b8:	88ae                	mv	a7,a1
ffffffffc02034ba:	87f6                	mv	a5,t4
ffffffffc02034bc:	6609                	lui	a2,0x2
ffffffffc02034be:	a811                	j	ffffffffc02034d2 <do_fork+0x1a8>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02034c0:	00e6d663          	bge	a3,a4,ffffffffc02034cc <do_fork+0x1a2>
ffffffffc02034c4:	00c75463          	bge	a4,a2,ffffffffc02034cc <do_fork+0x1a2>
                next_safe = proc->pid;
ffffffffc02034c8:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02034ca:	4885                	li	a7,1
ffffffffc02034cc:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02034ce:	00878d63          	beq	a5,s0,ffffffffc02034e8 <do_fork+0x1be>
            if (proc->pid == last_pid)
ffffffffc02034d2:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc02034d6:	fed715e3          	bne	a4,a3,ffffffffc02034c0 <do_fork+0x196>
                if (++last_pid >= next_safe)
ffffffffc02034da:	2685                	addiw	a3,a3,1
ffffffffc02034dc:	02c6d163          	bge	a3,a2,ffffffffc02034fe <do_fork+0x1d4>
ffffffffc02034e0:	679c                	ld	a5,8(a5)
ffffffffc02034e2:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02034e4:	fe8797e3          	bne	a5,s0,ffffffffc02034d2 <do_fork+0x1a8>
ffffffffc02034e8:	00088463          	beqz	a7,ffffffffc02034f0 <do_fork+0x1c6>
ffffffffc02034ec:	00ce2023          	sw	a2,0(t3)
ffffffffc02034f0:	dd8d                	beqz	a1,ffffffffc020342a <do_fork+0x100>
ffffffffc02034f2:	00d82023          	sw	a3,0(a6)
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02034f6:	8536                	mv	a0,a3
ffffffffc02034f8:	bf0d                	j	ffffffffc020342a <do_fork+0x100>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02034fa:	8936                	mv	s2,a3
ffffffffc02034fc:	b5e5                	j	ffffffffc02033e4 <do_fork+0xba>
                    if (last_pid >= MAX_PID)
ffffffffc02034fe:	6789                	lui	a5,0x2
ffffffffc0203500:	00f6c363          	blt	a3,a5,ffffffffc0203506 <do_fork+0x1dc>
                        last_pid = 1;
ffffffffc0203504:	4685                	li	a3,1
                    goto repeat;
ffffffffc0203506:	4585                	li	a1,1
ffffffffc0203508:	b775                	j	ffffffffc02034b4 <do_fork+0x18a>
    kfree(proc);
ffffffffc020350a:	854e                	mv	a0,s3
ffffffffc020350c:	dfafe0ef          	jal	ffffffffc0201b06 <kfree>
    goto fork_out;
ffffffffc0203510:	7402                	ld	s0,32(sp)
ffffffffc0203512:	6942                	ld	s2,16(sp)
ffffffffc0203514:	69a2                	ld	s3,8(sp)
    ret = -E_NO_MEM;
ffffffffc0203516:	5571                	li	a0,-4
ffffffffc0203518:	b7bd                	j	ffffffffc0203486 <do_fork+0x15c>
    int ret = -E_NO_FREE_PROC;
ffffffffc020351a:	556d                	li	a0,-5
ffffffffc020351c:	b7ad                	j	ffffffffc0203486 <do_fork+0x15c>
    assert(current->mm == NULL);
ffffffffc020351e:	00002697          	auipc	a3,0x2
ffffffffc0203522:	00a68693          	addi	a3,a3,10 # ffffffffc0205528 <etext+0x16c6>
ffffffffc0203526:	00001617          	auipc	a2,0x1
ffffffffc020352a:	31260613          	addi	a2,a2,786 # ffffffffc0204838 <etext+0x9d6>
ffffffffc020352e:	12a00593          	li	a1,298
ffffffffc0203532:	00002517          	auipc	a0,0x2
ffffffffc0203536:	00e50513          	addi	a0,a0,14 # ffffffffc0205540 <etext+0x16de>
ffffffffc020353a:	f0dfc0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc020353e:	00001617          	auipc	a2,0x1
ffffffffc0203542:	6aa60613          	addi	a2,a2,1706 # ffffffffc0204be8 <etext+0xd86>
ffffffffc0203546:	07100593          	li	a1,113
ffffffffc020354a:	00001517          	auipc	a0,0x1
ffffffffc020354e:	6c650513          	addi	a0,a0,1734 # ffffffffc0204c10 <etext+0xdae>
ffffffffc0203552:	ef5fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203556 <kernel_thread>:
{
ffffffffc0203556:	7129                	addi	sp,sp,-320
ffffffffc0203558:	fa22                	sd	s0,304(sp)
ffffffffc020355a:	f626                	sd	s1,296(sp)
ffffffffc020355c:	f24a                	sd	s2,288(sp)
ffffffffc020355e:	84ae                	mv	s1,a1
ffffffffc0203560:	892a                	mv	s2,a0
ffffffffc0203562:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0203564:	4581                	li	a1,0
ffffffffc0203566:	12000613          	li	a2,288
ffffffffc020356a:	850a                	mv	a0,sp
{
ffffffffc020356c:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020356e:	0a7000ef          	jal	ffffffffc0203e14 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0203572:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0203574:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0203576:	100027f3          	csrr	a5,sstatus
ffffffffc020357a:	edd7f793          	andi	a5,a5,-291
ffffffffc020357e:	1207e793          	ori	a5,a5,288
ffffffffc0203582:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203584:	860a                	mv	a2,sp
ffffffffc0203586:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020358a:	00000797          	auipc	a5,0x0
ffffffffc020358e:	c3e78793          	addi	a5,a5,-962 # ffffffffc02031c8 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203592:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0203594:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203596:	d95ff0ef          	jal	ffffffffc020332a <do_fork>
}
ffffffffc020359a:	70f2                	ld	ra,312(sp)
ffffffffc020359c:	7452                	ld	s0,304(sp)
ffffffffc020359e:	74b2                	ld	s1,296(sp)
ffffffffc02035a0:	7912                	ld	s2,288(sp)
ffffffffc02035a2:	6131                	addi	sp,sp,320
ffffffffc02035a4:	8082                	ret

ffffffffc02035a6 <do_exit>:
{
ffffffffc02035a6:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc02035a8:	00002617          	auipc	a2,0x2
ffffffffc02035ac:	fb060613          	addi	a2,a2,-80 # ffffffffc0205558 <etext+0x16f6>
ffffffffc02035b0:	19b00593          	li	a1,411
ffffffffc02035b4:	00002517          	auipc	a0,0x2
ffffffffc02035b8:	f8c50513          	addi	a0,a0,-116 # ffffffffc0205540 <etext+0x16de>
{
ffffffffc02035bc:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc02035be:	e89fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02035c2 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc02035c2:	7179                	addi	sp,sp,-48
ffffffffc02035c4:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc02035c6:	0000a797          	auipc	a5,0xa
ffffffffc02035ca:	e9278793          	addi	a5,a5,-366 # ffffffffc020d458 <proc_list>
ffffffffc02035ce:	f406                	sd	ra,40(sp)
ffffffffc02035d0:	f022                	sd	s0,32(sp)
ffffffffc02035d2:	e84a                	sd	s2,16(sp)
ffffffffc02035d4:	e44e                	sd	s3,8(sp)
ffffffffc02035d6:	00006497          	auipc	s1,0x6
ffffffffc02035da:	e8248493          	addi	s1,s1,-382 # ffffffffc0209458 <hash_list>
ffffffffc02035de:	e79c                	sd	a5,8(a5)
ffffffffc02035e0:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc02035e2:	0000a717          	auipc	a4,0xa
ffffffffc02035e6:	e7670713          	addi	a4,a4,-394 # ffffffffc020d458 <proc_list>
ffffffffc02035ea:	87a6                	mv	a5,s1
ffffffffc02035ec:	e79c                	sd	a5,8(a5)
ffffffffc02035ee:	e39c                	sd	a5,0(a5)
ffffffffc02035f0:	07c1                	addi	a5,a5,16
ffffffffc02035f2:	fee79de3          	bne	a5,a4,ffffffffc02035ec <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc02035f6:	bdbff0ef          	jal	ffffffffc02031d0 <alloc_proc>
ffffffffc02035fa:	0000a917          	auipc	s2,0xa
ffffffffc02035fe:	eee90913          	addi	s2,s2,-274 # ffffffffc020d4e8 <idleproc>
ffffffffc0203602:	00a93023          	sd	a0,0(s2)
ffffffffc0203606:	18050c63          	beqz	a0,ffffffffc020379e <proc_init+0x1dc>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc020360a:	07000513          	li	a0,112
ffffffffc020360e:	c4efe0ef          	jal	ffffffffc0201a5c <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203612:	07000613          	li	a2,112
ffffffffc0203616:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203618:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc020361a:	7fa000ef          	jal	ffffffffc0203e14 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc020361e:	00093503          	ld	a0,0(s2)
ffffffffc0203622:	85a2                	mv	a1,s0
ffffffffc0203624:	07000613          	li	a2,112
ffffffffc0203628:	03050513          	addi	a0,a0,48
ffffffffc020362c:	013000ef          	jal	ffffffffc0203e3e <memcmp>
ffffffffc0203630:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0203632:	453d                	li	a0,15
ffffffffc0203634:	c28fe0ef          	jal	ffffffffc0201a5c <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0203638:	463d                	li	a2,15
ffffffffc020363a:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc020363c:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc020363e:	7d6000ef          	jal	ffffffffc0203e14 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc0203642:	00093503          	ld	a0,0(s2)
ffffffffc0203646:	463d                	li	a2,15
ffffffffc0203648:	85a2                	mv	a1,s0
ffffffffc020364a:	0b450513          	addi	a0,a0,180
ffffffffc020364e:	7f0000ef          	jal	ffffffffc0203e3e <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc0203652:	00093783          	ld	a5,0(s2)
ffffffffc0203656:	0000a717          	auipc	a4,0xa
ffffffffc020365a:	e5273703          	ld	a4,-430(a4) # ffffffffc020d4a8 <boot_pgdir_pa>
ffffffffc020365e:	77d4                	ld	a3,168(a5)
ffffffffc0203660:	0ee68563          	beq	a3,a4,ffffffffc020374a <proc_init+0x188>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0203664:	4709                	li	a4,2
ffffffffc0203666:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0203668:	00003717          	auipc	a4,0x3
ffffffffc020366c:	99870713          	addi	a4,a4,-1640 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203670:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0203674:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc0203676:	4705                	li	a4,1
ffffffffc0203678:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020367a:	4641                	li	a2,16
ffffffffc020367c:	4581                	li	a1,0
ffffffffc020367e:	8522                	mv	a0,s0
ffffffffc0203680:	794000ef          	jal	ffffffffc0203e14 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203684:	463d                	li	a2,15
ffffffffc0203686:	00002597          	auipc	a1,0x2
ffffffffc020368a:	f1a58593          	addi	a1,a1,-230 # ffffffffc02055a0 <etext+0x173e>
ffffffffc020368e:	8522                	mv	a0,s0
ffffffffc0203690:	796000ef          	jal	ffffffffc0203e26 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0203694:	0000a717          	auipc	a4,0xa
ffffffffc0203698:	e3c70713          	addi	a4,a4,-452 # ffffffffc020d4d0 <nr_process>
ffffffffc020369c:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc020369e:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036a2:	4601                	li	a2,0
    nr_process++;
ffffffffc02036a4:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036a6:	00002597          	auipc	a1,0x2
ffffffffc02036aa:	f0258593          	addi	a1,a1,-254 # ffffffffc02055a8 <etext+0x1746>
ffffffffc02036ae:	00000517          	auipc	a0,0x0
ffffffffc02036b2:	b9c50513          	addi	a0,a0,-1124 # ffffffffc020324a <init_main>
    nr_process++;
ffffffffc02036b6:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc02036b8:	0000a797          	auipc	a5,0xa
ffffffffc02036bc:	e2d7b023          	sd	a3,-480(a5) # ffffffffc020d4d8 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036c0:	e97ff0ef          	jal	ffffffffc0203556 <kernel_thread>
ffffffffc02036c4:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc02036c6:	0ea05863          	blez	a0,ffffffffc02037b6 <proc_init+0x1f4>
    if (0 < pid && pid < MAX_PID)
ffffffffc02036ca:	6789                	lui	a5,0x2
ffffffffc02036cc:	fff5071b          	addiw	a4,a0,-1
ffffffffc02036d0:	17f9                	addi	a5,a5,-2 # 1ffe <kern_entry-0xffffffffc01fe002>
ffffffffc02036d2:	2501                	sext.w	a0,a0
ffffffffc02036d4:	02e7e463          	bltu	a5,a4,ffffffffc02036fc <proc_init+0x13a>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02036d8:	45a9                	li	a1,10
ffffffffc02036da:	27e000ef          	jal	ffffffffc0203958 <hash32>
ffffffffc02036de:	02051713          	slli	a4,a0,0x20
ffffffffc02036e2:	01c75793          	srli	a5,a4,0x1c
ffffffffc02036e6:	00f486b3          	add	a3,s1,a5
ffffffffc02036ea:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02036ec:	a029                	j	ffffffffc02036f6 <proc_init+0x134>
            if (proc->pid == pid)
ffffffffc02036ee:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02036f2:	0a870363          	beq	a4,s0,ffffffffc0203798 <proc_init+0x1d6>
    return listelm->next;
ffffffffc02036f6:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02036f8:	fef69be3          	bne	a3,a5,ffffffffc02036ee <proc_init+0x12c>
    return NULL;
ffffffffc02036fc:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036fe:	0b478493          	addi	s1,a5,180
ffffffffc0203702:	4641                	li	a2,16
ffffffffc0203704:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0203706:	0000a417          	auipc	s0,0xa
ffffffffc020370a:	dda40413          	addi	s0,s0,-550 # ffffffffc020d4e0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020370e:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0203710:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203712:	702000ef          	jal	ffffffffc0203e14 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203716:	463d                	li	a2,15
ffffffffc0203718:	00002597          	auipc	a1,0x2
ffffffffc020371c:	ec058593          	addi	a1,a1,-320 # ffffffffc02055d8 <etext+0x1776>
ffffffffc0203720:	8526                	mv	a0,s1
ffffffffc0203722:	704000ef          	jal	ffffffffc0203e26 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203726:	00093783          	ld	a5,0(s2)
ffffffffc020372a:	c3f1                	beqz	a5,ffffffffc02037ee <proc_init+0x22c>
ffffffffc020372c:	43dc                	lw	a5,4(a5)
ffffffffc020372e:	e3e1                	bnez	a5,ffffffffc02037ee <proc_init+0x22c>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203730:	601c                	ld	a5,0(s0)
ffffffffc0203732:	cfd1                	beqz	a5,ffffffffc02037ce <proc_init+0x20c>
ffffffffc0203734:	43d8                	lw	a4,4(a5)
ffffffffc0203736:	4785                	li	a5,1
ffffffffc0203738:	08f71b63          	bne	a4,a5,ffffffffc02037ce <proc_init+0x20c>
}
ffffffffc020373c:	70a2                	ld	ra,40(sp)
ffffffffc020373e:	7402                	ld	s0,32(sp)
ffffffffc0203740:	64e2                	ld	s1,24(sp)
ffffffffc0203742:	6942                	ld	s2,16(sp)
ffffffffc0203744:	69a2                	ld	s3,8(sp)
ffffffffc0203746:	6145                	addi	sp,sp,48
ffffffffc0203748:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc020374a:	73d8                	ld	a4,160(a5)
ffffffffc020374c:	ff01                	bnez	a4,ffffffffc0203664 <proc_init+0xa2>
ffffffffc020374e:	f0099be3          	bnez	s3,ffffffffc0203664 <proc_init+0xa2>
ffffffffc0203752:	6394                	ld	a3,0(a5)
ffffffffc0203754:	577d                	li	a4,-1
ffffffffc0203756:	1702                	slli	a4,a4,0x20
ffffffffc0203758:	f0e696e3          	bne	a3,a4,ffffffffc0203664 <proc_init+0xa2>
ffffffffc020375c:	4798                	lw	a4,8(a5)
ffffffffc020375e:	f00713e3          	bnez	a4,ffffffffc0203664 <proc_init+0xa2>
ffffffffc0203762:	6b98                	ld	a4,16(a5)
ffffffffc0203764:	f00710e3          	bnez	a4,ffffffffc0203664 <proc_init+0xa2>
ffffffffc0203768:	4f98                	lw	a4,24(a5)
ffffffffc020376a:	ee071de3          	bnez	a4,ffffffffc0203664 <proc_init+0xa2>
ffffffffc020376e:	7398                	ld	a4,32(a5)
ffffffffc0203770:	ee071ae3          	bnez	a4,ffffffffc0203664 <proc_init+0xa2>
ffffffffc0203774:	7798                	ld	a4,40(a5)
ffffffffc0203776:	ee0717e3          	bnez	a4,ffffffffc0203664 <proc_init+0xa2>
ffffffffc020377a:	0b07a703          	lw	a4,176(a5)
ffffffffc020377e:	8f49                	or	a4,a4,a0
ffffffffc0203780:	2701                	sext.w	a4,a4
ffffffffc0203782:	ee0711e3          	bnez	a4,ffffffffc0203664 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc0203786:	00002517          	auipc	a0,0x2
ffffffffc020378a:	e0250513          	addi	a0,a0,-510 # ffffffffc0205588 <etext+0x1726>
ffffffffc020378e:	a07fc0ef          	jal	ffffffffc0200194 <cprintf>
    idleproc->pid = 0;
ffffffffc0203792:	00093783          	ld	a5,0(s2)
ffffffffc0203796:	b5f9                	j	ffffffffc0203664 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0203798:	f2878793          	addi	a5,a5,-216
ffffffffc020379c:	b78d                	j	ffffffffc02036fe <proc_init+0x13c>
        panic("cannot alloc idleproc.\n");
ffffffffc020379e:	00002617          	auipc	a2,0x2
ffffffffc02037a2:	dd260613          	addi	a2,a2,-558 # ffffffffc0205570 <etext+0x170e>
ffffffffc02037a6:	1b600593          	li	a1,438
ffffffffc02037aa:	00002517          	auipc	a0,0x2
ffffffffc02037ae:	d9650513          	addi	a0,a0,-618 # ffffffffc0205540 <etext+0x16de>
ffffffffc02037b2:	c95fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("create init_main failed.\n");
ffffffffc02037b6:	00002617          	auipc	a2,0x2
ffffffffc02037ba:	e0260613          	addi	a2,a2,-510 # ffffffffc02055b8 <etext+0x1756>
ffffffffc02037be:	1d300593          	li	a1,467
ffffffffc02037c2:	00002517          	auipc	a0,0x2
ffffffffc02037c6:	d7e50513          	addi	a0,a0,-642 # ffffffffc0205540 <etext+0x16de>
ffffffffc02037ca:	c7dfc0ef          	jal	ffffffffc0200446 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02037ce:	00002697          	auipc	a3,0x2
ffffffffc02037d2:	e3a68693          	addi	a3,a3,-454 # ffffffffc0205608 <etext+0x17a6>
ffffffffc02037d6:	00001617          	auipc	a2,0x1
ffffffffc02037da:	06260613          	addi	a2,a2,98 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02037de:	1da00593          	li	a1,474
ffffffffc02037e2:	00002517          	auipc	a0,0x2
ffffffffc02037e6:	d5e50513          	addi	a0,a0,-674 # ffffffffc0205540 <etext+0x16de>
ffffffffc02037ea:	c5dfc0ef          	jal	ffffffffc0200446 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02037ee:	00002697          	auipc	a3,0x2
ffffffffc02037f2:	df268693          	addi	a3,a3,-526 # ffffffffc02055e0 <etext+0x177e>
ffffffffc02037f6:	00001617          	auipc	a2,0x1
ffffffffc02037fa:	04260613          	addi	a2,a2,66 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02037fe:	1d900593          	li	a1,473
ffffffffc0203802:	00002517          	auipc	a0,0x2
ffffffffc0203806:	d3e50513          	addi	a0,a0,-706 # ffffffffc0205540 <etext+0x16de>
ffffffffc020380a:	c3dfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020380e <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc020380e:	1141                	addi	sp,sp,-16
ffffffffc0203810:	e022                	sd	s0,0(sp)
ffffffffc0203812:	e406                	sd	ra,8(sp)
ffffffffc0203814:	0000a417          	auipc	s0,0xa
ffffffffc0203818:	cc440413          	addi	s0,s0,-828 # ffffffffc020d4d8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc020381c:	6018                	ld	a4,0(s0)
ffffffffc020381e:	4f1c                	lw	a5,24(a4)
ffffffffc0203820:	dffd                	beqz	a5,ffffffffc020381e <cpu_idle+0x10>
        {
            schedule();
ffffffffc0203822:	0a2000ef          	jal	ffffffffc02038c4 <schedule>
ffffffffc0203826:	bfdd                	j	ffffffffc020381c <cpu_idle+0xe>

ffffffffc0203828 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0203828:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020382c:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0203830:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0203832:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0203834:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0203838:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc020383c:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0203840:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0203844:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0203848:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc020384c:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0203850:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0203854:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0203858:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc020385c:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0203860:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0203864:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0203866:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0203868:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc020386c:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0203870:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0203874:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0203878:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc020387c:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0203880:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0203884:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0203888:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc020388c:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0203890:	8082                	ret

ffffffffc0203892 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203892:	411c                	lw	a5,0(a0)
ffffffffc0203894:	4705                	li	a4,1
ffffffffc0203896:	37f9                	addiw	a5,a5,-2
ffffffffc0203898:	00f77563          	bgeu	a4,a5,ffffffffc02038a2 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc020389c:	4789                	li	a5,2
ffffffffc020389e:	c11c                	sw	a5,0(a0)
ffffffffc02038a0:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc02038a2:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038a4:	00002697          	auipc	a3,0x2
ffffffffc02038a8:	d8c68693          	addi	a3,a3,-628 # ffffffffc0205630 <etext+0x17ce>
ffffffffc02038ac:	00001617          	auipc	a2,0x1
ffffffffc02038b0:	f8c60613          	addi	a2,a2,-116 # ffffffffc0204838 <etext+0x9d6>
ffffffffc02038b4:	45a5                	li	a1,9
ffffffffc02038b6:	00002517          	auipc	a0,0x2
ffffffffc02038ba:	dba50513          	addi	a0,a0,-582 # ffffffffc0205670 <etext+0x180e>
wakeup_proc(struct proc_struct *proc) {
ffffffffc02038be:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038c0:	b87fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02038c4 <schedule>:
}

void
schedule(void) {
ffffffffc02038c4:	1141                	addi	sp,sp,-16
ffffffffc02038c6:	e406                	sd	ra,8(sp)
ffffffffc02038c8:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02038ca:	100027f3          	csrr	a5,sstatus
ffffffffc02038ce:	8b89                	andi	a5,a5,2
ffffffffc02038d0:	4401                	li	s0,0
ffffffffc02038d2:	efbd                	bnez	a5,ffffffffc0203950 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02038d4:	0000a897          	auipc	a7,0xa
ffffffffc02038d8:	c048b883          	ld	a7,-1020(a7) # ffffffffc020d4d8 <current>
ffffffffc02038dc:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02038e0:	0000a517          	auipc	a0,0xa
ffffffffc02038e4:	c0853503          	ld	a0,-1016(a0) # ffffffffc020d4e8 <idleproc>
ffffffffc02038e8:	04a88e63          	beq	a7,a0,ffffffffc0203944 <schedule+0x80>
ffffffffc02038ec:	0c888693          	addi	a3,a7,200
ffffffffc02038f0:	0000a617          	auipc	a2,0xa
ffffffffc02038f4:	b6860613          	addi	a2,a2,-1176 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc02038f8:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02038fa:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc02038fc:	4809                	li	a6,2
ffffffffc02038fe:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0203900:	00c78863          	beq	a5,a2,ffffffffc0203910 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203904:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0203908:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc020390c:	03070163          	beq	a4,a6,ffffffffc020392e <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0203910:	fef697e3          	bne	a3,a5,ffffffffc02038fe <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203914:	ed89                	bnez	a1,ffffffffc020392e <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0203916:	451c                	lw	a5,8(a0)
ffffffffc0203918:	2785                	addiw	a5,a5,1
ffffffffc020391a:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc020391c:	00a88463          	beq	a7,a0,ffffffffc0203924 <schedule+0x60>
            proc_run(next);
ffffffffc0203920:	99dff0ef          	jal	ffffffffc02032bc <proc_run>
    if (flag) {
ffffffffc0203924:	e819                	bnez	s0,ffffffffc020393a <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0203926:	60a2                	ld	ra,8(sp)
ffffffffc0203928:	6402                	ld	s0,0(sp)
ffffffffc020392a:	0141                	addi	sp,sp,16
ffffffffc020392c:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc020392e:	4198                	lw	a4,0(a1)
ffffffffc0203930:	4789                	li	a5,2
ffffffffc0203932:	fef712e3          	bne	a4,a5,ffffffffc0203916 <schedule+0x52>
ffffffffc0203936:	852e                	mv	a0,a1
ffffffffc0203938:	bff9                	j	ffffffffc0203916 <schedule+0x52>
}
ffffffffc020393a:	6402                	ld	s0,0(sp)
ffffffffc020393c:	60a2                	ld	ra,8(sp)
ffffffffc020393e:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0203940:	fa5fc06f          	j	ffffffffc02008e4 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203944:	0000a617          	auipc	a2,0xa
ffffffffc0203948:	b1460613          	addi	a2,a2,-1260 # ffffffffc020d458 <proc_list>
ffffffffc020394c:	86b2                	mv	a3,a2
ffffffffc020394e:	b76d                	j	ffffffffc02038f8 <schedule+0x34>
        intr_disable();
ffffffffc0203950:	f9bfc0ef          	jal	ffffffffc02008ea <intr_disable>
        return 1;
ffffffffc0203954:	4405                	li	s0,1
ffffffffc0203956:	bfbd                	j	ffffffffc02038d4 <schedule+0x10>

ffffffffc0203958 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0203958:	9e3707b7          	lui	a5,0x9e370
ffffffffc020395c:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <kern_entry-0x21e8ffff>
ffffffffc020395e:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc0203962:	02000513          	li	a0,32
ffffffffc0203966:	9d0d                	subw	a0,a0,a1
}
ffffffffc0203968:	00a7d53b          	srlw	a0,a5,a0
ffffffffc020396c:	8082                	ret

ffffffffc020396e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020396e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203972:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203974:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203978:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020397a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020397e:	f022                	sd	s0,32(sp)
ffffffffc0203980:	ec26                	sd	s1,24(sp)
ffffffffc0203982:	e84a                	sd	s2,16(sp)
ffffffffc0203984:	f406                	sd	ra,40(sp)
ffffffffc0203986:	84aa                	mv	s1,a0
ffffffffc0203988:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020398a:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020398e:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0203990:	05067063          	bgeu	a2,a6,ffffffffc02039d0 <printnum+0x62>
ffffffffc0203994:	e44e                	sd	s3,8(sp)
ffffffffc0203996:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203998:	4785                	li	a5,1
ffffffffc020399a:	00e7d763          	bge	a5,a4,ffffffffc02039a8 <printnum+0x3a>
            putch(padc, putdat);
ffffffffc020399e:	85ca                	mv	a1,s2
ffffffffc02039a0:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02039a2:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02039a4:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02039a6:	fc65                	bnez	s0,ffffffffc020399e <printnum+0x30>
ffffffffc02039a8:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039aa:	1a02                	slli	s4,s4,0x20
ffffffffc02039ac:	020a5a13          	srli	s4,s4,0x20
ffffffffc02039b0:	00002797          	auipc	a5,0x2
ffffffffc02039b4:	cd878793          	addi	a5,a5,-808 # ffffffffc0205688 <etext+0x1826>
ffffffffc02039b8:	97d2                	add	a5,a5,s4
}
ffffffffc02039ba:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039bc:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02039c0:	70a2                	ld	ra,40(sp)
ffffffffc02039c2:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039c4:	85ca                	mv	a1,s2
ffffffffc02039c6:	87a6                	mv	a5,s1
}
ffffffffc02039c8:	6942                	ld	s2,16(sp)
ffffffffc02039ca:	64e2                	ld	s1,24(sp)
ffffffffc02039cc:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039ce:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02039d0:	03065633          	divu	a2,a2,a6
ffffffffc02039d4:	8722                	mv	a4,s0
ffffffffc02039d6:	f99ff0ef          	jal	ffffffffc020396e <printnum>
ffffffffc02039da:	bfc1                	j	ffffffffc02039aa <printnum+0x3c>

ffffffffc02039dc <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02039dc:	7119                	addi	sp,sp,-128
ffffffffc02039de:	f4a6                	sd	s1,104(sp)
ffffffffc02039e0:	f0ca                	sd	s2,96(sp)
ffffffffc02039e2:	ecce                	sd	s3,88(sp)
ffffffffc02039e4:	e8d2                	sd	s4,80(sp)
ffffffffc02039e6:	e4d6                	sd	s5,72(sp)
ffffffffc02039e8:	e0da                	sd	s6,64(sp)
ffffffffc02039ea:	f862                	sd	s8,48(sp)
ffffffffc02039ec:	fc86                	sd	ra,120(sp)
ffffffffc02039ee:	f8a2                	sd	s0,112(sp)
ffffffffc02039f0:	fc5e                	sd	s7,56(sp)
ffffffffc02039f2:	f466                	sd	s9,40(sp)
ffffffffc02039f4:	f06a                	sd	s10,32(sp)
ffffffffc02039f6:	ec6e                	sd	s11,24(sp)
ffffffffc02039f8:	892a                	mv	s2,a0
ffffffffc02039fa:	84ae                	mv	s1,a1
ffffffffc02039fc:	8c32                	mv	s8,a2
ffffffffc02039fe:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a00:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a04:	05500b13          	li	s6,85
ffffffffc0203a08:	00002a97          	auipc	s5,0x2
ffffffffc0203a0c:	e20a8a93          	addi	s5,s5,-480 # ffffffffc0205828 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a10:	000c4503          	lbu	a0,0(s8)
ffffffffc0203a14:	001c0413          	addi	s0,s8,1
ffffffffc0203a18:	01350a63          	beq	a0,s3,ffffffffc0203a2c <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0203a1c:	cd0d                	beqz	a0,ffffffffc0203a56 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0203a1e:	85a6                	mv	a1,s1
ffffffffc0203a20:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a22:	00044503          	lbu	a0,0(s0)
ffffffffc0203a26:	0405                	addi	s0,s0,1
ffffffffc0203a28:	ff351ae3          	bne	a0,s3,ffffffffc0203a1c <vprintfmt+0x40>
        char padc = ' ';
ffffffffc0203a2c:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0203a30:	4b81                	li	s7,0
ffffffffc0203a32:	4601                	li	a2,0
        width = precision = -1;
ffffffffc0203a34:	5d7d                	li	s10,-1
ffffffffc0203a36:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a38:	00044683          	lbu	a3,0(s0)
ffffffffc0203a3c:	00140c13          	addi	s8,s0,1
ffffffffc0203a40:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0203a44:	0ff5f593          	zext.b	a1,a1
ffffffffc0203a48:	02bb6663          	bltu	s6,a1,ffffffffc0203a74 <vprintfmt+0x98>
ffffffffc0203a4c:	058a                	slli	a1,a1,0x2
ffffffffc0203a4e:	95d6                	add	a1,a1,s5
ffffffffc0203a50:	4198                	lw	a4,0(a1)
ffffffffc0203a52:	9756                	add	a4,a4,s5
ffffffffc0203a54:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203a56:	70e6                	ld	ra,120(sp)
ffffffffc0203a58:	7446                	ld	s0,112(sp)
ffffffffc0203a5a:	74a6                	ld	s1,104(sp)
ffffffffc0203a5c:	7906                	ld	s2,96(sp)
ffffffffc0203a5e:	69e6                	ld	s3,88(sp)
ffffffffc0203a60:	6a46                	ld	s4,80(sp)
ffffffffc0203a62:	6aa6                	ld	s5,72(sp)
ffffffffc0203a64:	6b06                	ld	s6,64(sp)
ffffffffc0203a66:	7be2                	ld	s7,56(sp)
ffffffffc0203a68:	7c42                	ld	s8,48(sp)
ffffffffc0203a6a:	7ca2                	ld	s9,40(sp)
ffffffffc0203a6c:	7d02                	ld	s10,32(sp)
ffffffffc0203a6e:	6de2                	ld	s11,24(sp)
ffffffffc0203a70:	6109                	addi	sp,sp,128
ffffffffc0203a72:	8082                	ret
            putch('%', putdat);
ffffffffc0203a74:	85a6                	mv	a1,s1
ffffffffc0203a76:	02500513          	li	a0,37
ffffffffc0203a7a:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203a7c:	fff44703          	lbu	a4,-1(s0)
ffffffffc0203a80:	02500793          	li	a5,37
ffffffffc0203a84:	8c22                	mv	s8,s0
ffffffffc0203a86:	f8f705e3          	beq	a4,a5,ffffffffc0203a10 <vprintfmt+0x34>
ffffffffc0203a8a:	02500713          	li	a4,37
ffffffffc0203a8e:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0203a92:	1c7d                	addi	s8,s8,-1
ffffffffc0203a94:	fee79de3          	bne	a5,a4,ffffffffc0203a8e <vprintfmt+0xb2>
ffffffffc0203a98:	bfa5                	j	ffffffffc0203a10 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0203a9a:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0203a9e:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0203aa0:	fd068d1b          	addiw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0203aa4:	fd07859b          	addiw	a1,a5,-48
                ch = *fmt;
ffffffffc0203aa8:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203aac:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0203aae:	02b76563          	bltu	a4,a1,ffffffffc0203ad8 <vprintfmt+0xfc>
ffffffffc0203ab2:	4525                	li	a0,9
                ch = *fmt;
ffffffffc0203ab4:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203ab8:	002d171b          	slliw	a4,s10,0x2
ffffffffc0203abc:	01a7073b          	addw	a4,a4,s10
ffffffffc0203ac0:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203ac4:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc0203ac6:	fd07859b          	addiw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203aca:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203acc:	fd070d1b          	addiw	s10,a4,-48
                ch = *fmt;
ffffffffc0203ad0:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc0203ad4:	feb570e3          	bgeu	a0,a1,ffffffffc0203ab4 <vprintfmt+0xd8>
            if (width < 0)
ffffffffc0203ad8:	f60cd0e3          	bgez	s9,ffffffffc0203a38 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0203adc:	8cea                	mv	s9,s10
ffffffffc0203ade:	5d7d                	li	s10,-1
ffffffffc0203ae0:	bfa1                	j	ffffffffc0203a38 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ae2:	8db6                	mv	s11,a3
ffffffffc0203ae4:	8462                	mv	s0,s8
ffffffffc0203ae6:	bf89                	j	ffffffffc0203a38 <vprintfmt+0x5c>
ffffffffc0203ae8:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0203aea:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0203aec:	b7b1                	j	ffffffffc0203a38 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0203aee:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0203af0:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0203af4:	00c7c463          	blt	a5,a2,ffffffffc0203afc <vprintfmt+0x120>
    else if (lflag) {
ffffffffc0203af8:	1a060163          	beqz	a2,ffffffffc0203c9a <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0203afc:	000a3603          	ld	a2,0(s4)
ffffffffc0203b00:	46c1                	li	a3,16
ffffffffc0203b02:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203b04:	000d879b          	sext.w	a5,s11
ffffffffc0203b08:	8766                	mv	a4,s9
ffffffffc0203b0a:	85a6                	mv	a1,s1
ffffffffc0203b0c:	854a                	mv	a0,s2
ffffffffc0203b0e:	e61ff0ef          	jal	ffffffffc020396e <printnum>
            break;
ffffffffc0203b12:	bdfd                	j	ffffffffc0203a10 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0203b14:	000a2503          	lw	a0,0(s4)
ffffffffc0203b18:	85a6                	mv	a1,s1
ffffffffc0203b1a:	0a21                	addi	s4,s4,8
ffffffffc0203b1c:	9902                	jalr	s2
            break;
ffffffffc0203b1e:	bdcd                	j	ffffffffc0203a10 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0203b20:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0203b22:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0203b26:	00c7c463          	blt	a5,a2,ffffffffc0203b2e <vprintfmt+0x152>
    else if (lflag) {
ffffffffc0203b2a:	16060363          	beqz	a2,ffffffffc0203c90 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0203b2e:	000a3603          	ld	a2,0(s4)
ffffffffc0203b32:	46a9                	li	a3,10
ffffffffc0203b34:	8a3a                	mv	s4,a4
ffffffffc0203b36:	b7f9                	j	ffffffffc0203b04 <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc0203b38:	85a6                	mv	a1,s1
ffffffffc0203b3a:	03000513          	li	a0,48
ffffffffc0203b3e:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203b40:	85a6                	mv	a1,s1
ffffffffc0203b42:	07800513          	li	a0,120
ffffffffc0203b46:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203b48:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0203b4c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203b4e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203b50:	bf55                	j	ffffffffc0203b04 <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0203b52:	85a6                	mv	a1,s1
ffffffffc0203b54:	02500513          	li	a0,37
ffffffffc0203b58:	9902                	jalr	s2
            break;
ffffffffc0203b5a:	bd5d                	j	ffffffffc0203a10 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0203b5c:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b60:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0203b62:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0203b64:	bf95                	j	ffffffffc0203ad8 <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc0203b66:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0203b68:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0203b6c:	00c7c463          	blt	a5,a2,ffffffffc0203b74 <vprintfmt+0x198>
    else if (lflag) {
ffffffffc0203b70:	10060b63          	beqz	a2,ffffffffc0203c86 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0203b74:	000a3603          	ld	a2,0(s4)
ffffffffc0203b78:	46a1                	li	a3,8
ffffffffc0203b7a:	8a3a                	mv	s4,a4
ffffffffc0203b7c:	b761                	j	ffffffffc0203b04 <vprintfmt+0x128>
            if (width < 0)
ffffffffc0203b7e:	fffcc793          	not	a5,s9
ffffffffc0203b82:	97fd                	srai	a5,a5,0x3f
ffffffffc0203b84:	00fcf7b3          	and	a5,s9,a5
ffffffffc0203b88:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b8c:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0203b8e:	b56d                	j	ffffffffc0203a38 <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203b90:	000a3403          	ld	s0,0(s4)
ffffffffc0203b94:	008a0793          	addi	a5,s4,8
ffffffffc0203b98:	e43e                	sd	a5,8(sp)
ffffffffc0203b9a:	12040063          	beqz	s0,ffffffffc0203cba <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0203b9e:	0d905963          	blez	s9,ffffffffc0203c70 <vprintfmt+0x294>
ffffffffc0203ba2:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203ba6:	00140a13          	addi	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc0203baa:	12fd9763          	bne	s11,a5,ffffffffc0203cd8 <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203bae:	00044783          	lbu	a5,0(s0)
ffffffffc0203bb2:	0007851b          	sext.w	a0,a5
ffffffffc0203bb6:	cb9d                	beqz	a5,ffffffffc0203bec <vprintfmt+0x210>
ffffffffc0203bb8:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203bba:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203bbe:	000d4563          	bltz	s10,ffffffffc0203bc8 <vprintfmt+0x1ec>
ffffffffc0203bc2:	3d7d                	addiw	s10,s10,-1
ffffffffc0203bc4:	028d0263          	beq	s10,s0,ffffffffc0203be8 <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc0203bc8:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203bca:	0c0b8d63          	beqz	s7,ffffffffc0203ca4 <vprintfmt+0x2c8>
ffffffffc0203bce:	3781                	addiw	a5,a5,-32
ffffffffc0203bd0:	0cfdfa63          	bgeu	s11,a5,ffffffffc0203ca4 <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc0203bd4:	03f00513          	li	a0,63
ffffffffc0203bd8:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203bda:	000a4783          	lbu	a5,0(s4)
ffffffffc0203bde:	3cfd                	addiw	s9,s9,-1 # feffff <kern_entry-0xffffffffbf210001>
ffffffffc0203be0:	0a05                	addi	s4,s4,1
ffffffffc0203be2:	0007851b          	sext.w	a0,a5
ffffffffc0203be6:	ffe1                	bnez	a5,ffffffffc0203bbe <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc0203be8:	01905963          	blez	s9,ffffffffc0203bfa <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc0203bec:	85a6                	mv	a1,s1
ffffffffc0203bee:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0203bf2:	3cfd                	addiw	s9,s9,-1
                putch(' ', putdat);
ffffffffc0203bf4:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0203bf6:	fe0c9be3          	bnez	s9,ffffffffc0203bec <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203bfa:	6a22                	ld	s4,8(sp)
ffffffffc0203bfc:	bd11                	j	ffffffffc0203a10 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0203bfe:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0203c00:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0203c04:	00c7c363          	blt	a5,a2,ffffffffc0203c0a <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc0203c08:	ce25                	beqz	a2,ffffffffc0203c80 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc0203c0a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203c0e:	08044d63          	bltz	s0,ffffffffc0203ca8 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0203c12:	8622                	mv	a2,s0
ffffffffc0203c14:	8a5e                	mv	s4,s7
ffffffffc0203c16:	46a9                	li	a3,10
ffffffffc0203c18:	b5f5                	j	ffffffffc0203b04 <vprintfmt+0x128>
            if (err < 0) {
ffffffffc0203c1a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203c1e:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0203c20:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0203c24:	8fb9                	xor	a5,a5,a4
ffffffffc0203c26:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203c2a:	02d64663          	blt	a2,a3,ffffffffc0203c56 <vprintfmt+0x27a>
ffffffffc0203c2e:	00369713          	slli	a4,a3,0x3
ffffffffc0203c32:	00002797          	auipc	a5,0x2
ffffffffc0203c36:	d4e78793          	addi	a5,a5,-690 # ffffffffc0205980 <error_string>
ffffffffc0203c3a:	97ba                	add	a5,a5,a4
ffffffffc0203c3c:	639c                	ld	a5,0(a5)
ffffffffc0203c3e:	cf81                	beqz	a5,ffffffffc0203c56 <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203c40:	86be                	mv	a3,a5
ffffffffc0203c42:	00000617          	auipc	a2,0x0
ffffffffc0203c46:	24e60613          	addi	a2,a2,590 # ffffffffc0203e90 <etext+0x2e>
ffffffffc0203c4a:	85a6                	mv	a1,s1
ffffffffc0203c4c:	854a                	mv	a0,s2
ffffffffc0203c4e:	0e8000ef          	jal	ffffffffc0203d36 <printfmt>
            err = va_arg(ap, int);
ffffffffc0203c52:	0a21                	addi	s4,s4,8
ffffffffc0203c54:	bb75                	j	ffffffffc0203a10 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203c56:	00002617          	auipc	a2,0x2
ffffffffc0203c5a:	a5260613          	addi	a2,a2,-1454 # ffffffffc02056a8 <etext+0x1846>
ffffffffc0203c5e:	85a6                	mv	a1,s1
ffffffffc0203c60:	854a                	mv	a0,s2
ffffffffc0203c62:	0d4000ef          	jal	ffffffffc0203d36 <printfmt>
            err = va_arg(ap, int);
ffffffffc0203c66:	0a21                	addi	s4,s4,8
ffffffffc0203c68:	b365                	j	ffffffffc0203a10 <vprintfmt+0x34>
            lflag ++;
ffffffffc0203c6a:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c6c:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0203c6e:	b3e9                	j	ffffffffc0203a38 <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c70:	00044783          	lbu	a5,0(s0)
ffffffffc0203c74:	0007851b          	sext.w	a0,a5
ffffffffc0203c78:	d3c9                	beqz	a5,ffffffffc0203bfa <vprintfmt+0x21e>
ffffffffc0203c7a:	00140a13          	addi	s4,s0,1
ffffffffc0203c7e:	bf2d                	j	ffffffffc0203bb8 <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc0203c80:	000a2403          	lw	s0,0(s4)
ffffffffc0203c84:	b769                	j	ffffffffc0203c0e <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc0203c86:	000a6603          	lwu	a2,0(s4)
ffffffffc0203c8a:	46a1                	li	a3,8
ffffffffc0203c8c:	8a3a                	mv	s4,a4
ffffffffc0203c8e:	bd9d                	j	ffffffffc0203b04 <vprintfmt+0x128>
ffffffffc0203c90:	000a6603          	lwu	a2,0(s4)
ffffffffc0203c94:	46a9                	li	a3,10
ffffffffc0203c96:	8a3a                	mv	s4,a4
ffffffffc0203c98:	b5b5                	j	ffffffffc0203b04 <vprintfmt+0x128>
ffffffffc0203c9a:	000a6603          	lwu	a2,0(s4)
ffffffffc0203c9e:	46c1                	li	a3,16
ffffffffc0203ca0:	8a3a                	mv	s4,a4
ffffffffc0203ca2:	b58d                	j	ffffffffc0203b04 <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc0203ca4:	9902                	jalr	s2
ffffffffc0203ca6:	bf15                	j	ffffffffc0203bda <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc0203ca8:	85a6                	mv	a1,s1
ffffffffc0203caa:	02d00513          	li	a0,45
ffffffffc0203cae:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0203cb0:	40800633          	neg	a2,s0
ffffffffc0203cb4:	8a5e                	mv	s4,s7
ffffffffc0203cb6:	46a9                	li	a3,10
ffffffffc0203cb8:	b5b1                	j	ffffffffc0203b04 <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc0203cba:	01905663          	blez	s9,ffffffffc0203cc6 <vprintfmt+0x2ea>
ffffffffc0203cbe:	02d00793          	li	a5,45
ffffffffc0203cc2:	04fd9263          	bne	s11,a5,ffffffffc0203d06 <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203cc6:	02800793          	li	a5,40
ffffffffc0203cca:	00002a17          	auipc	s4,0x2
ffffffffc0203cce:	9d7a0a13          	addi	s4,s4,-1577 # ffffffffc02056a1 <etext+0x183f>
ffffffffc0203cd2:	02800513          	li	a0,40
ffffffffc0203cd6:	b5cd                	j	ffffffffc0203bb8 <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203cd8:	85ea                	mv	a1,s10
ffffffffc0203cda:	8522                	mv	a0,s0
ffffffffc0203cdc:	094000ef          	jal	ffffffffc0203d70 <strnlen>
ffffffffc0203ce0:	40ac8cbb          	subw	s9,s9,a0
ffffffffc0203ce4:	01905963          	blez	s9,ffffffffc0203cf6 <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc0203ce8:	2d81                	sext.w	s11,s11
ffffffffc0203cea:	85a6                	mv	a1,s1
ffffffffc0203cec:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203cee:	3cfd                	addiw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc0203cf0:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203cf2:	fe0c9ce3          	bnez	s9,ffffffffc0203cea <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203cf6:	00044783          	lbu	a5,0(s0)
ffffffffc0203cfa:	0007851b          	sext.w	a0,a5
ffffffffc0203cfe:	ea079de3          	bnez	a5,ffffffffc0203bb8 <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203d02:	6a22                	ld	s4,8(sp)
ffffffffc0203d04:	b331                	j	ffffffffc0203a10 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d06:	85ea                	mv	a1,s10
ffffffffc0203d08:	00002517          	auipc	a0,0x2
ffffffffc0203d0c:	99850513          	addi	a0,a0,-1640 # ffffffffc02056a0 <etext+0x183e>
ffffffffc0203d10:	060000ef          	jal	ffffffffc0203d70 <strnlen>
ffffffffc0203d14:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc0203d18:	00002417          	auipc	s0,0x2
ffffffffc0203d1c:	98840413          	addi	s0,s0,-1656 # ffffffffc02056a0 <etext+0x183e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d20:	00002a17          	auipc	s4,0x2
ffffffffc0203d24:	981a0a13          	addi	s4,s4,-1663 # ffffffffc02056a1 <etext+0x183f>
ffffffffc0203d28:	02800793          	li	a5,40
ffffffffc0203d2c:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d30:	fb904ce3          	bgtz	s9,ffffffffc0203ce8 <vprintfmt+0x30c>
ffffffffc0203d34:	b551                	j	ffffffffc0203bb8 <vprintfmt+0x1dc>

ffffffffc0203d36 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d36:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203d38:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d3c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203d3e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d40:	ec06                	sd	ra,24(sp)
ffffffffc0203d42:	f83a                	sd	a4,48(sp)
ffffffffc0203d44:	fc3e                	sd	a5,56(sp)
ffffffffc0203d46:	e0c2                	sd	a6,64(sp)
ffffffffc0203d48:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203d4a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203d4c:	c91ff0ef          	jal	ffffffffc02039dc <vprintfmt>
}
ffffffffc0203d50:	60e2                	ld	ra,24(sp)
ffffffffc0203d52:	6161                	addi	sp,sp,80
ffffffffc0203d54:	8082                	ret

ffffffffc0203d56 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203d56:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0203d5a:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0203d5c:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203d5e:	cb81                	beqz	a5,ffffffffc0203d6e <strlen+0x18>
        cnt ++;
ffffffffc0203d60:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203d62:	00a707b3          	add	a5,a4,a0
ffffffffc0203d66:	0007c783          	lbu	a5,0(a5)
ffffffffc0203d6a:	fbfd                	bnez	a5,ffffffffc0203d60 <strlen+0xa>
ffffffffc0203d6c:	8082                	ret
    }
    return cnt;
}
ffffffffc0203d6e:	8082                	ret

ffffffffc0203d70 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203d70:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203d72:	e589                	bnez	a1,ffffffffc0203d7c <strnlen+0xc>
ffffffffc0203d74:	a811                	j	ffffffffc0203d88 <strnlen+0x18>
        cnt ++;
ffffffffc0203d76:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203d78:	00f58863          	beq	a1,a5,ffffffffc0203d88 <strnlen+0x18>
ffffffffc0203d7c:	00f50733          	add	a4,a0,a5
ffffffffc0203d80:	00074703          	lbu	a4,0(a4)
ffffffffc0203d84:	fb6d                	bnez	a4,ffffffffc0203d76 <strnlen+0x6>
ffffffffc0203d86:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203d88:	852e                	mv	a0,a1
ffffffffc0203d8a:	8082                	ret

ffffffffc0203d8c <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203d8c:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203d8e:	0005c703          	lbu	a4,0(a1)
ffffffffc0203d92:	0785                	addi	a5,a5,1
ffffffffc0203d94:	0585                	addi	a1,a1,1
ffffffffc0203d96:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203d9a:	fb75                	bnez	a4,ffffffffc0203d8e <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203d9c:	8082                	ret

ffffffffc0203d9e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203d9e:	00054783          	lbu	a5,0(a0)
ffffffffc0203da2:	e791                	bnez	a5,ffffffffc0203dae <strcmp+0x10>
ffffffffc0203da4:	a02d                	j	ffffffffc0203dce <strcmp+0x30>
ffffffffc0203da6:	00054783          	lbu	a5,0(a0)
ffffffffc0203daa:	cf89                	beqz	a5,ffffffffc0203dc4 <strcmp+0x26>
ffffffffc0203dac:	85b6                	mv	a1,a3
ffffffffc0203dae:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0203db2:	0505                	addi	a0,a0,1
ffffffffc0203db4:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203db8:	fef707e3          	beq	a4,a5,ffffffffc0203da6 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203dbc:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203dc0:	9d19                	subw	a0,a0,a4
ffffffffc0203dc2:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203dc4:	0015c703          	lbu	a4,1(a1)
ffffffffc0203dc8:	4501                	li	a0,0
}
ffffffffc0203dca:	9d19                	subw	a0,a0,a4
ffffffffc0203dcc:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203dce:	0005c703          	lbu	a4,0(a1)
ffffffffc0203dd2:	4501                	li	a0,0
ffffffffc0203dd4:	b7f5                	j	ffffffffc0203dc0 <strcmp+0x22>

ffffffffc0203dd6 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203dd6:	ce01                	beqz	a2,ffffffffc0203dee <strncmp+0x18>
ffffffffc0203dd8:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203ddc:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203dde:	cb91                	beqz	a5,ffffffffc0203df2 <strncmp+0x1c>
ffffffffc0203de0:	0005c703          	lbu	a4,0(a1)
ffffffffc0203de4:	00f71763          	bne	a4,a5,ffffffffc0203df2 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0203de8:	0505                	addi	a0,a0,1
ffffffffc0203dea:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203dec:	f675                	bnez	a2,ffffffffc0203dd8 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203dee:	4501                	li	a0,0
ffffffffc0203df0:	8082                	ret
ffffffffc0203df2:	00054503          	lbu	a0,0(a0)
ffffffffc0203df6:	0005c783          	lbu	a5,0(a1)
ffffffffc0203dfa:	9d1d                	subw	a0,a0,a5
}
ffffffffc0203dfc:	8082                	ret

ffffffffc0203dfe <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203dfe:	00054783          	lbu	a5,0(a0)
ffffffffc0203e02:	c799                	beqz	a5,ffffffffc0203e10 <strchr+0x12>
        if (*s == c) {
ffffffffc0203e04:	00f58763          	beq	a1,a5,ffffffffc0203e12 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203e08:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203e0c:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203e0e:	fbfd                	bnez	a5,ffffffffc0203e04 <strchr+0x6>
    }
    return NULL;
ffffffffc0203e10:	4501                	li	a0,0
}
ffffffffc0203e12:	8082                	ret

ffffffffc0203e14 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203e14:	ca01                	beqz	a2,ffffffffc0203e24 <memset+0x10>
ffffffffc0203e16:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203e18:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203e1a:	0785                	addi	a5,a5,1
ffffffffc0203e1c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203e20:	fef61de3          	bne	a2,a5,ffffffffc0203e1a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203e24:	8082                	ret

ffffffffc0203e26 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203e26:	ca19                	beqz	a2,ffffffffc0203e3c <memcpy+0x16>
ffffffffc0203e28:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203e2a:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203e2c:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e30:	0585                	addi	a1,a1,1
ffffffffc0203e32:	0785                	addi	a5,a5,1
ffffffffc0203e34:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203e38:	feb61ae3          	bne	a2,a1,ffffffffc0203e2c <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203e3c:	8082                	ret

ffffffffc0203e3e <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203e3e:	c205                	beqz	a2,ffffffffc0203e5e <memcmp+0x20>
ffffffffc0203e40:	962a                	add	a2,a2,a0
ffffffffc0203e42:	a019                	j	ffffffffc0203e48 <memcmp+0xa>
ffffffffc0203e44:	00c50d63          	beq	a0,a2,ffffffffc0203e5e <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203e48:	00054783          	lbu	a5,0(a0)
ffffffffc0203e4c:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203e50:	0505                	addi	a0,a0,1
ffffffffc0203e52:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203e54:	fee788e3          	beq	a5,a4,ffffffffc0203e44 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e58:	40e7853b          	subw	a0,a5,a4
ffffffffc0203e5c:	8082                	ret
    }
    return 0;
ffffffffc0203e5e:	4501                	li	a0,0
}
ffffffffc0203e60:	8082                	ret
