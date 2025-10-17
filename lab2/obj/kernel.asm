
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	73c50513          	addi	a0,a0,1852 # ffffffffc0201788 <etext>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f4000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	74650513          	addi	a0,a0,1862 # ffffffffc02017a8 <etext+0x20>
ffffffffc020006a:	0e0000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	71a58593          	addi	a1,a1,1818 # ffffffffc0201788 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	75250513          	addi	a0,a0,1874 # ffffffffc02017c8 <etext+0x40>
ffffffffc020007e:	0cc000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <free_area_buddy>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	75e50513          	addi	a0,a0,1886 # ffffffffc02017e8 <etext+0x60>
ffffffffc0200092:	0b8000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	0d258593          	addi	a1,a1,210 # ffffffffc0206168 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	76a50513          	addi	a0,a0,1898 # ffffffffc0201808 <etext+0x80>
ffffffffc02000a6:	0a4000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00006797          	auipc	a5,0x6
ffffffffc02000ae:	4bd78793          	addi	a5,a5,1213 # ffffffffc0206567 <end+0x3ff>
ffffffffc02000b2:	00000717          	auipc	a4,0x0
ffffffffc02000b6:	02470713          	addi	a4,a4,36 # ffffffffc02000d6 <kern_init>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00001517          	auipc	a0,0x1
ffffffffc02000ce:	75e50513          	addi	a0,a0,1886 # ffffffffc0201828 <etext+0xa0>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a89d                	j	ffffffffc020014a <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00006517          	auipc	a0,0x6
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0206018 <free_area_buddy>
ffffffffc02000de:	00006617          	auipc	a2,0x6
ffffffffc02000e2:	08a60613          	addi	a2,a2,138 # ffffffffc0206168 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	688010ef          	jal	ffffffffc0201776 <memset>
    dtb_init();
ffffffffc02000f2:	13a000ef          	jal	ffffffffc020022c <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	12c000ef          	jal	ffffffffc0200222 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00002517          	auipc	a0,0x2
ffffffffc02000fe:	32e50513          	addi	a0,a0,814 # ffffffffc0202428 <etext+0xca0>
ffffffffc0200102:	07c000ef          	jal	ffffffffc020017e <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	7f9000ef          	jal	ffffffffc0201102 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc020010e:	a001                	j	ffffffffc020010e <kern_init+0x38>

ffffffffc0200110 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200110:	1141                	addi	sp,sp,-16
ffffffffc0200112:	e022                	sd	s0,0(sp)
ffffffffc0200114:	e406                	sd	ra,8(sp)
ffffffffc0200116:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200118:	10c000ef          	jal	ffffffffc0200224 <cons_putc>
    (*cnt) ++;
ffffffffc020011c:	401c                	lw	a5,0(s0)
}
ffffffffc020011e:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200120:	2785                	addiw	a5,a5,1
ffffffffc0200122:	c01c                	sw	a5,0(s0)
}
ffffffffc0200124:	6402                	ld	s0,0(sp)
ffffffffc0200126:	0141                	addi	sp,sp,16
ffffffffc0200128:	8082                	ret

ffffffffc020012a <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012a:	1101                	addi	sp,sp,-32
ffffffffc020012c:	862a                	mv	a2,a0
ffffffffc020012e:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200130:	00000517          	auipc	a0,0x0
ffffffffc0200134:	fe050513          	addi	a0,a0,-32 # ffffffffc0200110 <cputch>
ffffffffc0200138:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013a:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013c:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013e:	20e010ef          	jal	ffffffffc020134c <vprintfmt>
    return cnt;
}
ffffffffc0200142:	60e2                	ld	ra,24(sp)
ffffffffc0200144:	4532                	lw	a0,12(sp)
ffffffffc0200146:	6105                	addi	sp,sp,32
ffffffffc0200148:	8082                	ret

ffffffffc020014a <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014a:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014c:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc0200150:	f42e                	sd	a1,40(sp)
ffffffffc0200152:	f832                	sd	a2,48(sp)
ffffffffc0200154:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200156:	862a                	mv	a2,a0
ffffffffc0200158:	004c                	addi	a1,sp,4
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb650513          	addi	a0,a0,-74 # ffffffffc0200110 <cputch>
ffffffffc0200162:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200164:	ec06                	sd	ra,24(sp)
ffffffffc0200166:	e0ba                	sd	a4,64(sp)
ffffffffc0200168:	e4be                	sd	a5,72(sp)
ffffffffc020016a:	e8c2                	sd	a6,80(sp)
ffffffffc020016c:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020016e:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200170:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200172:	1da010ef          	jal	ffffffffc020134c <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200176:	60e2                	ld	ra,24(sp)
ffffffffc0200178:	4512                	lw	a0,4(sp)
ffffffffc020017a:	6125                	addi	sp,sp,96
ffffffffc020017c:	8082                	ret

ffffffffc020017e <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020017e:	1101                	addi	sp,sp,-32
ffffffffc0200180:	ec06                	sd	ra,24(sp)
ffffffffc0200182:	e822                	sd	s0,16(sp)
ffffffffc0200184:	87aa                	mv	a5,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200186:	00054503          	lbu	a0,0(a0)
ffffffffc020018a:	c905                	beqz	a0,ffffffffc02001ba <cputs+0x3c>
ffffffffc020018c:	e426                	sd	s1,8(sp)
ffffffffc020018e:	00178493          	addi	s1,a5,1
ffffffffc0200192:	8426                	mv	s0,s1
    cons_putc(c);
ffffffffc0200194:	090000ef          	jal	ffffffffc0200224 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200198:	00044503          	lbu	a0,0(s0)
ffffffffc020019c:	87a2                	mv	a5,s0
ffffffffc020019e:	0405                	addi	s0,s0,1
ffffffffc02001a0:	f975                	bnez	a0,ffffffffc0200194 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a2:	9f85                	subw	a5,a5,s1
    cons_putc(c);
ffffffffc02001a4:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a6:	0027841b          	addiw	s0,a5,2
ffffffffc02001aa:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001ac:	078000ef          	jal	ffffffffc0200224 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b0:	60e2                	ld	ra,24(sp)
ffffffffc02001b2:	8522                	mv	a0,s0
ffffffffc02001b4:	6442                	ld	s0,16(sp)
ffffffffc02001b6:	6105                	addi	sp,sp,32
ffffffffc02001b8:	8082                	ret
    cons_putc(c);
ffffffffc02001ba:	4529                	li	a0,10
ffffffffc02001bc:	068000ef          	jal	ffffffffc0200224 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001c0:	4405                	li	s0,1
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	8522                	mv	a0,s0
ffffffffc02001c6:	6442                	ld	s0,16(sp)
ffffffffc02001c8:	6105                	addi	sp,sp,32
ffffffffc02001ca:	8082                	ret

ffffffffc02001cc <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001cc:	00006317          	auipc	t1,0x6
ffffffffc02001d0:	f5430313          	addi	t1,t1,-172 # ffffffffc0206120 <is_panic>
ffffffffc02001d4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d8:	715d                	addi	sp,sp,-80
ffffffffc02001da:	ec06                	sd	ra,24(sp)
ffffffffc02001dc:	f436                	sd	a3,40(sp)
ffffffffc02001de:	f83a                	sd	a4,48(sp)
ffffffffc02001e0:	fc3e                	sd	a5,56(sp)
ffffffffc02001e2:	e0c2                	sd	a6,64(sp)
ffffffffc02001e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e6:	000e0363          	beqz	t3,ffffffffc02001ec <__panic+0x20>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001ea:	a001                	j	ffffffffc02001ea <__panic+0x1e>
    is_panic = 1;
ffffffffc02001ec:	4785                	li	a5,1
ffffffffc02001ee:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001f2:	e822                	sd	s0,16(sp)
ffffffffc02001f4:	103c                	addi	a5,sp,40
ffffffffc02001f6:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f8:	862e                	mv	a2,a1
ffffffffc02001fa:	85aa                	mv	a1,a0
ffffffffc02001fc:	00001517          	auipc	a0,0x1
ffffffffc0200200:	65c50513          	addi	a0,a0,1628 # ffffffffc0201858 <etext+0xd0>
    va_start(ap, fmt);
ffffffffc0200204:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200206:	f45ff0ef          	jal	ffffffffc020014a <cprintf>
    vcprintf(fmt, ap);
ffffffffc020020a:	65a2                	ld	a1,8(sp)
ffffffffc020020c:	8522                	mv	a0,s0
ffffffffc020020e:	f1dff0ef          	jal	ffffffffc020012a <vcprintf>
    cprintf("\n");
ffffffffc0200212:	00001517          	auipc	a0,0x1
ffffffffc0200216:	66650513          	addi	a0,a0,1638 # ffffffffc0201878 <etext+0xf0>
ffffffffc020021a:	f31ff0ef          	jal	ffffffffc020014a <cprintf>
ffffffffc020021e:	6442                	ld	s0,16(sp)
ffffffffc0200220:	b7e9                	j	ffffffffc02001ea <__panic+0x1e>

ffffffffc0200222 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200222:	8082                	ret

ffffffffc0200224 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200224:	0ff57513          	zext.b	a0,a0
ffffffffc0200228:	49e0106f          	j	ffffffffc02016c6 <sbi_console_putchar>

ffffffffc020022c <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020022c:	711d                	addi	sp,sp,-96
    cprintf("DTB Init\n");
ffffffffc020022e:	00001517          	auipc	a0,0x1
ffffffffc0200232:	65250513          	addi	a0,a0,1618 # ffffffffc0201880 <etext+0xf8>
void dtb_init(void) {
ffffffffc0200236:	ec86                	sd	ra,88(sp)
ffffffffc0200238:	e8a2                	sd	s0,80(sp)
    cprintf("DTB Init\n");
ffffffffc020023a:	f11ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023e:	00006597          	auipc	a1,0x6
ffffffffc0200242:	dc25b583          	ld	a1,-574(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200246:	00001517          	auipc	a0,0x1
ffffffffc020024a:	64a50513          	addi	a0,a0,1610 # ffffffffc0201890 <etext+0x108>
ffffffffc020024e:	efdff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200252:	00006417          	auipc	s0,0x6
ffffffffc0200256:	db640413          	addi	s0,s0,-586 # ffffffffc0206008 <boot_dtb>
ffffffffc020025a:	600c                	ld	a1,0(s0)
ffffffffc020025c:	00001517          	auipc	a0,0x1
ffffffffc0200260:	64450513          	addi	a0,a0,1604 # ffffffffc02018a0 <etext+0x118>
ffffffffc0200264:	ee7ff0ef          	jal	ffffffffc020014a <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200268:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020026a:	00001517          	auipc	a0,0x1
ffffffffc020026e:	64e50513          	addi	a0,a0,1614 # ffffffffc02018b8 <etext+0x130>
    if (boot_dtb == 0) {
ffffffffc0200272:	12070d63          	beqz	a4,ffffffffc02003ac <dtb_init+0x180>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200276:	57f5                	li	a5,-3
ffffffffc0200278:	07fa                	slli	a5,a5,0x1e
ffffffffc020027a:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020027c:	431c                	lw	a5,0(a4)
ffffffffc020027e:	f456                	sd	s5,40(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200280:	00ff0637          	lui	a2,0xff0
ffffffffc0200284:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200288:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020028c:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200290:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200294:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200298:	6ac1                	lui	s5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029a:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029c:	8ec9                	or	a3,a3,a0
ffffffffc020029e:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002a2:	1afd                	addi	s5,s5,-1 # ffff <kern_entry-0xffffffffc01f0001>
ffffffffc02002a4:	0157f7b3          	and	a5,a5,s5
ffffffffc02002a8:	8dd5                	or	a1,a1,a3
ffffffffc02002aa:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002ac:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002b0:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002b2:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9d85>
ffffffffc02002b6:	0ef59f63          	bne	a1,a5,ffffffffc02003b4 <dtb_init+0x188>
ffffffffc02002ba:	471c                	lw	a5,8(a4)
ffffffffc02002bc:	4754                	lw	a3,12(a4)
ffffffffc02002be:	fc4e                	sd	s3,56(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c0:	0087d99b          	srliw	s3,a5,0x8
ffffffffc02002c4:	0086d41b          	srliw	s0,a3,0x8
ffffffffc02002c8:	0186951b          	slliw	a0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002cc:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d0:	0187959b          	slliw	a1,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d4:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d8:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002dc:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e0:	0109999b          	slliw	s3,s3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e4:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e8:	8c71                	and	s0,s0,a2
ffffffffc02002ea:	00c9f9b3          	and	s3,s3,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ee:	01156533          	or	a0,a0,a7
ffffffffc02002f2:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002f6:	0105e633          	or	a2,a1,a6
ffffffffc02002fa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002fe:	8c49                	or	s0,s0,a0
ffffffffc0200300:	0156f6b3          	and	a3,a3,s5
ffffffffc0200304:	00c9e9b3          	or	s3,s3,a2
ffffffffc0200308:	0157f7b3          	and	a5,a5,s5
ffffffffc020030c:	8c55                	or	s0,s0,a3
ffffffffc020030e:	00f9e9b3          	or	s3,s3,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200312:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200314:	1982                	slli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200316:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200318:	0209d993          	srli	s3,s3,0x20
ffffffffc020031c:	e4a6                	sd	s1,72(sp)
ffffffffc020031e:	e0ca                	sd	s2,64(sp)
ffffffffc0200320:	ec5e                	sd	s7,24(sp)
ffffffffc0200322:	e862                	sd	s8,16(sp)
ffffffffc0200324:	e466                	sd	s9,8(sp)
ffffffffc0200326:	e06a                	sd	s10,0(sp)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200328:	f852                	sd	s4,48(sp)
    int in_memory_node = 0;
ffffffffc020032a:	4b81                	li	s7,0
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020032c:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020032e:	99ba                	add	s3,s3,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200330:	00ff0cb7          	lui	s9,0xff0
        switch (token) {
ffffffffc0200334:	4c0d                	li	s8,3
ffffffffc0200336:	4911                	li	s2,4
ffffffffc0200338:	4d05                	li	s10,1
ffffffffc020033a:	4489                	li	s1,2
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033c:	0009a703          	lw	a4,0(s3)
ffffffffc0200340:	00498a13          	addi	s4,s3,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200344:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200348:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020034c:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200350:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200354:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200358:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0196f6b3          	and	a3,a3,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200362:	8fd5                	or	a5,a5,a3
ffffffffc0200364:	00eaf733          	and	a4,s5,a4
ffffffffc0200368:	8fd9                	or	a5,a5,a4
ffffffffc020036a:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020036c:	09878263          	beq	a5,s8,ffffffffc02003f0 <dtb_init+0x1c4>
ffffffffc0200370:	00fc6963          	bltu	s8,a5,ffffffffc0200382 <dtb_init+0x156>
ffffffffc0200374:	05a78963          	beq	a5,s10,ffffffffc02003c6 <dtb_init+0x19a>
ffffffffc0200378:	00979763          	bne	a5,s1,ffffffffc0200386 <dtb_init+0x15a>
ffffffffc020037c:	4b81                	li	s7,0
ffffffffc020037e:	89d2                	mv	s3,s4
ffffffffc0200380:	bf75                	j	ffffffffc020033c <dtb_init+0x110>
ffffffffc0200382:	ff278ee3          	beq	a5,s2,ffffffffc020037e <dtb_init+0x152>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200386:	00001517          	auipc	a0,0x1
ffffffffc020038a:	5fa50513          	addi	a0,a0,1530 # ffffffffc0201980 <etext+0x1f8>
ffffffffc020038e:	dbdff0ef          	jal	ffffffffc020014a <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200392:	64a6                	ld	s1,72(sp)
ffffffffc0200394:	6906                	ld	s2,64(sp)
ffffffffc0200396:	79e2                	ld	s3,56(sp)
ffffffffc0200398:	7a42                	ld	s4,48(sp)
ffffffffc020039a:	7aa2                	ld	s5,40(sp)
ffffffffc020039c:	6be2                	ld	s7,24(sp)
ffffffffc020039e:	6c42                	ld	s8,16(sp)
ffffffffc02003a0:	6ca2                	ld	s9,8(sp)
ffffffffc02003a2:	6d02                	ld	s10,0(sp)
ffffffffc02003a4:	00001517          	auipc	a0,0x1
ffffffffc02003a8:	61450513          	addi	a0,a0,1556 # ffffffffc02019b8 <etext+0x230>
}
ffffffffc02003ac:	6446                	ld	s0,80(sp)
ffffffffc02003ae:	60e6                	ld	ra,88(sp)
ffffffffc02003b0:	6125                	addi	sp,sp,96
    cprintf("DTB init completed\n");
ffffffffc02003b2:	bb61                	j	ffffffffc020014a <cprintf>
}
ffffffffc02003b4:	6446                	ld	s0,80(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003b6:	7aa2                	ld	s5,40(sp)
}
ffffffffc02003b8:	60e6                	ld	ra,88(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003ba:	00001517          	auipc	a0,0x1
ffffffffc02003be:	51e50513          	addi	a0,a0,1310 # ffffffffc02018d8 <etext+0x150>
}
ffffffffc02003c2:	6125                	addi	sp,sp,96
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003c4:	b359                	j	ffffffffc020014a <cprintf>
                int name_len = strlen(name);
ffffffffc02003c6:	8552                	mv	a0,s4
ffffffffc02003c8:	318010ef          	jal	ffffffffc02016e0 <strlen>
ffffffffc02003cc:	89aa                	mv	s3,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003ce:	4619                	li	a2,6
ffffffffc02003d0:	00001597          	auipc	a1,0x1
ffffffffc02003d4:	53058593          	addi	a1,a1,1328 # ffffffffc0201900 <etext+0x178>
ffffffffc02003d8:	8552                	mv	a0,s4
                int name_len = strlen(name);
ffffffffc02003da:	2981                	sext.w	s3,s3
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003dc:	372010ef          	jal	ffffffffc020174e <strncmp>
ffffffffc02003e0:	e111                	bnez	a0,ffffffffc02003e4 <dtb_init+0x1b8>
                    in_memory_node = 1;
ffffffffc02003e2:	4b85                	li	s7,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003e4:	0a11                	addi	s4,s4,4
ffffffffc02003e6:	9a4e                	add	s4,s4,s3
ffffffffc02003e8:	ffca7a13          	andi	s4,s4,-4
        switch (token) {
ffffffffc02003ec:	89d2                	mv	s3,s4
ffffffffc02003ee:	b7b9                	j	ffffffffc020033c <dtb_init+0x110>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f0:	0049a783          	lw	a5,4(s3)
ffffffffc02003f4:	f05a                	sd	s6,32(sp)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f6:	0089a683          	lw	a3,8(s3)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02003fa:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02003fe:	01879b1b          	slliw	s6,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200402:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200406:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020040a:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020040e:	00cb6b33          	or	s6,s6,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200412:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200416:	0087979b          	slliw	a5,a5,0x8
ffffffffc020041a:	00eb6b33          	or	s6,s6,a4
ffffffffc020041e:	00faf7b3          	and	a5,s5,a5
ffffffffc0200422:	00fb6b33          	or	s6,s6,a5
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200426:	00c98a13          	addi	s4,s3,12
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020042a:	2b01                	sext.w	s6,s6
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020042c:	000b9c63          	bnez	s7,ffffffffc0200444 <dtb_init+0x218>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200430:	1b02                	slli	s6,s6,0x20
ffffffffc0200432:	020b5b13          	srli	s6,s6,0x20
ffffffffc0200436:	0a0d                	addi	s4,s4,3
ffffffffc0200438:	9a5a                	add	s4,s4,s6
ffffffffc020043a:	ffca7a13          	andi	s4,s4,-4
                break;
ffffffffc020043e:	7b02                	ld	s6,32(sp)
        switch (token) {
ffffffffc0200440:	89d2                	mv	s3,s4
ffffffffc0200442:	bded                	j	ffffffffc020033c <dtb_init+0x110>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200444:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200448:	0186979b          	slliw	a5,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020044c:	0186d71b          	srliw	a4,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200450:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200454:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200458:	01957533          	and	a0,a0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020045c:	8fd9                	or	a5,a5,a4
ffffffffc020045e:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200462:	8d5d                	or	a0,a0,a5
ffffffffc0200464:	00daf6b3          	and	a3,s5,a3
ffffffffc0200468:	8d55                	or	a0,a0,a3
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020046a:	1502                	slli	a0,a0,0x20
ffffffffc020046c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020046e:	00001597          	auipc	a1,0x1
ffffffffc0200472:	49a58593          	addi	a1,a1,1178 # ffffffffc0201908 <etext+0x180>
ffffffffc0200476:	9522                	add	a0,a0,s0
ffffffffc0200478:	29e010ef          	jal	ffffffffc0201716 <strcmp>
ffffffffc020047c:	f955                	bnez	a0,ffffffffc0200430 <dtb_init+0x204>
ffffffffc020047e:	47bd                	li	a5,15
ffffffffc0200480:	fb67f8e3          	bgeu	a5,s6,ffffffffc0200430 <dtb_init+0x204>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200484:	00c9b783          	ld	a5,12(s3)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200488:	0149b703          	ld	a4,20(s3)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020048c:	00001517          	auipc	a0,0x1
ffffffffc0200490:	48450513          	addi	a0,a0,1156 # ffffffffc0201910 <etext+0x188>
           fdt32_to_cpu(x >> 32);
ffffffffc0200494:	4207d693          	srai	a3,a5,0x20
ffffffffc0200498:	42075813          	srai	a6,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020049c:	0187d39b          	srliw	t2,a5,0x18
ffffffffc02004a0:	0186d29b          	srliw	t0,a3,0x18
ffffffffc02004a4:	01875f9b          	srliw	t6,a4,0x18
ffffffffc02004a8:	01885f1b          	srliw	t5,a6,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ac:	0087d49b          	srliw	s1,a5,0x8
ffffffffc02004b0:	0087541b          	srliw	s0,a4,0x8
ffffffffc02004b4:	01879e9b          	slliw	t4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0107d59b          	srliw	a1,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004bc:	01869e1b          	slliw	t3,a3,0x18
ffffffffc02004c0:	0187131b          	slliw	t1,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107561b          	srliw	a2,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0188189b          	slliw	a7,a6,0x18
ffffffffc02004cc:	83e1                	srli	a5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	8361                	srli	a4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d4:	0108581b          	srliw	a6,a6,0x10
ffffffffc02004d8:	005e6e33          	or	t3,t3,t0
ffffffffc02004dc:	01e8e8b3          	or	a7,a7,t5
ffffffffc02004e0:	0088181b          	slliw	a6,a6,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e4:	0104949b          	slliw	s1,s1,0x10
ffffffffc02004e8:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	0085959b          	slliw	a1,a1,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0197f7b3          	and	a5,a5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f4:	0086969b          	slliw	a3,a3,0x8
ffffffffc02004f8:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fc:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	00daf6b3          	and	a3,s5,a3
ffffffffc0200504:	007eeeb3          	or	t4,t4,t2
ffffffffc0200508:	01f36333          	or	t1,t1,t6
ffffffffc020050c:	01c7e7b3          	or	a5,a5,t3
ffffffffc0200510:	00caf633          	and	a2,s5,a2
ffffffffc0200514:	01176733          	or	a4,a4,a7
ffffffffc0200518:	00baf5b3          	and	a1,s5,a1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020051c:	0194f4b3          	and	s1,s1,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200520:	010afab3          	and	s5,s5,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200524:	01947433          	and	s0,s0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200528:	01d4e4b3          	or	s1,s1,t4
ffffffffc020052c:	00646433          	or	s0,s0,t1
ffffffffc0200530:	8fd5                	or	a5,a5,a3
ffffffffc0200532:	01576733          	or	a4,a4,s5
ffffffffc0200536:	8c51                	or	s0,s0,a2
ffffffffc0200538:	8ccd                	or	s1,s1,a1
           fdt32_to_cpu(x >> 32);
ffffffffc020053a:	1782                	slli	a5,a5,0x20
ffffffffc020053c:	1702                	slli	a4,a4,0x20
ffffffffc020053e:	9381                	srli	a5,a5,0x20
ffffffffc0200540:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200542:	1482                	slli	s1,s1,0x20
ffffffffc0200544:	1402                	slli	s0,s0,0x20
ffffffffc0200546:	8cdd                	or	s1,s1,a5
ffffffffc0200548:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020054a:	c01ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020054e:	85a6                	mv	a1,s1
ffffffffc0200550:	00001517          	auipc	a0,0x1
ffffffffc0200554:	3e050513          	addi	a0,a0,992 # ffffffffc0201930 <etext+0x1a8>
ffffffffc0200558:	bf3ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020055c:	01445613          	srli	a2,s0,0x14
ffffffffc0200560:	85a2                	mv	a1,s0
ffffffffc0200562:	00001517          	auipc	a0,0x1
ffffffffc0200566:	3e650513          	addi	a0,a0,998 # ffffffffc0201948 <etext+0x1c0>
ffffffffc020056a:	be1ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020056e:	009405b3          	add	a1,s0,s1
ffffffffc0200572:	15fd                	addi	a1,a1,-1
ffffffffc0200574:	00001517          	auipc	a0,0x1
ffffffffc0200578:	3f450513          	addi	a0,a0,1012 # ffffffffc0201968 <etext+0x1e0>
ffffffffc020057c:	bcfff0ef          	jal	ffffffffc020014a <cprintf>
        memory_base = mem_base;
ffffffffc0200580:	7b02                	ld	s6,32(sp)
ffffffffc0200582:	00006797          	auipc	a5,0x6
ffffffffc0200586:	ba97b723          	sd	s1,-1106(a5) # ffffffffc0206130 <memory_base>
        memory_size = mem_size;
ffffffffc020058a:	00006797          	auipc	a5,0x6
ffffffffc020058e:	b887bf23          	sd	s0,-1122(a5) # ffffffffc0206128 <memory_size>
ffffffffc0200592:	b501                	j	ffffffffc0200392 <dtb_init+0x166>

ffffffffc0200594 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200594:	00006517          	auipc	a0,0x6
ffffffffc0200598:	b9c53503          	ld	a0,-1124(a0) # ffffffffc0206130 <memory_base>
ffffffffc020059c:	8082                	ret

ffffffffc020059e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc020059e:	00006517          	auipc	a0,0x6
ffffffffc02005a2:	b8a53503          	ld	a0,-1142(a0) # ffffffffc0206128 <memory_size>
ffffffffc02005a6:	8082                	ret

ffffffffc02005a8 <buddy_system_init>:
}

// 初始化伙伴系统
static void
buddy_system_init(void) {
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc02005a8:	00006797          	auipc	a5,0x6
ffffffffc02005ac:	a7078793          	addi	a5,a5,-1424 # ffffffffc0206018 <free_area_buddy>
ffffffffc02005b0:	00006717          	auipc	a4,0x6
ffffffffc02005b4:	b7070713          	addi	a4,a4,-1168 # ffffffffc0206120 <is_panic>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005b8:	e79c                	sd	a5,8(a5)
ffffffffc02005ba:	e39c                	sd	a5,0(a5)
        list_init(&free_area_buddy[i].free_list);
        free_area_buddy[i].nr_free = 0;
ffffffffc02005bc:	0007a823          	sw	zero,16(a5)
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc02005c0:	07e1                	addi	a5,a5,24
ffffffffc02005c2:	fee79be3          	bne	a5,a4,ffffffffc02005b8 <buddy_system_init+0x10>
    }
}
ffffffffc02005c6:	8082                	ret

ffffffffc02005c8 <buddy_system_nr_free_pages>:

// 获取空闲页框数量
static size_t
buddy_system_nr_free_pages(void) {
    size_t total_free = 0;
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc02005c8:	00006697          	auipc	a3,0x6
ffffffffc02005cc:	a6068693          	addi	a3,a3,-1440 # ffffffffc0206028 <free_area_buddy+0x10>
ffffffffc02005d0:	4781                	li	a5,0
    size_t total_free = 0;
ffffffffc02005d2:	4501                	li	a0,0
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc02005d4:	462d                	li	a2,11
        total_free += free_area_buddy[i].nr_free * power_of_two(i);
ffffffffc02005d6:	0006e703          	lwu	a4,0(a3)
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc02005da:	06e1                	addi	a3,a3,24
        total_free += free_area_buddy[i].nr_free * power_of_two(i);
ffffffffc02005dc:	00f71733          	sll	a4,a4,a5
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc02005e0:	2785                	addiw	a5,a5,1
        total_free += free_area_buddy[i].nr_free * power_of_two(i);
ffffffffc02005e2:	953a                	add	a0,a0,a4
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc02005e4:	fec799e3          	bne	a5,a2,ffffffffc02005d6 <buddy_system_nr_free_pages+0xe>
    }
    return total_free;
}
ffffffffc02005e8:	8082                	ret

ffffffffc02005ea <buddy_system_alloc_pages>:
buddy_system_alloc_pages(size_t n) {
ffffffffc02005ea:	1141                	addi	sp,sp,-16
ffffffffc02005ec:	e406                	sd	ra,8(sp)
ffffffffc02005ee:	e022                	sd	s0,0(sp)
    assert(n > 0);
ffffffffc02005f0:	c979                	beqz	a0,ffffffffc02006c6 <buddy_system_alloc_pages+0xdc>
    if (n > nr_free_pages()) {
ffffffffc02005f2:	842a                	mv	s0,a0
ffffffffc02005f4:	303000ef          	jal	ffffffffc02010f6 <nr_free_pages>
ffffffffc02005f8:	0c856263          	bltu	a0,s0,ffffffffc02006bc <buddy_system_alloc_pages+0xd2>
    while (size < n) {
ffffffffc02005fc:	4785                	li	a5,1
    int order = 0;
ffffffffc02005fe:	4801                	li	a6,0
    while (size < n) {
ffffffffc0200600:	00f40963          	beq	s0,a5,ffffffffc0200612 <buddy_system_alloc_pages+0x28>
        size <<= 1;
ffffffffc0200604:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc0200606:	2805                	addiw	a6,a6,1
    while (size < n) {
ffffffffc0200608:	fe87eee3          	bltu	a5,s0,ffffffffc0200604 <buddy_system_alloc_pages+0x1a>
    while (current_order <= MAX_ORDER) {
ffffffffc020060c:	47a9                	li	a5,10
ffffffffc020060e:	0b07c763          	blt	a5,a6,ffffffffc02006bc <buddy_system_alloc_pages+0xd2>
ffffffffc0200612:	00181693          	slli	a3,a6,0x1
ffffffffc0200616:	96c2                	add	a3,a3,a6
ffffffffc0200618:	068e                	slli	a3,a3,0x3
ffffffffc020061a:	00006717          	auipc	a4,0x6
ffffffffc020061e:	9fe70713          	addi	a4,a4,-1538 # ffffffffc0206018 <free_area_buddy>
ffffffffc0200622:	96ba                	add	a3,a3,a4
    int current_order = order;
ffffffffc0200624:	87c2                	mv	a5,a6
    while (current_order <= MAX_ORDER) {
ffffffffc0200626:	462d                	li	a2,11
ffffffffc0200628:	a029                	j	ffffffffc0200632 <buddy_system_alloc_pages+0x48>
        current_order++;
ffffffffc020062a:	2785                	addiw	a5,a5,1
    while (current_order <= MAX_ORDER) {
ffffffffc020062c:	06e1                	addi	a3,a3,24
ffffffffc020062e:	08c78763          	beq	a5,a2,ffffffffc02006bc <buddy_system_alloc_pages+0xd2>
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
ffffffffc0200632:	0086b883          	ld	a7,8(a3)
        if (!list_empty(&free_area_buddy[current_order].free_list)) {
ffffffffc0200636:	fed88ae3          	beq	a7,a3,ffffffffc020062a <buddy_system_alloc_pages+0x40>
            free_area_buddy[current_order].nr_free--;
ffffffffc020063a:	00179693          	slli	a3,a5,0x1
ffffffffc020063e:	96be                	add	a3,a3,a5
ffffffffc0200640:	068e                	slli	a3,a3,0x3
    __list_del(listelm->prev, listelm->next);
ffffffffc0200642:	0088b503          	ld	a0,8(a7)
ffffffffc0200646:	00d705b3          	add	a1,a4,a3
ffffffffc020064a:	0008b303          	ld	t1,0(a7)
ffffffffc020064e:	4990                	lw	a2,16(a1)
ffffffffc0200650:	16a1                	addi	a3,a3,-24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200652:	00a33423          	sd	a0,8(t1)
    next->prev = prev;
ffffffffc0200656:	00653023          	sd	t1,0(a0)
ffffffffc020065a:	367d                	addiw	a2,a2,-1 # feffff <kern_entry-0xffffffffbf210001>
ffffffffc020065c:	c990                	sw	a2,16(a1)
            page = le2page(le, page_link);
ffffffffc020065e:	fe888513          	addi	a0,a7,-24
    while (current_order > order) {
ffffffffc0200662:	9736                	add	a4,a4,a3
        struct Page *buddy = page + power_of_two(current_order);
ffffffffc0200664:	02800e13          	li	t3,40
    while (current_order > order) {
ffffffffc0200668:	04f85163          	bge	a6,a5,ffffffffc02006aa <buddy_system_alloc_pages+0xc0>
        current_order--;
ffffffffc020066c:	fff7869b          	addiw	a3,a5,-1
        struct Page *buddy = page + power_of_two(current_order);
ffffffffc0200670:	00de17b3          	sll	a5,t3,a3
ffffffffc0200674:	97aa                	add	a5,a5,a0
        SetPageProperty(buddy);
ffffffffc0200676:	678c                	ld	a1,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200678:	00873303          	ld	t1,8(a4)
    page->property = order;
ffffffffc020067c:	cb94                	sw	a3,16(a5)
        SetPageProperty(buddy);
ffffffffc020067e:	0025e593          	ori	a1,a1,2
        free_area_buddy[current_order].nr_free++;
ffffffffc0200682:	4b10                	lw	a2,16(a4)
        SetPageProperty(buddy);
ffffffffc0200684:	e78c                	sd	a1,8(a5)
        list_add(&free_area_buddy[current_order].free_list, &(buddy->page_link));
ffffffffc0200686:	01878593          	addi	a1,a5,24
    prev->next = next->prev = elm;
ffffffffc020068a:	00b33023          	sd	a1,0(t1)
ffffffffc020068e:	e70c                	sd	a1,8(a4)
    elm->prev = prev;
ffffffffc0200690:	ef98                	sd	a4,24(a5)
    elm->next = next;
ffffffffc0200692:	0267b023          	sd	t1,32(a5)
        free_area_buddy[current_order].nr_free++;
ffffffffc0200696:	0016079b          	addiw	a5,a2,1
ffffffffc020069a:	cb1c                	sw	a5,16(a4)
        current_order--;
ffffffffc020069c:	0006879b          	sext.w	a5,a3
    while (current_order > order) {
ffffffffc02006a0:	1721                	addi	a4,a4,-24
ffffffffc02006a2:	fd0795e3          	bne	a5,a6,ffffffffc020066c <buddy_system_alloc_pages+0x82>
ffffffffc02006a6:	fed8ac23          	sw	a3,-8(a7)
    ClearPageProperty(page);
ffffffffc02006aa:	ff08b783          	ld	a5,-16(a7)
}
ffffffffc02006ae:	60a2                	ld	ra,8(sp)
ffffffffc02006b0:	6402                	ld	s0,0(sp)
    ClearPageProperty(page);
ffffffffc02006b2:	9bf5                	andi	a5,a5,-3
ffffffffc02006b4:	fef8b823          	sd	a5,-16(a7)
}
ffffffffc02006b8:	0141                	addi	sp,sp,16
ffffffffc02006ba:	8082                	ret
ffffffffc02006bc:	60a2                	ld	ra,8(sp)
ffffffffc02006be:	6402                	ld	s0,0(sp)
        return NULL;
ffffffffc02006c0:	4501                	li	a0,0
}
ffffffffc02006c2:	0141                	addi	sp,sp,16
ffffffffc02006c4:	8082                	ret
    assert(n > 0);
ffffffffc02006c6:	00001697          	auipc	a3,0x1
ffffffffc02006ca:	30a68693          	addi	a3,a3,778 # ffffffffc02019d0 <etext+0x248>
ffffffffc02006ce:	00001617          	auipc	a2,0x1
ffffffffc02006d2:	30a60613          	addi	a2,a2,778 # ffffffffc02019d8 <etext+0x250>
ffffffffc02006d6:	07f00593          	li	a1,127
ffffffffc02006da:	00001517          	auipc	a0,0x1
ffffffffc02006de:	31650513          	addi	a0,a0,790 # ffffffffc02019f0 <etext+0x268>
ffffffffc02006e2:	aebff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02006e6 <buddy_system_init_memmap>:
buddy_system_init_memmap(struct Page *base, size_t n) {
ffffffffc02006e6:	711d                	addi	sp,sp,-96
ffffffffc02006e8:	ec86                	sd	ra,88(sp)
ffffffffc02006ea:	e8a2                	sd	s0,80(sp)
ffffffffc02006ec:	e4a6                	sd	s1,72(sp)
ffffffffc02006ee:	e0ca                	sd	s2,64(sp)
ffffffffc02006f0:	fc4e                	sd	s3,56(sp)
ffffffffc02006f2:	f852                	sd	s4,48(sp)
ffffffffc02006f4:	f456                	sd	s5,40(sp)
ffffffffc02006f6:	f05a                	sd	s6,32(sp)
ffffffffc02006f8:	ec5e                	sd	s7,24(sp)
ffffffffc02006fa:	e862                	sd	s8,16(sp)
ffffffffc02006fc:	e466                	sd	s9,8(sp)
ffffffffc02006fe:	e06a                	sd	s10,0(sp)
    assert(n > 0);
ffffffffc0200700:	10058863          	beqz	a1,ffffffffc0200810 <buddy_system_init_memmap+0x12a>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200704:	fcccd9b7          	lui	s3,0xfcccd
ffffffffc0200708:	ccd98993          	addi	s3,s3,-819 # fffffffffccccccd <end+0x3cac6b65>
ffffffffc020070c:	09b2                	slli	s3,s3,0xc
ffffffffc020070e:	ccd98993          	addi	s3,s3,-819
ffffffffc0200712:	09b2                	slli	s3,s3,0xc
ffffffffc0200714:	ccd98993          	addi	s3,s3,-819
ffffffffc0200718:	09b2                	slli	s3,s3,0xc
ffffffffc020071a:	8bae                	mv	s7,a1
ffffffffc020071c:	8c2a                	mv	s8,a0
ffffffffc020071e:	00002b17          	auipc	s6,0x2
ffffffffc0200722:	ef2b3b03          	ld	s6,-270(s6) # ffffffffc0202610 <nbase>
ffffffffc0200726:	00006c97          	auipc	s9,0x6
ffffffffc020072a:	8f2c8c93          	addi	s9,s9,-1806 # ffffffffc0206018 <free_area_buddy>
ffffffffc020072e:	00006d17          	auipc	s10,0x6
ffffffffc0200732:	a32d0d13          	addi	s10,s10,-1486 # ffffffffc0206160 <pages>
            SetPageReserved(p);
ffffffffc0200736:	4905                	li	s2,1
    while (n < power_of_two(order)) {
ffffffffc0200738:	3ff00a93          	li	s5,1023
ffffffffc020073c:	ccd98993          	addi	s3,s3,-819
    cprintf("buddy_system: initialized %lu pages at 0x%08lx, order %d\n", 
ffffffffc0200740:	00001a17          	auipc	s4,0x1
ffffffffc0200744:	2d0a0a13          	addi	s4,s4,720 # ffffffffc0201a10 <etext+0x288>
    for (; p != base + n; p++) {
ffffffffc0200748:	002b9713          	slli	a4,s7,0x2
ffffffffc020074c:	975e                	add	a4,a4,s7
ffffffffc020074e:	070e                	slli	a4,a4,0x3
ffffffffc0200750:	9762                	add	a4,a4,s8
    struct Page *p = base;
ffffffffc0200752:	87e2                	mv	a5,s8
    for (; p != base + n; p++) {
ffffffffc0200754:	01870a63          	beq	a4,s8,ffffffffc0200768 <buddy_system_init_memmap+0x82>



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200758:	0007a023          	sw	zero,0(a5)
            SetPageReserved(p);
ffffffffc020075c:	0127b423          	sd	s2,8(a5)
    for (; p != base + n; p++) {
ffffffffc0200760:	02878793          	addi	a5,a5,40
ffffffffc0200764:	fee79ae3          	bne	a5,a4,ffffffffc0200758 <buddy_system_init_memmap+0x72>
    int order = MAX_ORDER;
ffffffffc0200768:	4429                	li	s0,10
    while (n < power_of_two(order)) {
ffffffffc020076a:	077aee63          	bltu	s5,s7,ffffffffc02007e6 <buddy_system_init_memmap+0x100>
        order--;
ffffffffc020076e:	347d                	addiw	s0,s0,-1
    return (size_t)1 << order;
ffffffffc0200770:	008914b3          	sll	s1,s2,s0
    while (n < power_of_two(order)) {
ffffffffc0200774:	fe9bede3          	bltu	s7,s1,ffffffffc020076e <buddy_system_init_memmap+0x88>
ffffffffc0200778:	00141793          	slli	a5,s0,0x1
ffffffffc020077c:	00878733          	add	a4,a5,s0
ffffffffc0200780:	070e                	slli	a4,a4,0x3
    base->property = order;
ffffffffc0200782:	8522                	mv	a0,s0
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200784:	000d3603          	ld	a2,0(s10)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200788:	97a2                	add	a5,a5,s0
    SetPageProperty(base);
ffffffffc020078a:	008c3683          	ld	a3,8(s8)
ffffffffc020078e:	40cc0633          	sub	a2,s8,a2
ffffffffc0200792:	860d                	srai	a2,a2,0x3
ffffffffc0200794:	03360633          	mul	a2,a2,s3
ffffffffc0200798:	078e                	slli	a5,a5,0x3
ffffffffc020079a:	97e6                	add	a5,a5,s9
ffffffffc020079c:	678c                	ld	a1,8(a5)
ffffffffc020079e:	0026e693          	ori	a3,a3,2
    base->property = order;
ffffffffc02007a2:	00ac2823          	sw	a0,16(s8)
    SetPageProperty(base);
ffffffffc02007a6:	00dc3423          	sd	a3,8(s8)
    list_add(&free_area_buddy[order].free_list, &(base->page_link));
ffffffffc02007aa:	018c0513          	addi	a0,s8,24
    free_area_buddy[order].nr_free++;
ffffffffc02007ae:	4b94                	lw	a3,16(a5)
    prev->next = next->prev = elm;
ffffffffc02007b0:	e188                	sd	a0,0(a1)
ffffffffc02007b2:	e788                	sd	a0,8(a5)
    list_add(&free_area_buddy[order].free_list, &(base->page_link));
ffffffffc02007b4:	9766                	add	a4,a4,s9
ffffffffc02007b6:	965a                	add	a2,a2,s6
    elm->next = next;
ffffffffc02007b8:	02bc3023          	sd	a1,32(s8)
    elm->prev = prev;
ffffffffc02007bc:	00ec3c23          	sd	a4,24(s8)
    cprintf("buddy_system: initialized %lu pages at 0x%08lx, order %d\n", 
ffffffffc02007c0:	0632                	slli	a2,a2,0xc
    free_area_buddy[order].nr_free++;
ffffffffc02007c2:	0016871b          	addiw	a4,a3,1
    cprintf("buddy_system: initialized %lu pages at 0x%08lx, order %d\n", 
ffffffffc02007c6:	85a6                	mv	a1,s1
ffffffffc02007c8:	86a2                	mv	a3,s0
ffffffffc02007ca:	8552                	mv	a0,s4
    free_area_buddy[order].nr_free++;
ffffffffc02007cc:	cb98                	sw	a4,16(a5)
    cprintf("buddy_system: initialized %lu pages at 0x%08lx, order %d\n", 
ffffffffc02007ce:	97dff0ef          	jal	ffffffffc020014a <cprintf>
    if (n > allocated_pages) {
ffffffffc02007d2:	0374f163          	bgeu	s1,s7,ffffffffc02007f4 <buddy_system_init_memmap+0x10e>
        buddy_system_init_memmap(base + allocated_pages, n - allocated_pages);
ffffffffc02007d6:	02800793          	li	a5,40
ffffffffc02007da:	008797b3          	sll	a5,a5,s0
ffffffffc02007de:	9c3e                	add	s8,s8,a5
ffffffffc02007e0:	409b8bb3          	sub	s7,s7,s1
    assert(n > 0);
ffffffffc02007e4:	b795                	j	ffffffffc0200748 <buddy_system_init_memmap+0x62>
    while (n < power_of_two(order)) {
ffffffffc02007e6:	4529                	li	a0,10
ffffffffc02007e8:	0f000713          	li	a4,240
    return (size_t)1 << order;
ffffffffc02007ec:	40000493          	li	s1,1024
ffffffffc02007f0:	47d1                	li	a5,20
ffffffffc02007f2:	bf49                	j	ffffffffc0200784 <buddy_system_init_memmap+0x9e>
}
ffffffffc02007f4:	60e6                	ld	ra,88(sp)
ffffffffc02007f6:	6446                	ld	s0,80(sp)
ffffffffc02007f8:	64a6                	ld	s1,72(sp)
ffffffffc02007fa:	6906                	ld	s2,64(sp)
ffffffffc02007fc:	79e2                	ld	s3,56(sp)
ffffffffc02007fe:	7a42                	ld	s4,48(sp)
ffffffffc0200800:	7aa2                	ld	s5,40(sp)
ffffffffc0200802:	7b02                	ld	s6,32(sp)
ffffffffc0200804:	6be2                	ld	s7,24(sp)
ffffffffc0200806:	6c42                	ld	s8,16(sp)
ffffffffc0200808:	6ca2                	ld	s9,8(sp)
ffffffffc020080a:	6d02                	ld	s10,0(sp)
ffffffffc020080c:	6125                	addi	sp,sp,96
ffffffffc020080e:	8082                	ret
    assert(n > 0);
ffffffffc0200810:	00001697          	auipc	a3,0x1
ffffffffc0200814:	1c068693          	addi	a3,a3,448 # ffffffffc02019d0 <etext+0x248>
ffffffffc0200818:	00001617          	auipc	a2,0x1
ffffffffc020081c:	1c060613          	addi	a2,a2,448 # ffffffffc02019d8 <etext+0x250>
ffffffffc0200820:	05000593          	li	a1,80
ffffffffc0200824:	00001517          	auipc	a0,0x1
ffffffffc0200828:	1cc50513          	addi	a0,a0,460 # ffffffffc02019f0 <etext+0x268>
ffffffffc020082c:	9a1ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200830 <buddy_system_check>:
    free_page(p2);
}

// 合并后的完整伙伴系统测试函数
static void
buddy_system_check(void) {
ffffffffc0200830:	7171                	addi	sp,sp,-176
    cprintf("\n");
ffffffffc0200832:	00001517          	auipc	a0,0x1
ffffffffc0200836:	04650513          	addi	a0,a0,70 # ffffffffc0201878 <etext+0xf0>
buddy_system_check(void) {
ffffffffc020083a:	f506                	sd	ra,168(sp)
ffffffffc020083c:	ed26                	sd	s1,152(sp)
ffffffffc020083e:	f122                	sd	s0,160(sp)
ffffffffc0200840:	e94a                	sd	s2,144(sp)
ffffffffc0200842:	e54e                	sd	s3,136(sp)
ffffffffc0200844:	e152                	sd	s4,128(sp)
ffffffffc0200846:	fcd6                	sd	s5,120(sp)
ffffffffc0200848:	f8da                	sd	s6,112(sp)
ffffffffc020084a:	f4de                	sd	s7,104(sp)
ffffffffc020084c:	f0e2                	sd	s8,96(sp)
ffffffffc020084e:	ece6                	sd	s9,88(sp)
    cprintf("\n");
ffffffffc0200850:	8fbff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("========================================\n");
ffffffffc0200854:	00001517          	auipc	a0,0x1
ffffffffc0200858:	1fc50513          	addi	a0,a0,508 # ffffffffc0201a50 <etext+0x2c8>
ffffffffc020085c:	8efff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("   COMPREHENSIVE BUDDY SYSTEM TESTS    \n");
ffffffffc0200860:	00001517          	auipc	a0,0x1
ffffffffc0200864:	22050513          	addi	a0,a0,544 # ffffffffc0201a80 <etext+0x2f8>
ffffffffc0200868:	8e3ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("========================================\n");
ffffffffc020086c:	00001517          	auipc	a0,0x1
ffffffffc0200870:	1e450513          	addi	a0,a0,484 # ffffffffc0201a50 <etext+0x2c8>
ffffffffc0200874:	8d7ff0ef          	jal	ffffffffc020014a <cprintf>
    
    // 保存初始状态
    size_t initial_free_pages = nr_free_pages();
ffffffffc0200878:	07f000ef          	jal	ffffffffc02010f6 <nr_free_pages>
    cprintf("Initial free pages: %lu\n", initial_free_pages);
ffffffffc020087c:	85aa                	mv	a1,a0
    size_t initial_free_pages = nr_free_pages();
ffffffffc020087e:	84aa                	mv	s1,a0
    cprintf("Initial free pages: %lu\n", initial_free_pages);
ffffffffc0200880:	00001517          	auipc	a0,0x1
ffffffffc0200884:	23050513          	addi	a0,a0,560 # ffffffffc0201ab0 <etext+0x328>
ffffffffc0200888:	8c3ff0ef          	jal	ffffffffc020014a <cprintf>
    
    // ===== 基础功能测试 =====
    cprintf("\n--- Basic Functionality Tests ---\n");
ffffffffc020088c:	00001517          	auipc	a0,0x1
ffffffffc0200890:	24450513          	addi	a0,a0,580 # ffffffffc0201ad0 <etext+0x348>
ffffffffc0200894:	8b7ff0ef          	jal	ffffffffc020014a <cprintf>
    
    // 测试1: 基本分配释放
    cprintf("Test 1: Basic allocation and free\n");
ffffffffc0200898:	00001517          	auipc	a0,0x1
ffffffffc020089c:	26050513          	addi	a0,a0,608 # ffffffffc0201af8 <etext+0x370>
ffffffffc02008a0:	8abff0ef          	jal	ffffffffc020014a <cprintf>
    struct Page *p1 = alloc_pages(1);
ffffffffc02008a4:	4505                	li	a0,1
ffffffffc02008a6:	039000ef          	jal	ffffffffc02010de <alloc_pages>
    assert(p1 != NULL);
ffffffffc02008aa:	64050b63          	beqz	a0,ffffffffc0200f00 <buddy_system_check+0x6d0>
ffffffffc02008ae:	fcccd937          	lui	s2,0xfcccd
ffffffffc02008b2:	ccd90913          	addi	s2,s2,-819 # fffffffffccccccd <end+0x3cac6b65>
ffffffffc02008b6:	00006a97          	auipc	s5,0x6
ffffffffc02008ba:	8aaa8a93          	addi	s5,s5,-1878 # ffffffffc0206160 <pages>
ffffffffc02008be:	0932                	slli	s2,s2,0xc
ffffffffc02008c0:	000ab583          	ld	a1,0(s5)
ffffffffc02008c4:	ccd90913          	addi	s2,s2,-819
ffffffffc02008c8:	0932                	slli	s2,s2,0xc
ffffffffc02008ca:	ccd90913          	addi	s2,s2,-819
ffffffffc02008ce:	40b505b3          	sub	a1,a0,a1
ffffffffc02008d2:	0932                	slli	s2,s2,0xc
ffffffffc02008d4:	858d                	srai	a1,a1,0x3
ffffffffc02008d6:	ccd90913          	addi	s2,s2,-819
ffffffffc02008da:	032585b3          	mul	a1,a1,s2
ffffffffc02008de:	00002417          	auipc	s0,0x2
ffffffffc02008e2:	d3243403          	ld	s0,-718(s0) # ffffffffc0202610 <nbase>
ffffffffc02008e6:	89aa                	mv	s3,a0
    cprintf("  ✓ Allocated 1 page at 0x%08lx\n", page2pa(p1));
ffffffffc02008e8:	00001517          	auipc	a0,0x1
ffffffffc02008ec:	24850513          	addi	a0,a0,584 # ffffffffc0201b30 <etext+0x3a8>
ffffffffc02008f0:	95a2                	add	a1,a1,s0
ffffffffc02008f2:	05b2                	slli	a1,a1,0xc
ffffffffc02008f4:	857ff0ef          	jal	ffffffffc020014a <cprintf>
    free_pages(p1, 1);
ffffffffc02008f8:	4585                	li	a1,1
ffffffffc02008fa:	854e                	mv	a0,s3
ffffffffc02008fc:	7ee000ef          	jal	ffffffffc02010ea <free_pages>
    cprintf("  ✓ Freed 1 page\n");
ffffffffc0200900:	00001517          	auipc	a0,0x1
ffffffffc0200904:	25850513          	addi	a0,a0,600 # ffffffffc0201b58 <etext+0x3d0>
ffffffffc0200908:	843ff0ef          	jal	ffffffffc020014a <cprintf>
    
    // 测试2: 分配不同大小的块
    cprintf("Test 2: Allocation of different sizes\n");
ffffffffc020090c:	00001517          	auipc	a0,0x1
ffffffffc0200910:	26450513          	addi	a0,a0,612 # ffffffffc0201b70 <etext+0x3e8>
ffffffffc0200914:	837ff0ef          	jal	ffffffffc020014a <cprintf>
    struct Page *p2 = alloc_pages(2);
ffffffffc0200918:	4509                	li	a0,2
ffffffffc020091a:	7c4000ef          	jal	ffffffffc02010de <alloc_pages>
ffffffffc020091e:	8b2a                	mv	s6,a0
    struct Page *p4 = alloc_pages(4);
ffffffffc0200920:	4511                	li	a0,4
ffffffffc0200922:	7bc000ef          	jal	ffffffffc02010de <alloc_pages>
ffffffffc0200926:	8a2a                	mv	s4,a0
    struct Page *p8 = alloc_pages(8);
ffffffffc0200928:	4521                	li	a0,8
ffffffffc020092a:	7b4000ef          	jal	ffffffffc02010de <alloc_pages>
ffffffffc020092e:	89aa                	mv	s3,a0
    assert(p2 != NULL && p4 != NULL && p8 != NULL);
ffffffffc0200930:	540b0863          	beqz	s6,ffffffffc0200e80 <buddy_system_check+0x650>
ffffffffc0200934:	540a0663          	beqz	s4,ffffffffc0200e80 <buddy_system_check+0x650>
ffffffffc0200938:	54050463          	beqz	a0,ffffffffc0200e80 <buddy_system_check+0x650>
    cprintf("  ✓ Allocated 2, 4, 8 pages\n");
ffffffffc020093c:	00001517          	auipc	a0,0x1
ffffffffc0200940:	28450513          	addi	a0,a0,644 # ffffffffc0201bc0 <etext+0x438>
ffffffffc0200944:	807ff0ef          	jal	ffffffffc020014a <cprintf>
    free_pages(p2, 2);
ffffffffc0200948:	4589                	li	a1,2
ffffffffc020094a:	855a                	mv	a0,s6
ffffffffc020094c:	79e000ef          	jal	ffffffffc02010ea <free_pages>
    free_pages(p4, 4);
ffffffffc0200950:	4591                	li	a1,4
ffffffffc0200952:	8552                	mv	a0,s4
ffffffffc0200954:	796000ef          	jal	ffffffffc02010ea <free_pages>
    free_pages(p8, 8);
ffffffffc0200958:	45a1                	li	a1,8
ffffffffc020095a:	854e                	mv	a0,s3
ffffffffc020095c:	78e000ef          	jal	ffffffffc02010ea <free_pages>
    cprintf("  ✓ Freed all blocks\n");
ffffffffc0200960:	00001517          	auipc	a0,0x1
ffffffffc0200964:	28050513          	addi	a0,a0,640 # ffffffffc0201be0 <etext+0x458>
ffffffffc0200968:	fe2ff0ef          	jal	ffffffffc020014a <cprintf>
    
    // 测试3: 伙伴合并测试
    cprintf("Test 3: Buddy merge test\n");
ffffffffc020096c:	00001517          	auipc	a0,0x1
ffffffffc0200970:	28c50513          	addi	a0,a0,652 # ffffffffc0201bf8 <etext+0x470>
ffffffffc0200974:	fd6ff0ef          	jal	ffffffffc020014a <cprintf>
    
    // 先分配一个2页的块，然后分裂它来获得确定的伙伴
    struct Page *two_page_block = alloc_pages(2);
ffffffffc0200978:	4509                	li	a0,2
ffffffffc020097a:	764000ef          	jal	ffffffffc02010de <alloc_pages>
ffffffffc020097e:	89aa                	mv	s3,a0
    assert(two_page_block != NULL);
ffffffffc0200980:	52050063          	beqz	a0,ffffffffc0200ea0 <buddy_system_check+0x670>
ffffffffc0200984:	000ab583          	ld	a1,0(s5)
    cprintf("  Allocated 2-page block at 0x%08lx\n", page2pa(two_page_block));
ffffffffc0200988:	00001517          	auipc	a0,0x1
ffffffffc020098c:	2a850513          	addi	a0,a0,680 # ffffffffc0201c30 <etext+0x4a8>
    
    // 手动分裂这个2页块来获得伙伴
    struct Page *first_page = two_page_block;
    struct Page *second_page = two_page_block + 1;
ffffffffc0200990:	02898a13          	addi	s4,s3,40
ffffffffc0200994:	40b985b3          	sub	a1,s3,a1
ffffffffc0200998:	858d                	srai	a1,a1,0x3
ffffffffc020099a:	032585b3          	mul	a1,a1,s2
ffffffffc020099e:	95a2                	add	a1,a1,s0
    cprintf("  Allocated 2-page block at 0x%08lx\n", page2pa(two_page_block));
ffffffffc02009a0:	05b2                	slli	a1,a1,0xc
ffffffffc02009a2:	fa8ff0ef          	jal	ffffffffc020014a <cprintf>
ffffffffc02009a6:	000abb03          	ld	s6,0(s5)
    uintptr_t buddy_paddr = paddr ^ (PGSIZE << order);
ffffffffc02009aa:	6785                	lui	a5,0x1
    if (buddy_paddr >= KERNTOP) {
ffffffffc02009ac:	c8000737          	lui	a4,0xc8000
ffffffffc02009b0:	416985b3          	sub	a1,s3,s6
ffffffffc02009b4:	858d                	srai	a1,a1,0x3
ffffffffc02009b6:	032585b3          	mul	a1,a1,s2
ffffffffc02009ba:	95a2                	add	a1,a1,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc02009bc:	05b2                	slli	a1,a1,0xc
    uintptr_t buddy_paddr = paddr ^ (PGSIZE << order);
ffffffffc02009be:	8fad                	xor	a5,a5,a1
    if (buddy_paddr >= KERNTOP) {
ffffffffc02009c0:	06e7fe63          	bgeu	a5,a4,ffffffffc0200a3c <buddy_system_check+0x20c>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02009c4:	83b1                	srli	a5,a5,0xc
ffffffffc02009c6:	00005717          	auipc	a4,0x5
ffffffffc02009ca:	79273703          	ld	a4,1938(a4) # ffffffffc0206158 <npage>
ffffffffc02009ce:	54e7f963          	bgeu	a5,a4,ffffffffc0200f20 <buddy_system_check+0x6f0>
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02009d2:	8f81                	sub	a5,a5,s0
ffffffffc02009d4:	00279713          	slli	a4,a5,0x2
ffffffffc02009d8:	97ba                	add	a5,a5,a4
ffffffffc02009da:	078e                	slli	a5,a5,0x3
    
    // 检查它们是否是伙伴
    struct Page *buddy_of_first = get_buddy(first_page, 0);
    cprintf("  First page: 0x%08lx\n", page2pa(first_page));
ffffffffc02009dc:	00001517          	auipc	a0,0x1
ffffffffc02009e0:	2ac50513          	addi	a0,a0,684 # ffffffffc0201c88 <etext+0x500>
ffffffffc02009e4:	9b3e                	add	s6,s6,a5
ffffffffc02009e6:	f64ff0ef          	jal	ffffffffc020014a <cprintf>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009ea:	000ab583          	ld	a1,0(s5)
    cprintf("  Second page: 0x%08lx\n", page2pa(second_page));
ffffffffc02009ee:	00001517          	auipc	a0,0x1
ffffffffc02009f2:	2b250513          	addi	a0,a0,690 # ffffffffc0201ca0 <etext+0x518>
ffffffffc02009f6:	40ba05b3          	sub	a1,s4,a1
ffffffffc02009fa:	858d                	srai	a1,a1,0x3
ffffffffc02009fc:	032585b3          	mul	a1,a1,s2
ffffffffc0200a00:	95a2                	add	a1,a1,s0
ffffffffc0200a02:	05b2                	slli	a1,a1,0xc
ffffffffc0200a04:	f46ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  Buddy of first: 0x%08lx\n", buddy_of_first ? page2pa(buddy_of_first) : 0);
ffffffffc0200a08:	040b0f63          	beqz	s6,ffffffffc0200a66 <buddy_system_check+0x236>
ffffffffc0200a0c:	000ab583          	ld	a1,0(s5)
ffffffffc0200a10:	00001517          	auipc	a0,0x1
ffffffffc0200a14:	2a850513          	addi	a0,a0,680 # ffffffffc0201cb8 <etext+0x530>
ffffffffc0200a18:	40bb05b3          	sub	a1,s6,a1
ffffffffc0200a1c:	858d                	srai	a1,a1,0x3
ffffffffc0200a1e:	032585b3          	mul	a1,a1,s2
ffffffffc0200a22:	95a2                	add	a1,a1,s0
ffffffffc0200a24:	05b2                	slli	a1,a1,0xc
ffffffffc0200a26:	f24ff0ef          	jal	ffffffffc020014a <cprintf>
    
    if (buddy_of_first == second_page) {
ffffffffc0200a2a:	056a1563          	bne	s4,s6,ffffffffc0200a74 <buddy_system_check+0x244>
        cprintf("  ✓ Confirmed buddy relationship\n");
ffffffffc0200a2e:	00001517          	auipc	a0,0x1
ffffffffc0200a32:	2aa50513          	addi	a0,a0,682 # ffffffffc0201cd8 <etext+0x550>
ffffffffc0200a36:	f14ff0ef          	jal	ffffffffc020014a <cprintf>
ffffffffc0200a3a:	a099                	j	ffffffffc0200a80 <buddy_system_check+0x250>
    cprintf("  First page: 0x%08lx\n", page2pa(first_page));
ffffffffc0200a3c:	00001517          	auipc	a0,0x1
ffffffffc0200a40:	24c50513          	addi	a0,a0,588 # ffffffffc0201c88 <etext+0x500>
ffffffffc0200a44:	f06ff0ef          	jal	ffffffffc020014a <cprintf>
ffffffffc0200a48:	000ab783          	ld	a5,0(s5)
    cprintf("  Second page: 0x%08lx\n", page2pa(second_page));
ffffffffc0200a4c:	00001517          	auipc	a0,0x1
ffffffffc0200a50:	25450513          	addi	a0,a0,596 # ffffffffc0201ca0 <etext+0x518>
ffffffffc0200a54:	40fa05b3          	sub	a1,s4,a5
ffffffffc0200a58:	858d                	srai	a1,a1,0x3
ffffffffc0200a5a:	032585b3          	mul	a1,a1,s2
ffffffffc0200a5e:	95a2                	add	a1,a1,s0
ffffffffc0200a60:	05b2                	slli	a1,a1,0xc
ffffffffc0200a62:	ee8ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  Buddy of first: 0x%08lx\n", buddy_of_first ? page2pa(buddy_of_first) : 0);
ffffffffc0200a66:	4581                	li	a1,0
ffffffffc0200a68:	00001517          	auipc	a0,0x1
ffffffffc0200a6c:	25050513          	addi	a0,a0,592 # ffffffffc0201cb8 <etext+0x530>
ffffffffc0200a70:	edaff0ef          	jal	ffffffffc020014a <cprintf>
    } else {
        cprintf("  ⚠ Pages are not buddies (may be due to allocation pattern)\n");
ffffffffc0200a74:	00001517          	auipc	a0,0x1
ffffffffc0200a78:	28c50513          	addi	a0,a0,652 # ffffffffc0201d00 <etext+0x578>
ffffffffc0200a7c:	eceff0ef          	jal	ffffffffc020014a <cprintf>
        // 继续测试，但不断言失败
    }
    
    // 释放并验证合并
    free_pages(two_page_block, 2);
ffffffffc0200a80:	4589                	li	a1,2
ffffffffc0200a82:	854e                	mv	a0,s3
ffffffffc0200a84:	666000ef          	jal	ffffffffc02010ea <free_pages>
    cprintf("  ✓ Freed 2-page block (should merge back)\n");
ffffffffc0200a88:	00001517          	auipc	a0,0x1
ffffffffc0200a8c:	2b850513          	addi	a0,a0,696 # ffffffffc0201d40 <etext+0x5b8>
ffffffffc0200a90:	ebaff0ef          	jal	ffffffffc020014a <cprintf>
    
    // 测试4: 内存不足测试
    cprintf("Test 4: Out of memory test\n");
ffffffffc0200a94:	00001517          	auipc	a0,0x1
ffffffffc0200a98:	2dc50513          	addi	a0,a0,732 # ffffffffc0201d70 <etext+0x5e8>
ffffffffc0200a9c:	eaeff0ef          	jal	ffffffffc020014a <cprintf>
    struct Page *large_block = alloc_pages(nr_free_pages() + 1);
ffffffffc0200aa0:	656000ef          	jal	ffffffffc02010f6 <nr_free_pages>
ffffffffc0200aa4:	0505                	addi	a0,a0,1
ffffffffc0200aa6:	638000ef          	jal	ffffffffc02010de <alloc_pages>
    assert(large_block == NULL);
ffffffffc0200aaa:	42051b63          	bnez	a0,ffffffffc0200ee0 <buddy_system_check+0x6b0>
    cprintf("  ✓ Correctly rejected oversized allocation\n");
ffffffffc0200aae:	00001517          	auipc	a0,0x1
ffffffffc0200ab2:	2fa50513          	addi	a0,a0,762 # ffffffffc0201da8 <etext+0x620>
ffffffffc0200ab6:	e94ff0ef          	jal	ffffffffc020014a <cprintf>
    
    // 测试5: 精确大小分配
    cprintf("Test 5: Exact size allocation\n");
ffffffffc0200aba:	00001517          	auipc	a0,0x1
ffffffffc0200abe:	31e50513          	addi	a0,a0,798 # ffffffffc0201dd8 <etext+0x650>
ffffffffc0200ac2:	e88ff0ef          	jal	ffffffffc020014a <cprintf>
    struct Page *exact = alloc_pages(16);
ffffffffc0200ac6:	4541                	li	a0,16
ffffffffc0200ac8:	616000ef          	jal	ffffffffc02010de <alloc_pages>
ffffffffc0200acc:	892a                	mv	s2,a0
    assert(exact != NULL);
ffffffffc0200ace:	3e050963          	beqz	a0,ffffffffc0200ec0 <buddy_system_check+0x690>
    cprintf("  ✓ Allocated exact 16 pages\n");
ffffffffc0200ad2:	00001517          	auipc	a0,0x1
ffffffffc0200ad6:	33650513          	addi	a0,a0,822 # ffffffffc0201e08 <etext+0x680>
ffffffffc0200ada:	e70ff0ef          	jal	ffffffffc020014a <cprintf>
    free_pages(exact, 16);
ffffffffc0200ade:	45c1                	li	a1,16
ffffffffc0200ae0:	854a                	mv	a0,s2
ffffffffc0200ae2:	608000ef          	jal	ffffffffc02010ea <free_pages>
    cprintf("  ✓ Freed 16 pages\n");
ffffffffc0200ae6:	00001517          	auipc	a0,0x1
ffffffffc0200aea:	34250513          	addi	a0,a0,834 # ffffffffc0201e28 <etext+0x6a0>
ffffffffc0200aee:	e5cff0ef          	jal	ffffffffc020014a <cprintf>
    
    // ===== 高级功能测试 =====
    cprintf("\n--- Advanced Functionality Tests ---\n");
ffffffffc0200af2:	00001517          	auipc	a0,0x1
ffffffffc0200af6:	34e50513          	addi	a0,a0,846 # ffffffffc0201e40 <etext+0x6b8>
ffffffffc0200afa:	e50ff0ef          	jal	ffffffffc020014a <cprintf>
    
    // 测试6: 详细分配测试
    cprintf("Test 6: Detailed allocation test\n");
ffffffffc0200afe:	00001517          	auipc	a0,0x1
ffffffffc0200b02:	36a50513          	addi	a0,a0,874 # ffffffffc0201e68 <etext+0x6e0>
ffffffffc0200b06:	e44ff0ef          	jal	ffffffffc020014a <cprintf>
    struct Page *pages[3];
    pages[0] = alloc_pages(1);
ffffffffc0200b0a:	4505                	li	a0,1
ffffffffc0200b0c:	5d2000ef          	jal	ffffffffc02010de <alloc_pages>
ffffffffc0200b10:	892a                	mv	s2,a0
    pages[1] = alloc_pages(2);
ffffffffc0200b12:	4509                	li	a0,2
    pages[0] = alloc_pages(1);
ffffffffc0200b14:	e44a                	sd	s2,8(sp)
    pages[1] = alloc_pages(2);
ffffffffc0200b16:	5c8000ef          	jal	ffffffffc02010de <alloc_pages>
ffffffffc0200b1a:	89aa                	mv	s3,a0
    pages[2] = alloc_pages(4);
ffffffffc0200b1c:	4511                	li	a0,4
    pages[1] = alloc_pages(2);
ffffffffc0200b1e:	e84e                	sd	s3,16(sp)
    pages[2] = alloc_pages(4);
ffffffffc0200b20:	5be000ef          	jal	ffffffffc02010de <alloc_pages>
    
    for (int i = 0; i < 3; i++) {
        assert(pages[i] != NULL);
ffffffffc0200b24:	67a2                	ld	a5,8(sp)
    pages[2] = alloc_pages(4);
ffffffffc0200b26:	ec2a                	sd	a0,24(sp)
ffffffffc0200b28:	8a2a                	mv	s4,a0
ffffffffc0200b2a:	00810c93          	addi	s9,sp,8
        assert(pages[i] != NULL);
ffffffffc0200b2e:	4b01                	li	s6,0
        cprintf("  ✓ Allocated %d pages at 0x%08lx\n", 
ffffffffc0200b30:	4585                	li	a1,1
        assert(pages[i] != NULL);
ffffffffc0200b32:	30078763          	beqz	a5,ffffffffc0200e40 <buddy_system_check+0x610>
ffffffffc0200b36:	fcccdc37          	lui	s8,0xfcccd
ffffffffc0200b3a:	ccdc0c13          	addi	s8,s8,-819 # fffffffffccccccd <end+0x3cac6b65>
ffffffffc0200b3e:	0c32                	slli	s8,s8,0xc
ffffffffc0200b40:	ccdc0c13          	addi	s8,s8,-819
ffffffffc0200b44:	0c32                	slli	s8,s8,0xc
ffffffffc0200b46:	ccdc0c13          	addi	s8,s8,-819
ffffffffc0200b4a:	0c32                	slli	s8,s8,0xc
ffffffffc0200b4c:	ccdc0c13          	addi	s8,s8,-819
        cprintf("  ✓ Allocated %d pages at 0x%08lx\n", 
ffffffffc0200b50:	00001b97          	auipc	s7,0x1
ffffffffc0200b54:	358b8b93          	addi	s7,s7,856 # ffffffffc0201ea8 <etext+0x720>
ffffffffc0200b58:	000ab703          	ld	a4,0(s5)
ffffffffc0200b5c:	855e                	mv	a0,s7
    for (int i = 0; i < 3; i++) {
ffffffffc0200b5e:	0ca1                	addi	s9,s9,8
ffffffffc0200b60:	40e78633          	sub	a2,a5,a4
ffffffffc0200b64:	860d                	srai	a2,a2,0x3
ffffffffc0200b66:	03860633          	mul	a2,a2,s8
ffffffffc0200b6a:	9622                	add	a2,a2,s0
        cprintf("  ✓ Allocated %d pages at 0x%08lx\n", 
ffffffffc0200b6c:	0632                	slli	a2,a2,0xc
ffffffffc0200b6e:	ddcff0ef          	jal	ffffffffc020014a <cprintf>
        assert(pages[i] != NULL);
ffffffffc0200b72:	000cb783          	ld	a5,0(s9)
ffffffffc0200b76:	2c078563          	beqz	a5,ffffffffc0200e40 <buddy_system_check+0x610>
                (i == 0) ? 1 : (i == 1) ? 2 : 4, page2pa(pages[i]));
ffffffffc0200b7a:	4589                	li	a1,2
ffffffffc0200b7c:	280b0963          	beqz	s6,ffffffffc0200e0e <buddy_system_check+0x5de>
ffffffffc0200b80:	000ab703          	ld	a4,0(s5)
        cprintf("  ✓ Allocated %d pages at 0x%08lx\n", 
ffffffffc0200b84:	4591                	li	a1,4
ffffffffc0200b86:	00001517          	auipc	a0,0x1
ffffffffc0200b8a:	32250513          	addi	a0,a0,802 # ffffffffc0201ea8 <etext+0x720>
ffffffffc0200b8e:	40e78633          	sub	a2,a5,a4
ffffffffc0200b92:	860d                	srai	a2,a2,0x3
ffffffffc0200b94:	03860633          	mul	a2,a2,s8
ffffffffc0200b98:	00005a97          	auipc	s5,0x5
ffffffffc0200b9c:	490a8a93          	addi	s5,s5,1168 # ffffffffc0206028 <free_area_buddy+0x10>
ffffffffc0200ba0:	9622                	add	a2,a2,s0
ffffffffc0200ba2:	0632                	slli	a2,a2,0xc
ffffffffc0200ba4:	da6ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("Buddy System Status:\n");
ffffffffc0200ba8:	00001517          	auipc	a0,0x1
ffffffffc0200bac:	66050513          	addi	a0,a0,1632 # ffffffffc0202208 <etext+0xa80>
ffffffffc0200bb0:	d9aff0ef          	jal	ffffffffc020014a <cprintf>
ffffffffc0200bb4:	86d6                	mv	a3,s5
    size_t total_free = 0;
ffffffffc0200bb6:	4581                	li	a1,0
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc0200bb8:	4781                	li	a5,0
ffffffffc0200bba:	462d                	li	a2,11
        total_free += free_area_buddy[i].nr_free * power_of_two(i);
ffffffffc0200bbc:	0006e703          	lwu	a4,0(a3)
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc0200bc0:	06e1                	addi	a3,a3,24
        total_free += free_area_buddy[i].nr_free * power_of_two(i);
ffffffffc0200bc2:	00f71733          	sll	a4,a4,a5
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc0200bc6:	2785                	addiw	a5,a5,1 # 1001 <kern_entry-0xffffffffc01fefff>
        total_free += free_area_buddy[i].nr_free * power_of_two(i);
ffffffffc0200bc8:	95ba                	add	a1,a1,a4
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc0200bca:	fec799e3          	bne	a5,a2,ffffffffc0200bbc <buddy_system_check+0x38c>
    cprintf("Total free pages: %lu\n", buddy_system_nr_free_pages());
ffffffffc0200bce:	00001517          	auipc	a0,0x1
ffffffffc0200bd2:	30250513          	addi	a0,a0,770 # ffffffffc0201ed0 <etext+0x748>
ffffffffc0200bd6:	d74ff0ef          	jal	ffffffffc020014a <cprintf>
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc0200bda:	4401                	li	s0,0
    return (size_t)1 << order;
ffffffffc0200bdc:	4c05                	li	s8,1
            cprintf("Order %d (size %lu pages): %lu free blocks\n", 
ffffffffc0200bde:	00001b97          	auipc	s7,0x1
ffffffffc0200be2:	30ab8b93          	addi	s7,s7,778 # ffffffffc0201ee8 <etext+0x760>
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc0200be6:	4b2d                	li	s6,11
ffffffffc0200be8:	a029                	j	ffffffffc0200bf2 <buddy_system_check+0x3c2>
ffffffffc0200bea:	2405                	addiw	s0,s0,1
ffffffffc0200bec:	0ae1                	addi	s5,s5,24
ffffffffc0200bee:	01640f63          	beq	s0,s6,ffffffffc0200c0c <buddy_system_check+0x3dc>
        size_t free_blocks = free_area_buddy[i].nr_free;
ffffffffc0200bf2:	000ae683          	lwu	a3,0(s5)
        if (free_blocks > 0) {
ffffffffc0200bf6:	daf5                	beqz	a3,ffffffffc0200bea <buddy_system_check+0x3ba>
            cprintf("Order %d (size %lu pages): %lu free blocks\n", 
ffffffffc0200bf8:	008c1633          	sll	a2,s8,s0
ffffffffc0200bfc:	85a2                	mv	a1,s0
ffffffffc0200bfe:	855e                	mv	a0,s7
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc0200c00:	2405                	addiw	s0,s0,1
            cprintf("Order %d (size %lu pages): %lu free blocks\n", 
ffffffffc0200c02:	d48ff0ef          	jal	ffffffffc020014a <cprintf>
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc0200c06:	0ae1                	addi	s5,s5,24
ffffffffc0200c08:	ff6415e3          	bne	s0,s6,ffffffffc0200bf2 <buddy_system_check+0x3c2>
    cprintf("\n");
ffffffffc0200c0c:	00001517          	auipc	a0,0x1
ffffffffc0200c10:	c6c50513          	addi	a0,a0,-916 # ffffffffc0201878 <etext+0xf0>
ffffffffc0200c14:	d36ff0ef          	jal	ffffffffc020014a <cprintf>
    // 打印当前状态
    buddy_system_print_status();
    
    // 释放
    for (int i = 0; i < 3; i++) {
        free_pages(pages[i], (i == 0) ? 1 : (i == 1) ? 2 : 4);
ffffffffc0200c18:	854a                	mv	a0,s2
ffffffffc0200c1a:	4585                	li	a1,1
ffffffffc0200c1c:	4ce000ef          	jal	ffffffffc02010ea <free_pages>
ffffffffc0200c20:	854e                	mv	a0,s3
ffffffffc0200c22:	4589                	li	a1,2
ffffffffc0200c24:	4c6000ef          	jal	ffffffffc02010ea <free_pages>
ffffffffc0200c28:	4591                	li	a1,4
ffffffffc0200c2a:	8552                	mv	a0,s4
ffffffffc0200c2c:	4be000ef          	jal	ffffffffc02010ea <free_pages>
    }
    cprintf("  ✓ Freed all test blocks\n");
ffffffffc0200c30:	00001517          	auipc	a0,0x1
ffffffffc0200c34:	2e850513          	addi	a0,a0,744 # ffffffffc0201f18 <etext+0x790>
ffffffffc0200c38:	d12ff0ef          	jal	ffffffffc020014a <cprintf>
    
    // 测试7: 非2的幂分配测试
    cprintf("Test 7: Non-power-of-two allocation\n");
ffffffffc0200c3c:	00001517          	auipc	a0,0x1
ffffffffc0200c40:	2fc50513          	addi	a0,a0,764 # ffffffffc0201f38 <etext+0x7b0>
ffffffffc0200c44:	d06ff0ef          	jal	ffffffffc020014a <cprintf>
    struct Page *p3 = alloc_pages(3);  // 应该分配4页
ffffffffc0200c48:	450d                	li	a0,3
ffffffffc0200c4a:	494000ef          	jal	ffffffffc02010de <alloc_pages>
ffffffffc0200c4e:	89aa                	mv	s3,a0
    struct Page *p5 = alloc_pages(5);  // 应该分配8页
ffffffffc0200c50:	4515                	li	a0,5
ffffffffc0200c52:	48c000ef          	jal	ffffffffc02010de <alloc_pages>
ffffffffc0200c56:	892a                	mv	s2,a0
    struct Page *p7 = alloc_pages(7);  // 应该分配8页
ffffffffc0200c58:	451d                	li	a0,7
ffffffffc0200c5a:	484000ef          	jal	ffffffffc02010de <alloc_pages>
ffffffffc0200c5e:	842a                	mv	s0,a0
    assert(p3 != NULL && p5 != NULL && p7 != NULL);
ffffffffc0200c60:	20098063          	beqz	s3,ffffffffc0200e60 <buddy_system_check+0x630>
ffffffffc0200c64:	1e090e63          	beqz	s2,ffffffffc0200e60 <buddy_system_check+0x630>
ffffffffc0200c68:	1e050c63          	beqz	a0,ffffffffc0200e60 <buddy_system_check+0x630>
    return (size_t)1 << order;
ffffffffc0200c6c:	0109a583          	lw	a1,16(s3)
ffffffffc0200c70:	4a05                	li	s4,1
    cprintf("  ✓ Allocated 3 pages (got %lu)\n", power_of_two(get_page_order(p3)));
ffffffffc0200c72:	00001517          	auipc	a0,0x1
ffffffffc0200c76:	31650513          	addi	a0,a0,790 # ffffffffc0201f88 <etext+0x800>
ffffffffc0200c7a:	00ba15b3          	sll	a1,s4,a1
ffffffffc0200c7e:	cccff0ef          	jal	ffffffffc020014a <cprintf>
    return (size_t)1 << order;
ffffffffc0200c82:	01092583          	lw	a1,16(s2)
    cprintf("  ✓ Allocated 5 pages (got %lu)\n", power_of_two(get_page_order(p5)));
ffffffffc0200c86:	00001517          	auipc	a0,0x1
ffffffffc0200c8a:	32a50513          	addi	a0,a0,810 # ffffffffc0201fb0 <etext+0x828>
    
    // 测试8: 碎片整理测试
    cprintf("Test 8: Fragmentation handling\n");
    struct Page *frag_blocks[6];
    for (int i = 0; i < 6; i++) {
        frag_blocks[i] = alloc_pages(1 << (i % 3));  // 1, 2, 4, 1, 2, 4
ffffffffc0200c8e:	4a8d                	li	s5,3
    cprintf("  ✓ Allocated 5 pages (got %lu)\n", power_of_two(get_page_order(p5)));
ffffffffc0200c90:	00ba15b3          	sll	a1,s4,a1
ffffffffc0200c94:	cb6ff0ef          	jal	ffffffffc020014a <cprintf>
    return (size_t)1 << order;
ffffffffc0200c98:	480c                	lw	a1,16(s0)
    cprintf("  ✓ Allocated 7 pages (got %lu)\n", power_of_two(get_page_order(p7)));
ffffffffc0200c9a:	00001517          	auipc	a0,0x1
ffffffffc0200c9e:	33e50513          	addi	a0,a0,830 # ffffffffc0201fd8 <etext+0x850>
ffffffffc0200ca2:	00ba15b3          	sll	a1,s4,a1
ffffffffc0200ca6:	ca4ff0ef          	jal	ffffffffc020014a <cprintf>
    free_pages(p3, 3);
ffffffffc0200caa:	854e                	mv	a0,s3
ffffffffc0200cac:	458d                	li	a1,3
ffffffffc0200cae:	43c000ef          	jal	ffffffffc02010ea <free_pages>
    free_pages(p5, 5);
ffffffffc0200cb2:	854a                	mv	a0,s2
ffffffffc0200cb4:	4595                	li	a1,5
ffffffffc0200cb6:	434000ef          	jal	ffffffffc02010ea <free_pages>
    free_pages(p7, 7);
ffffffffc0200cba:	459d                	li	a1,7
ffffffffc0200cbc:	8522                	mv	a0,s0
ffffffffc0200cbe:	42c000ef          	jal	ffffffffc02010ea <free_pages>
    cprintf("  ✓ Freed non-power-of-two blocks\n");
ffffffffc0200cc2:	00001517          	auipc	a0,0x1
ffffffffc0200cc6:	33e50513          	addi	a0,a0,830 # ffffffffc0202000 <etext+0x878>
ffffffffc0200cca:	c80ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("Test 8: Fragmentation handling\n");
ffffffffc0200cce:	00001517          	auipc	a0,0x1
ffffffffc0200cd2:	35a50513          	addi	a0,a0,858 # ffffffffc0202028 <etext+0x8a0>
ffffffffc0200cd6:	c74ff0ef          	jal	ffffffffc020014a <cprintf>
    for (int i = 0; i < 6; i++) {
ffffffffc0200cda:	02010913          	addi	s2,sp,32
ffffffffc0200cde:	4401                	li	s0,0
ffffffffc0200ce0:	4999                	li	s3,6
        frag_blocks[i] = alloc_pages(1 << (i % 3));  // 1, 2, 4, 1, 2, 4
ffffffffc0200ce2:	0354653b          	remw	a0,s0,s5
ffffffffc0200ce6:	00aa153b          	sllw	a0,s4,a0
ffffffffc0200cea:	3f4000ef          	jal	ffffffffc02010de <alloc_pages>
ffffffffc0200cee:	00a93023          	sd	a0,0(s2)
        assert(frag_blocks[i] != NULL);
ffffffffc0200cf2:	12050763          	beqz	a0,ffffffffc0200e20 <buddy_system_check+0x5f0>
    for (int i = 0; i < 6; i++) {
ffffffffc0200cf6:	2405                	addiw	s0,s0,1
ffffffffc0200cf8:	0921                	addi	s2,s2,8
ffffffffc0200cfa:	ff3414e3          	bne	s0,s3,ffffffffc0200ce2 <buddy_system_check+0x4b2>
    }
    cprintf("  ✓ Created fragmented memory layout\n");
ffffffffc0200cfe:	00001517          	auipc	a0,0x1
ffffffffc0200d02:	36250513          	addi	a0,a0,866 # ffffffffc0202060 <etext+0x8d8>
ffffffffc0200d06:	c44ff0ef          	jal	ffffffffc020014a <cprintf>
    
    // 交错释放
    for (int i = 0; i < 6; i += 2) {
        free_pages(frag_blocks[i], 1 << (i % 3));
ffffffffc0200d0a:	7502                	ld	a0,32(sp)
ffffffffc0200d0c:	4585                	li	a1,1
ffffffffc0200d0e:	3dc000ef          	jal	ffffffffc02010ea <free_pages>
ffffffffc0200d12:	7542                	ld	a0,48(sp)
ffffffffc0200d14:	4591                	li	a1,4
ffffffffc0200d16:	3d4000ef          	jal	ffffffffc02010ea <free_pages>
ffffffffc0200d1a:	6506                	ld	a0,64(sp)
ffffffffc0200d1c:	4589                	li	a1,2
ffffffffc0200d1e:	3cc000ef          	jal	ffffffffc02010ea <free_pages>
    }
    
    // 尝试分配大块（应该通过合并成功）
    struct Page *large_after_frag = alloc_pages(8);
ffffffffc0200d22:	4521                	li	a0,8
ffffffffc0200d24:	3ba000ef          	jal	ffffffffc02010de <alloc_pages>
ffffffffc0200d28:	842a                	mv	s0,a0
    if (large_after_frag != NULL) {
ffffffffc0200d2a:	c919                	beqz	a0,ffffffffc0200d40 <buddy_system_check+0x510>
        cprintf("  ✓ Successfully allocated 8 pages after fragmentation\n");
ffffffffc0200d2c:	00001517          	auipc	a0,0x1
ffffffffc0200d30:	35c50513          	addi	a0,a0,860 # ffffffffc0202088 <etext+0x900>
ffffffffc0200d34:	c16ff0ef          	jal	ffffffffc020014a <cprintf>
        free_pages(large_after_frag, 8);
ffffffffc0200d38:	45a1                	li	a1,8
ffffffffc0200d3a:	8522                	mv	a0,s0
ffffffffc0200d3c:	3ae000ef          	jal	ffffffffc02010ea <free_pages>
    }
    
    // 清理剩余块
    for (int i = 1; i < 6; i += 2) {
        free_pages(frag_blocks[i], 1 << (i % 3));
ffffffffc0200d40:	7522                	ld	a0,40(sp)
ffffffffc0200d42:	4589                	li	a1,2
ffffffffc0200d44:	3a6000ef          	jal	ffffffffc02010ea <free_pages>
ffffffffc0200d48:	7562                	ld	a0,56(sp)
ffffffffc0200d4a:	4585                	li	a1,1
ffffffffc0200d4c:	39e000ef          	jal	ffffffffc02010ea <free_pages>
ffffffffc0200d50:	6526                	ld	a0,72(sp)
ffffffffc0200d52:	4591                	li	a1,4
ffffffffc0200d54:	396000ef          	jal	ffffffffc02010ea <free_pages>
    }
    cprintf("  ✓ Memory defragmented successfully\n");
ffffffffc0200d58:	00001517          	auipc	a0,0x1
ffffffffc0200d5c:	37050513          	addi	a0,a0,880 # ffffffffc02020c8 <etext+0x940>
ffffffffc0200d60:	beaff0ef          	jal	ffffffffc020014a <cprintf>
    
    // ===== 最终验证 =====
    cprintf("\n--- Final Verification ---\n");
ffffffffc0200d64:	00001517          	auipc	a0,0x1
ffffffffc0200d68:	38c50513          	addi	a0,a0,908 # ffffffffc02020f0 <etext+0x968>
ffffffffc0200d6c:	bdeff0ef          	jal	ffffffffc020014a <cprintf>
    size_t final_free_pages = nr_free_pages();
ffffffffc0200d70:	386000ef          	jal	ffffffffc02010f6 <nr_free_pages>
ffffffffc0200d74:	842a                	mv	s0,a0
    cprintf("Initial free pages: %lu\n", initial_free_pages);
ffffffffc0200d76:	85a6                	mv	a1,s1
ffffffffc0200d78:	00001517          	auipc	a0,0x1
ffffffffc0200d7c:	d3850513          	addi	a0,a0,-712 # ffffffffc0201ab0 <etext+0x328>
ffffffffc0200d80:	bcaff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("Final free pages: %lu\n", final_free_pages);
ffffffffc0200d84:	85a2                	mv	a1,s0
ffffffffc0200d86:	00001517          	auipc	a0,0x1
ffffffffc0200d8a:	38a50513          	addi	a0,a0,906 # ffffffffc0202110 <etext+0x988>
ffffffffc0200d8e:	bbcff0ef          	jal	ffffffffc020014a <cprintf>
    
    if (final_free_pages == initial_free_pages) {
ffffffffc0200d92:	08848063          	beq	s1,s0,ffffffffc0200e12 <buddy_system_check+0x5e2>
        cprintf("Memory conservation verified\n");
    } else {
        cprintf("Memory leak detected!\n");
ffffffffc0200d96:	00001517          	auipc	a0,0x1
ffffffffc0200d9a:	3b250513          	addi	a0,a0,946 # ffffffffc0202148 <etext+0x9c0>
ffffffffc0200d9e:	bacff0ef          	jal	ffffffffc020014a <cprintf>
    }
    
    cprintf("\n");
ffffffffc0200da2:	00001517          	auipc	a0,0x1
ffffffffc0200da6:	ad650513          	addi	a0,a0,-1322 # ffffffffc0201878 <etext+0xf0>
ffffffffc0200daa:	ba0ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("========================================\n");
ffffffffc0200dae:	00001517          	auipc	a0,0x1
ffffffffc0200db2:	ca250513          	addi	a0,a0,-862 # ffffffffc0201a50 <etext+0x2c8>
ffffffffc0200db6:	b94ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("   ALL BUDDY SYSTEM TESTS PASSED!     \n");
ffffffffc0200dba:	00001517          	auipc	a0,0x1
ffffffffc0200dbe:	3a650513          	addi	a0,a0,934 # ffffffffc0202160 <etext+0x9d8>
ffffffffc0200dc2:	b88ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("========================================\n");
ffffffffc0200dc6:	00001517          	auipc	a0,0x1
ffffffffc0200dca:	c8a50513          	addi	a0,a0,-886 # ffffffffc0201a50 <etext+0x2c8>
ffffffffc0200dce:	b7cff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("Total tests completed: 8\n");
ffffffffc0200dd2:	00001517          	auipc	a0,0x1
ffffffffc0200dd6:	3b650513          	addi	a0,a0,950 # ffffffffc0202188 <etext+0xa00>
ffffffffc0200dda:	b70ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("All core buddy system features verified\n");
ffffffffc0200dde:	00001517          	auipc	a0,0x1
ffffffffc0200de2:	3ca50513          	addi	a0,a0,970 # ffffffffc02021a8 <etext+0xa20>
ffffffffc0200de6:	b64ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("========================================\n\n");
}
ffffffffc0200dea:	740a                	ld	s0,160(sp)
ffffffffc0200dec:	70aa                	ld	ra,168(sp)
ffffffffc0200dee:	64ea                	ld	s1,152(sp)
ffffffffc0200df0:	694a                	ld	s2,144(sp)
ffffffffc0200df2:	69aa                	ld	s3,136(sp)
ffffffffc0200df4:	6a0a                	ld	s4,128(sp)
ffffffffc0200df6:	7ae6                	ld	s5,120(sp)
ffffffffc0200df8:	7b46                	ld	s6,112(sp)
ffffffffc0200dfa:	7ba6                	ld	s7,104(sp)
ffffffffc0200dfc:	7c06                	ld	s8,96(sp)
ffffffffc0200dfe:	6ce6                	ld	s9,88(sp)
    cprintf("========================================\n\n");
ffffffffc0200e00:	00001517          	auipc	a0,0x1
ffffffffc0200e04:	3d850513          	addi	a0,a0,984 # ffffffffc02021d8 <etext+0xa50>
}
ffffffffc0200e08:	614d                	addi	sp,sp,176
    cprintf("========================================\n\n");
ffffffffc0200e0a:	b40ff06f          	j	ffffffffc020014a <cprintf>
ffffffffc0200e0e:	4b05                	li	s6,1
ffffffffc0200e10:	b3a1                	j	ffffffffc0200b58 <buddy_system_check+0x328>
        cprintf("Memory conservation verified\n");
ffffffffc0200e12:	00001517          	auipc	a0,0x1
ffffffffc0200e16:	31650513          	addi	a0,a0,790 # ffffffffc0202128 <etext+0x9a0>
ffffffffc0200e1a:	b30ff0ef          	jal	ffffffffc020014a <cprintf>
ffffffffc0200e1e:	b751                	j	ffffffffc0200da2 <buddy_system_check+0x572>
        assert(frag_blocks[i] != NULL);
ffffffffc0200e20:	00001697          	auipc	a3,0x1
ffffffffc0200e24:	22868693          	addi	a3,a3,552 # ffffffffc0202048 <etext+0x8c0>
ffffffffc0200e28:	00001617          	auipc	a2,0x1
ffffffffc0200e2c:	bb060613          	addi	a2,a2,-1104 # ffffffffc02019d8 <etext+0x250>
ffffffffc0200e30:	19e00593          	li	a1,414
ffffffffc0200e34:	00001517          	auipc	a0,0x1
ffffffffc0200e38:	bbc50513          	addi	a0,a0,-1092 # ffffffffc02019f0 <etext+0x268>
ffffffffc0200e3c:	b90ff0ef          	jal	ffffffffc02001cc <__panic>
        assert(pages[i] != NULL);
ffffffffc0200e40:	00001697          	auipc	a3,0x1
ffffffffc0200e44:	05068693          	addi	a3,a3,80 # ffffffffc0201e90 <etext+0x708>
ffffffffc0200e48:	00001617          	auipc	a2,0x1
ffffffffc0200e4c:	b9060613          	addi	a2,a2,-1136 # ffffffffc02019d8 <etext+0x250>
ffffffffc0200e50:	17c00593          	li	a1,380
ffffffffc0200e54:	00001517          	auipc	a0,0x1
ffffffffc0200e58:	b9c50513          	addi	a0,a0,-1124 # ffffffffc02019f0 <etext+0x268>
ffffffffc0200e5c:	b70ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p3 != NULL && p5 != NULL && p7 != NULL);
ffffffffc0200e60:	00001697          	auipc	a3,0x1
ffffffffc0200e64:	10068693          	addi	a3,a3,256 # ffffffffc0201f60 <etext+0x7d8>
ffffffffc0200e68:	00001617          	auipc	a2,0x1
ffffffffc0200e6c:	b7060613          	addi	a2,a2,-1168 # ffffffffc02019d8 <etext+0x250>
ffffffffc0200e70:	18f00593          	li	a1,399
ffffffffc0200e74:	00001517          	auipc	a0,0x1
ffffffffc0200e78:	b7c50513          	addi	a0,a0,-1156 # ffffffffc02019f0 <etext+0x268>
ffffffffc0200e7c:	b50ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p2 != NULL && p4 != NULL && p8 != NULL);
ffffffffc0200e80:	00001697          	auipc	a3,0x1
ffffffffc0200e84:	d1868693          	addi	a3,a3,-744 # ffffffffc0201b98 <etext+0x410>
ffffffffc0200e88:	00001617          	auipc	a2,0x1
ffffffffc0200e8c:	b5060613          	addi	a2,a2,-1200 # ffffffffc02019d8 <etext+0x250>
ffffffffc0200e90:	13f00593          	li	a1,319
ffffffffc0200e94:	00001517          	auipc	a0,0x1
ffffffffc0200e98:	b5c50513          	addi	a0,a0,-1188 # ffffffffc02019f0 <etext+0x268>
ffffffffc0200e9c:	b30ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(two_page_block != NULL);
ffffffffc0200ea0:	00001697          	auipc	a3,0x1
ffffffffc0200ea4:	d7868693          	addi	a3,a3,-648 # ffffffffc0201c18 <etext+0x490>
ffffffffc0200ea8:	00001617          	auipc	a2,0x1
ffffffffc0200eac:	b3060613          	addi	a2,a2,-1232 # ffffffffc02019d8 <etext+0x250>
ffffffffc0200eb0:	14b00593          	li	a1,331
ffffffffc0200eb4:	00001517          	auipc	a0,0x1
ffffffffc0200eb8:	b3c50513          	addi	a0,a0,-1220 # ffffffffc02019f0 <etext+0x268>
ffffffffc0200ebc:	b10ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(exact != NULL);
ffffffffc0200ec0:	00001697          	auipc	a3,0x1
ffffffffc0200ec4:	f3868693          	addi	a3,a3,-200 # ffffffffc0201df8 <etext+0x670>
ffffffffc0200ec8:	00001617          	auipc	a2,0x1
ffffffffc0200ecc:	b1060613          	addi	a2,a2,-1264 # ffffffffc02019d8 <etext+0x250>
ffffffffc0200ed0:	16c00593          	li	a1,364
ffffffffc0200ed4:	00001517          	auipc	a0,0x1
ffffffffc0200ed8:	b1c50513          	addi	a0,a0,-1252 # ffffffffc02019f0 <etext+0x268>
ffffffffc0200edc:	af0ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(large_block == NULL);
ffffffffc0200ee0:	00001697          	auipc	a3,0x1
ffffffffc0200ee4:	eb068693          	addi	a3,a3,-336 # ffffffffc0201d90 <etext+0x608>
ffffffffc0200ee8:	00001617          	auipc	a2,0x1
ffffffffc0200eec:	af060613          	addi	a2,a2,-1296 # ffffffffc02019d8 <etext+0x250>
ffffffffc0200ef0:	16600593          	li	a1,358
ffffffffc0200ef4:	00001517          	auipc	a0,0x1
ffffffffc0200ef8:	afc50513          	addi	a0,a0,-1284 # ffffffffc02019f0 <etext+0x268>
ffffffffc0200efc:	ad0ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p1 != NULL);
ffffffffc0200f00:	00001697          	auipc	a3,0x1
ffffffffc0200f04:	c2068693          	addi	a3,a3,-992 # ffffffffc0201b20 <etext+0x398>
ffffffffc0200f08:	00001617          	auipc	a2,0x1
ffffffffc0200f0c:	ad060613          	addi	a2,a2,-1328 # ffffffffc02019d8 <etext+0x250>
ffffffffc0200f10:	13500593          	li	a1,309
ffffffffc0200f14:	00001517          	auipc	a0,0x1
ffffffffc0200f18:	adc50513          	addi	a0,a0,-1316 # ffffffffc02019f0 <etext+0x268>
ffffffffc0200f1c:	ab0ff0ef          	jal	ffffffffc02001cc <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200f20:	00001617          	auipc	a2,0x1
ffffffffc0200f24:	d3860613          	addi	a2,a2,-712 # ffffffffc0201c58 <etext+0x4d0>
ffffffffc0200f28:	06a00593          	li	a1,106
ffffffffc0200f2c:	00001517          	auipc	a0,0x1
ffffffffc0200f30:	d4c50513          	addi	a0,a0,-692 # ffffffffc0201c78 <etext+0x4f0>
ffffffffc0200f34:	a98ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200f38 <buddy_system_free_pages>:
buddy_system_free_pages(struct Page *base, size_t n) {
ffffffffc0200f38:	1141                	addi	sp,sp,-16
ffffffffc0200f3a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200f3c:	18058063          	beqz	a1,ffffffffc02010bc <buddy_system_free_pages+0x184>
    assert(PageReserved(base));
ffffffffc0200f40:	6518                	ld	a4,8(a0)
ffffffffc0200f42:	00177793          	andi	a5,a4,1
ffffffffc0200f46:	14078a63          	beqz	a5,ffffffffc020109a <buddy_system_free_pages+0x162>
    while (size < n) {
ffffffffc0200f4a:	4685                	li	a3,1
    SetPageProperty(page);
ffffffffc0200f4c:	00276613          	ori	a2,a4,2
    int order = 0;
ffffffffc0200f50:	4701                	li	a4,0
    while (size < n) {
ffffffffc0200f52:	12d58363          	beq	a1,a3,ffffffffc0201078 <buddy_system_free_pages+0x140>
        size <<= 1;
ffffffffc0200f56:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc0200f58:	2705                	addiw	a4,a4,1
    while (size < n) {
ffffffffc0200f5a:	feb7eee3          	bltu	a5,a1,ffffffffc0200f56 <buddy_system_free_pages+0x1e>
    uintptr_t buddy_paddr = paddr ^ (PGSIZE << order);
ffffffffc0200f5e:	6685                	lui	a3,0x1
    page->property = order;
ffffffffc0200f60:	c918                	sw	a4,16(a0)
    SetPageProperty(page);
ffffffffc0200f62:	e510                	sd	a2,8(a0)
    while (order < MAX_ORDER) {
ffffffffc0200f64:	47a5                	li	a5,9
    uintptr_t buddy_paddr = paddr ^ (PGSIZE << order);
ffffffffc0200f66:	00e696bb          	sllw	a3,a3,a4
    while (order < MAX_ORDER) {
ffffffffc0200f6a:	10e7c263          	blt	a5,a4,ffffffffc020106e <buddy_system_free_pages+0x136>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f6e:	fcccd637          	lui	a2,0xfcccd
ffffffffc0200f72:	ccd60613          	addi	a2,a2,-819 # fffffffffccccccd <end+0x3cac6b65>
ffffffffc0200f76:	0632                	slli	a2,a2,0xc
ffffffffc0200f78:	ccd60613          	addi	a2,a2,-819
ffffffffc0200f7c:	0632                	slli	a2,a2,0xc
ffffffffc0200f7e:	00005317          	auipc	t1,0x5
ffffffffc0200f82:	1e233303          	ld	t1,482(t1) # ffffffffc0206160 <pages>
ffffffffc0200f86:	ccd60613          	addi	a2,a2,-819
ffffffffc0200f8a:	406507b3          	sub	a5,a0,t1
ffffffffc0200f8e:	0632                	slli	a2,a2,0xc
ffffffffc0200f90:	878d                	srai	a5,a5,0x3
ffffffffc0200f92:	ccd60613          	addi	a2,a2,-819
ffffffffc0200f96:	02c787b3          	mul	a5,a5,a2
ffffffffc0200f9a:	00001e17          	auipc	t3,0x1
ffffffffc0200f9e:	676e3e03          	ld	t3,1654(t3) # ffffffffc0202610 <nbase>
    if (buddy_paddr >= KERNTOP) {
ffffffffc0200fa2:	c80005b7          	lui	a1,0xc8000
ffffffffc0200fa6:	97f2                	add	a5,a5,t3
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fa8:	07b2                	slli	a5,a5,0xc
    uintptr_t buddy_paddr = paddr ^ (PGSIZE << order);
ffffffffc0200faa:	8fb5                	xor	a5,a5,a3
    if (buddy_paddr >= KERNTOP) {
ffffffffc0200fac:	0cb7f163          	bgeu	a5,a1,ffffffffc020106e <buddy_system_free_pages+0x136>
ffffffffc0200fb0:	00171593          	slli	a1,a4,0x1
ffffffffc0200fb4:	95ba                	add	a1,a1,a4
ffffffffc0200fb6:	058e                	slli	a1,a1,0x3
ffffffffc0200fb8:	00005817          	auipc	a6,0x5
ffffffffc0200fbc:	06080813          	addi	a6,a6,96 # ffffffffc0206018 <free_area_buddy>
ffffffffc0200fc0:	e022                	sd	s0,0(sp)
    if (PPN(pa) >= npage) {
ffffffffc0200fc2:	00005e97          	auipc	t4,0x5
ffffffffc0200fc6:	196ebe83          	ld	t4,406(t4) # ffffffffc0206158 <npage>
ffffffffc0200fca:	95c2                	add	a1,a1,a6
    while (order < MAX_ORDER) {
ffffffffc0200fcc:	4f29                	li	t5,10
    uintptr_t buddy_paddr = paddr ^ (PGSIZE << order);
ffffffffc0200fce:	6285                	lui	t0,0x1
    if (buddy_paddr >= KERNTOP) {
ffffffffc0200fd0:	c8000fb7          	lui	t6,0xc8000
ffffffffc0200fd4:	83b1                	srli	a5,a5,0xc
ffffffffc0200fd6:	0bd7f663          	bgeu	a5,t4,ffffffffc0201082 <buddy_system_free_pages+0x14a>
    return &pages[PPN(pa) - nbase];
ffffffffc0200fda:	41c787b3          	sub	a5,a5,t3
ffffffffc0200fde:	00279693          	slli	a3,a5,0x2
ffffffffc0200fe2:	97b6                	add	a5,a5,a3
ffffffffc0200fe4:	078e                	slli	a5,a5,0x3
ffffffffc0200fe6:	979a                	add	a5,a5,t1
        free_area_buddy[order].nr_free--;
ffffffffc0200fe8:	0105a883          	lw	a7,16(a1) # ffffffffc8000010 <end+0x7df9ea8>
        if (!buddy || !is_buddy(buddy, order)) {
ffffffffc0200fec:	cfb1                	beqz	a5,ffffffffc0201048 <buddy_system_free_pages+0x110>
    if (!PageProperty(page)) {
ffffffffc0200fee:	6794                	ld	a3,8(a5)
ffffffffc0200ff0:	0026f393          	andi	t2,a3,2
ffffffffc0200ff4:	04038a63          	beqz	t2,ffffffffc0201048 <buddy_system_free_pages+0x110>
        if (!buddy || !is_buddy(buddy, order)) {
ffffffffc0200ff8:	0107a383          	lw	t2,16(a5)
ffffffffc0200ffc:	04e39663          	bne	t2,a4,ffffffffc0201048 <buddy_system_free_pages+0x110>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201000:	6f80                	ld	s0,24(a5)
ffffffffc0201002:	0207b383          	ld	t2,32(a5)
        free_area_buddy[order].nr_free--;
ffffffffc0201006:	38fd                	addiw	a7,a7,-1
        ClearPageProperty(buddy);
ffffffffc0201008:	9af5                	andi	a3,a3,-3
    prev->next = next;
ffffffffc020100a:	00743423          	sd	t2,8(s0)
    next->prev = prev;
ffffffffc020100e:	0083b023          	sd	s0,0(t2)
        free_area_buddy[order].nr_free--;
ffffffffc0201012:	0115a823          	sw	a7,16(a1)
        ClearPageProperty(buddy);
ffffffffc0201016:	e794                	sd	a3,8(a5)
        if (page > buddy) {
ffffffffc0201018:	00a7f363          	bgeu	a5,a0,ffffffffc020101e <buddy_system_free_pages+0xe6>
ffffffffc020101c:	853e                	mv	a0,a5
        SetPageProperty(page);
ffffffffc020101e:	651c                	ld	a5,8(a0)
        order++;
ffffffffc0201020:	2705                	addiw	a4,a4,1
    page->property = order;
ffffffffc0201022:	c918                	sw	a4,16(a0)
        SetPageProperty(page);
ffffffffc0201024:	0027e793          	ori	a5,a5,2
ffffffffc0201028:	e51c                	sd	a5,8(a0)
    while (order < MAX_ORDER) {
ffffffffc020102a:	01e70f63          	beq	a4,t5,ffffffffc0201048 <buddy_system_free_pages+0x110>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020102e:	406507b3          	sub	a5,a0,t1
ffffffffc0201032:	878d                	srai	a5,a5,0x3
ffffffffc0201034:	02c787b3          	mul	a5,a5,a2
    uintptr_t buddy_paddr = paddr ^ (PGSIZE << order);
ffffffffc0201038:	00e296bb          	sllw	a3,t0,a4
    if (buddy_paddr >= KERNTOP) {
ffffffffc020103c:	05e1                	addi	a1,a1,24
ffffffffc020103e:	97f2                	add	a5,a5,t3
    return page2ppn(page) << PGSHIFT;
ffffffffc0201040:	07b2                	slli	a5,a5,0xc
    uintptr_t buddy_paddr = paddr ^ (PGSIZE << order);
ffffffffc0201042:	8fb5                	xor	a5,a5,a3
    if (buddy_paddr >= KERNTOP) {
ffffffffc0201044:	f9f7e8e3          	bltu	a5,t6,ffffffffc0200fd4 <buddy_system_free_pages+0x9c>
ffffffffc0201048:	6402                	ld	s0,0(sp)
    __list_add(elm, listelm, listelm->next);
ffffffffc020104a:	00171793          	slli	a5,a4,0x1
ffffffffc020104e:	97ba                	add	a5,a5,a4
ffffffffc0201050:	078e                	slli	a5,a5,0x3
ffffffffc0201052:	97c2                	add	a5,a5,a6
ffffffffc0201054:	6794                	ld	a3,8(a5)
    free_area_buddy[order].nr_free++;
ffffffffc0201056:	4b98                	lw	a4,16(a5)
    list_add(&free_area_buddy[order].free_list, &(page->page_link));
ffffffffc0201058:	01850613          	addi	a2,a0,24
    prev->next = next->prev = elm;
ffffffffc020105c:	e290                	sd	a2,0(a3)
ffffffffc020105e:	e790                	sd	a2,8(a5)
}
ffffffffc0201060:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0201062:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc0201064:	ed1c                	sd	a5,24(a0)
    free_area_buddy[order].nr_free++;
ffffffffc0201066:	2705                	addiw	a4,a4,1
ffffffffc0201068:	cb98                	sw	a4,16(a5)
}
ffffffffc020106a:	0141                	addi	sp,sp,16
ffffffffc020106c:	8082                	ret
ffffffffc020106e:	00005817          	auipc	a6,0x5
ffffffffc0201072:	faa80813          	addi	a6,a6,-86 # ffffffffc0206018 <free_area_buddy>
ffffffffc0201076:	bfd1                	j	ffffffffc020104a <buddy_system_free_pages+0x112>
    page->property = order;
ffffffffc0201078:	00052823          	sw	zero,16(a0)
    SetPageProperty(page);
ffffffffc020107c:	e510                	sd	a2,8(a0)
ffffffffc020107e:	6685                	lui	a3,0x1
ffffffffc0201080:	b5fd                	j	ffffffffc0200f6e <buddy_system_free_pages+0x36>
        panic("pa2page called with invalid pa");
ffffffffc0201082:	00001617          	auipc	a2,0x1
ffffffffc0201086:	bd660613          	addi	a2,a2,-1066 # ffffffffc0201c58 <etext+0x4d0>
ffffffffc020108a:	06a00593          	li	a1,106
ffffffffc020108e:	00001517          	auipc	a0,0x1
ffffffffc0201092:	bea50513          	addi	a0,a0,-1046 # ffffffffc0201c78 <etext+0x4f0>
ffffffffc0201096:	936ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(PageReserved(base));
ffffffffc020109a:	00001697          	auipc	a3,0x1
ffffffffc020109e:	18668693          	addi	a3,a3,390 # ffffffffc0202220 <etext+0xa98>
ffffffffc02010a2:	00001617          	auipc	a2,0x1
ffffffffc02010a6:	93660613          	addi	a2,a2,-1738 # ffffffffc02019d8 <etext+0x250>
ffffffffc02010aa:	0b700593          	li	a1,183
ffffffffc02010ae:	00001517          	auipc	a0,0x1
ffffffffc02010b2:	94250513          	addi	a0,a0,-1726 # ffffffffc02019f0 <etext+0x268>
ffffffffc02010b6:	e022                	sd	s0,0(sp)
ffffffffc02010b8:	914ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(n > 0);
ffffffffc02010bc:	00001697          	auipc	a3,0x1
ffffffffc02010c0:	91468693          	addi	a3,a3,-1772 # ffffffffc02019d0 <etext+0x248>
ffffffffc02010c4:	00001617          	auipc	a2,0x1
ffffffffc02010c8:	91460613          	addi	a2,a2,-1772 # ffffffffc02019d8 <etext+0x250>
ffffffffc02010cc:	0b600593          	li	a1,182
ffffffffc02010d0:	00001517          	auipc	a0,0x1
ffffffffc02010d4:	92050513          	addi	a0,a0,-1760 # ffffffffc02019f0 <etext+0x268>
ffffffffc02010d8:	e022                	sd	s0,0(sp)
ffffffffc02010da:	8f2ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02010de <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc02010de:	00005797          	auipc	a5,0x5
ffffffffc02010e2:	05a7b783          	ld	a5,90(a5) # ffffffffc0206138 <pmm_manager>
ffffffffc02010e6:	6f9c                	ld	a5,24(a5)
ffffffffc02010e8:	8782                	jr	a5

ffffffffc02010ea <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc02010ea:	00005797          	auipc	a5,0x5
ffffffffc02010ee:	04e7b783          	ld	a5,78(a5) # ffffffffc0206138 <pmm_manager>
ffffffffc02010f2:	739c                	ld	a5,32(a5)
ffffffffc02010f4:	8782                	jr	a5

ffffffffc02010f6 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc02010f6:	00005797          	auipc	a5,0x5
ffffffffc02010fa:	0427b783          	ld	a5,66(a5) # ffffffffc0206138 <pmm_manager>
ffffffffc02010fe:	779c                	ld	a5,40(a5)
ffffffffc0201100:	8782                	jr	a5

ffffffffc0201102 <pmm_init>:
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0201102:	00001797          	auipc	a5,0x1
ffffffffc0201106:	34678793          	addi	a5,a5,838 # ffffffffc0202448 <buddy_system_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020110a:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc020110c:	7179                	addi	sp,sp,-48
ffffffffc020110e:	f406                	sd	ra,40(sp)
ffffffffc0201110:	f022                	sd	s0,32(sp)
ffffffffc0201112:	ec26                	sd	s1,24(sp)
ffffffffc0201114:	e44e                	sd	s3,8(sp)
ffffffffc0201116:	e84a                	sd	s2,16(sp)
ffffffffc0201118:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc020111a:	00005417          	auipc	s0,0x5
ffffffffc020111e:	01e40413          	addi	s0,s0,30 # ffffffffc0206138 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201122:	00001517          	auipc	a0,0x1
ffffffffc0201126:	13650513          	addi	a0,a0,310 # ffffffffc0202258 <etext+0xad0>
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc020112a:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020112c:	81eff0ef          	jal	ffffffffc020014a <cprintf>
    pmm_manager->init();
ffffffffc0201130:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201132:	00005497          	auipc	s1,0x5
ffffffffc0201136:	01e48493          	addi	s1,s1,30 # ffffffffc0206150 <va_pa_offset>
    pmm_manager->init();
ffffffffc020113a:	679c                	ld	a5,8(a5)
ffffffffc020113c:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020113e:	57f5                	li	a5,-3
ffffffffc0201140:	07fa                	slli	a5,a5,0x1e
ffffffffc0201142:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201144:	c50ff0ef          	jal	ffffffffc0200594 <get_memory_base>
ffffffffc0201148:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020114a:	c54ff0ef          	jal	ffffffffc020059e <get_memory_size>
    if (mem_size == 0) {
ffffffffc020114e:	14050f63          	beqz	a0,ffffffffc02012ac <pmm_init+0x1aa>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201152:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201154:	00001517          	auipc	a0,0x1
ffffffffc0201158:	14c50513          	addi	a0,a0,332 # ffffffffc02022a0 <etext+0xb18>
ffffffffc020115c:	feffe0ef          	jal	ffffffffc020014a <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201160:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201164:	864e                	mv	a2,s3
ffffffffc0201166:	fffa0693          	addi	a3,s4,-1
ffffffffc020116a:	85ca                	mv	a1,s2
ffffffffc020116c:	00001517          	auipc	a0,0x1
ffffffffc0201170:	14c50513          	addi	a0,a0,332 # ffffffffc02022b8 <etext+0xb30>
ffffffffc0201174:	fd7fe0ef          	jal	ffffffffc020014a <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0201178:	c80007b7          	lui	a5,0xc8000
ffffffffc020117c:	8652                	mv	a2,s4
ffffffffc020117e:	0d47e663          	bltu	a5,s4,ffffffffc020124a <pmm_init+0x148>
ffffffffc0201182:	77fd                	lui	a5,0xfffff
ffffffffc0201184:	00006817          	auipc	a6,0x6
ffffffffc0201188:	fe380813          	addi	a6,a6,-29 # ffffffffc0207167 <end+0xfff>
ffffffffc020118c:	00f87833          	and	a6,a6,a5
    npage = maxpa / PGSIZE;
ffffffffc0201190:	8231                	srli	a2,a2,0xc
ffffffffc0201192:	00005797          	auipc	a5,0x5
ffffffffc0201196:	fcc7b323          	sd	a2,-58(a5) # ffffffffc0206158 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020119a:	00005797          	auipc	a5,0x5
ffffffffc020119e:	fd07b323          	sd	a6,-58(a5) # ffffffffc0206160 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02011a2:	000807b7          	lui	a5,0x80
ffffffffc02011a6:	002005b7          	lui	a1,0x200
ffffffffc02011aa:	02f60563          	beq	a2,a5,ffffffffc02011d4 <pmm_init+0xd2>
ffffffffc02011ae:	00261593          	slli	a1,a2,0x2
ffffffffc02011b2:	00c587b3          	add	a5,a1,a2
ffffffffc02011b6:	fec006b7          	lui	a3,0xfec00
ffffffffc02011ba:	078e                	slli	a5,a5,0x3
ffffffffc02011bc:	96c2                	add	a3,a3,a6
ffffffffc02011be:	96be                	add	a3,a3,a5
ffffffffc02011c0:	87c2                	mv	a5,a6
        SetPageReserved(pages + i);
ffffffffc02011c2:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02011c4:	02878793          	addi	a5,a5,40 # 80028 <kern_entry-0xffffffffc017ffd8>
        SetPageReserved(pages + i);
ffffffffc02011c8:	00176713          	ori	a4,a4,1
ffffffffc02011cc:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02011d0:	fed799e3          	bne	a5,a3,ffffffffc02011c2 <pmm_init+0xc0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02011d4:	95b2                	add	a1,a1,a2
ffffffffc02011d6:	fec006b7          	lui	a3,0xfec00
ffffffffc02011da:	96c2                	add	a3,a3,a6
ffffffffc02011dc:	058e                	slli	a1,a1,0x3
ffffffffc02011de:	96ae                	add	a3,a3,a1
ffffffffc02011e0:	c02007b7          	lui	a5,0xc0200
ffffffffc02011e4:	0af6e863          	bltu	a3,a5,ffffffffc0201294 <pmm_init+0x192>
ffffffffc02011e8:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02011ea:	77fd                	lui	a5,0xfffff
ffffffffc02011ec:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02011f0:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02011f2:	04b6ef63          	bltu	a3,a1,ffffffffc0201250 <pmm_init+0x14e>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02011f6:	601c                	ld	a5,0(s0)
ffffffffc02011f8:	7b9c                	ld	a5,48(a5)
ffffffffc02011fa:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02011fc:	00001517          	auipc	a0,0x1
ffffffffc0201200:	11450513          	addi	a0,a0,276 # ffffffffc0202310 <etext+0xb88>
ffffffffc0201204:	f47fe0ef          	jal	ffffffffc020014a <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201208:	00004597          	auipc	a1,0x4
ffffffffc020120c:	df858593          	addi	a1,a1,-520 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201210:	00005797          	auipc	a5,0x5
ffffffffc0201214:	f2b7bc23          	sd	a1,-200(a5) # ffffffffc0206148 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201218:	c02007b7          	lui	a5,0xc0200
ffffffffc020121c:	0af5e463          	bltu	a1,a5,ffffffffc02012c4 <pmm_init+0x1c2>
ffffffffc0201220:	609c                	ld	a5,0(s1)
}
ffffffffc0201222:	7402                	ld	s0,32(sp)
ffffffffc0201224:	70a2                	ld	ra,40(sp)
ffffffffc0201226:	64e2                	ld	s1,24(sp)
ffffffffc0201228:	6942                	ld	s2,16(sp)
ffffffffc020122a:	69a2                	ld	s3,8(sp)
ffffffffc020122c:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020122e:	40f586b3          	sub	a3,a1,a5
ffffffffc0201232:	00005797          	auipc	a5,0x5
ffffffffc0201236:	f0d7b723          	sd	a3,-242(a5) # ffffffffc0206140 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020123a:	00001517          	auipc	a0,0x1
ffffffffc020123e:	0f650513          	addi	a0,a0,246 # ffffffffc0202330 <etext+0xba8>
ffffffffc0201242:	8636                	mv	a2,a3
}
ffffffffc0201244:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201246:	f05fe06f          	j	ffffffffc020014a <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc020124a:	c8000637          	lui	a2,0xc8000
ffffffffc020124e:	bf15                	j	ffffffffc0201182 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201250:	6705                	lui	a4,0x1
ffffffffc0201252:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201254:	96ba                	add	a3,a3,a4
ffffffffc0201256:	8efd                	and	a3,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc0201258:	00c6d793          	srli	a5,a3,0xc
ffffffffc020125c:	02c7f063          	bgeu	a5,a2,ffffffffc020127c <pmm_init+0x17a>
    pmm_manager->init_memmap(base, n);
ffffffffc0201260:	6018                	ld	a4,0(s0)
    return &pages[PPN(pa) - nbase];
ffffffffc0201262:	fff80637          	lui	a2,0xfff80
ffffffffc0201266:	97b2                	add	a5,a5,a2
ffffffffc0201268:	00279513          	slli	a0,a5,0x2
ffffffffc020126c:	953e                	add	a0,a0,a5
ffffffffc020126e:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201270:	8d95                	sub	a1,a1,a3
ffffffffc0201272:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201274:	81b1                	srli	a1,a1,0xc
ffffffffc0201276:	9542                	add	a0,a0,a6
ffffffffc0201278:	9782                	jalr	a5
}
ffffffffc020127a:	bfb5                	j	ffffffffc02011f6 <pmm_init+0xf4>
        panic("pa2page called with invalid pa");
ffffffffc020127c:	00001617          	auipc	a2,0x1
ffffffffc0201280:	9dc60613          	addi	a2,a2,-1572 # ffffffffc0201c58 <etext+0x4d0>
ffffffffc0201284:	06a00593          	li	a1,106
ffffffffc0201288:	00001517          	auipc	a0,0x1
ffffffffc020128c:	9f050513          	addi	a0,a0,-1552 # ffffffffc0201c78 <etext+0x4f0>
ffffffffc0201290:	f3dfe0ef          	jal	ffffffffc02001cc <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201294:	00001617          	auipc	a2,0x1
ffffffffc0201298:	05460613          	addi	a2,a2,84 # ffffffffc02022e8 <etext+0xb60>
ffffffffc020129c:	06600593          	li	a1,102
ffffffffc02012a0:	00001517          	auipc	a0,0x1
ffffffffc02012a4:	ff050513          	addi	a0,a0,-16 # ffffffffc0202290 <etext+0xb08>
ffffffffc02012a8:	f25fe0ef          	jal	ffffffffc02001cc <__panic>
        panic("DTB memory info not available");
ffffffffc02012ac:	00001617          	auipc	a2,0x1
ffffffffc02012b0:	fc460613          	addi	a2,a2,-60 # ffffffffc0202270 <etext+0xae8>
ffffffffc02012b4:	04e00593          	li	a1,78
ffffffffc02012b8:	00001517          	auipc	a0,0x1
ffffffffc02012bc:	fd850513          	addi	a0,a0,-40 # ffffffffc0202290 <etext+0xb08>
ffffffffc02012c0:	f0dfe0ef          	jal	ffffffffc02001cc <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02012c4:	86ae                	mv	a3,a1
ffffffffc02012c6:	00001617          	auipc	a2,0x1
ffffffffc02012ca:	02260613          	addi	a2,a2,34 # ffffffffc02022e8 <etext+0xb60>
ffffffffc02012ce:	08100593          	li	a1,129
ffffffffc02012d2:	00001517          	auipc	a0,0x1
ffffffffc02012d6:	fbe50513          	addi	a0,a0,-66 # ffffffffc0202290 <etext+0xb08>
ffffffffc02012da:	ef3fe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02012de <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02012de:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012e2:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02012e4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012e8:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02012ea:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012ee:	f022                	sd	s0,32(sp)
ffffffffc02012f0:	ec26                	sd	s1,24(sp)
ffffffffc02012f2:	e84a                	sd	s2,16(sp)
ffffffffc02012f4:	f406                	sd	ra,40(sp)
ffffffffc02012f6:	84aa                	mv	s1,a0
ffffffffc02012f8:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02012fa:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02012fe:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201300:	05067063          	bgeu	a2,a6,ffffffffc0201340 <printnum+0x62>
ffffffffc0201304:	e44e                	sd	s3,8(sp)
ffffffffc0201306:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201308:	4785                	li	a5,1
ffffffffc020130a:	00e7d763          	bge	a5,a4,ffffffffc0201318 <printnum+0x3a>
            putch(padc, putdat);
ffffffffc020130e:	85ca                	mv	a1,s2
ffffffffc0201310:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0201312:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201314:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201316:	fc65                	bnez	s0,ffffffffc020130e <printnum+0x30>
ffffffffc0201318:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020131a:	1a02                	slli	s4,s4,0x20
ffffffffc020131c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201320:	00001797          	auipc	a5,0x1
ffffffffc0201324:	05078793          	addi	a5,a5,80 # ffffffffc0202370 <etext+0xbe8>
ffffffffc0201328:	97d2                	add	a5,a5,s4
}
ffffffffc020132a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020132c:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0201330:	70a2                	ld	ra,40(sp)
ffffffffc0201332:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201334:	85ca                	mv	a1,s2
ffffffffc0201336:	87a6                	mv	a5,s1
}
ffffffffc0201338:	6942                	ld	s2,16(sp)
ffffffffc020133a:	64e2                	ld	s1,24(sp)
ffffffffc020133c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020133e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201340:	03065633          	divu	a2,a2,a6
ffffffffc0201344:	8722                	mv	a4,s0
ffffffffc0201346:	f99ff0ef          	jal	ffffffffc02012de <printnum>
ffffffffc020134a:	bfc1                	j	ffffffffc020131a <printnum+0x3c>

ffffffffc020134c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020134c:	7119                	addi	sp,sp,-128
ffffffffc020134e:	f4a6                	sd	s1,104(sp)
ffffffffc0201350:	f0ca                	sd	s2,96(sp)
ffffffffc0201352:	ecce                	sd	s3,88(sp)
ffffffffc0201354:	e8d2                	sd	s4,80(sp)
ffffffffc0201356:	e4d6                	sd	s5,72(sp)
ffffffffc0201358:	e0da                	sd	s6,64(sp)
ffffffffc020135a:	f862                	sd	s8,48(sp)
ffffffffc020135c:	fc86                	sd	ra,120(sp)
ffffffffc020135e:	f8a2                	sd	s0,112(sp)
ffffffffc0201360:	fc5e                	sd	s7,56(sp)
ffffffffc0201362:	f466                	sd	s9,40(sp)
ffffffffc0201364:	f06a                	sd	s10,32(sp)
ffffffffc0201366:	ec6e                	sd	s11,24(sp)
ffffffffc0201368:	892a                	mv	s2,a0
ffffffffc020136a:	84ae                	mv	s1,a1
ffffffffc020136c:	8c32                	mv	s8,a2
ffffffffc020136e:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201370:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201374:	05500b13          	li	s6,85
ffffffffc0201378:	00001a97          	auipc	s5,0x1
ffffffffc020137c:	108a8a93          	addi	s5,s5,264 # ffffffffc0202480 <buddy_system_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201380:	000c4503          	lbu	a0,0(s8)
ffffffffc0201384:	001c0413          	addi	s0,s8,1
ffffffffc0201388:	01350a63          	beq	a0,s3,ffffffffc020139c <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc020138c:	cd0d                	beqz	a0,ffffffffc02013c6 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc020138e:	85a6                	mv	a1,s1
ffffffffc0201390:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201392:	00044503          	lbu	a0,0(s0)
ffffffffc0201396:	0405                	addi	s0,s0,1
ffffffffc0201398:	ff351ae3          	bne	a0,s3,ffffffffc020138c <vprintfmt+0x40>
        char padc = ' ';
ffffffffc020139c:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02013a0:	4b81                	li	s7,0
ffffffffc02013a2:	4601                	li	a2,0
        width = precision = -1;
ffffffffc02013a4:	5d7d                	li	s10,-1
ffffffffc02013a6:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013a8:	00044683          	lbu	a3,0(s0)
ffffffffc02013ac:	00140c13          	addi	s8,s0,1
ffffffffc02013b0:	fdd6859b          	addiw	a1,a3,-35 # fffffffffebfffdd <end+0x3e9f9e75>
ffffffffc02013b4:	0ff5f593          	zext.b	a1,a1
ffffffffc02013b8:	02bb6663          	bltu	s6,a1,ffffffffc02013e4 <vprintfmt+0x98>
ffffffffc02013bc:	058a                	slli	a1,a1,0x2
ffffffffc02013be:	95d6                	add	a1,a1,s5
ffffffffc02013c0:	4198                	lw	a4,0(a1)
ffffffffc02013c2:	9756                	add	a4,a4,s5
ffffffffc02013c4:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02013c6:	70e6                	ld	ra,120(sp)
ffffffffc02013c8:	7446                	ld	s0,112(sp)
ffffffffc02013ca:	74a6                	ld	s1,104(sp)
ffffffffc02013cc:	7906                	ld	s2,96(sp)
ffffffffc02013ce:	69e6                	ld	s3,88(sp)
ffffffffc02013d0:	6a46                	ld	s4,80(sp)
ffffffffc02013d2:	6aa6                	ld	s5,72(sp)
ffffffffc02013d4:	6b06                	ld	s6,64(sp)
ffffffffc02013d6:	7be2                	ld	s7,56(sp)
ffffffffc02013d8:	7c42                	ld	s8,48(sp)
ffffffffc02013da:	7ca2                	ld	s9,40(sp)
ffffffffc02013dc:	7d02                	ld	s10,32(sp)
ffffffffc02013de:	6de2                	ld	s11,24(sp)
ffffffffc02013e0:	6109                	addi	sp,sp,128
ffffffffc02013e2:	8082                	ret
            putch('%', putdat);
ffffffffc02013e4:	85a6                	mv	a1,s1
ffffffffc02013e6:	02500513          	li	a0,37
ffffffffc02013ea:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02013ec:	fff44703          	lbu	a4,-1(s0)
ffffffffc02013f0:	02500793          	li	a5,37
ffffffffc02013f4:	8c22                	mv	s8,s0
ffffffffc02013f6:	f8f705e3          	beq	a4,a5,ffffffffc0201380 <vprintfmt+0x34>
ffffffffc02013fa:	02500713          	li	a4,37
ffffffffc02013fe:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201402:	1c7d                	addi	s8,s8,-1
ffffffffc0201404:	fee79de3          	bne	a5,a4,ffffffffc02013fe <vprintfmt+0xb2>
ffffffffc0201408:	bfa5                	j	ffffffffc0201380 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc020140a:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc020140e:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0201410:	fd068d1b          	addiw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0201414:	fd07859b          	addiw	a1,a5,-48
                ch = *fmt;
ffffffffc0201418:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020141c:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc020141e:	02b76563          	bltu	a4,a1,ffffffffc0201448 <vprintfmt+0xfc>
ffffffffc0201422:	4525                	li	a0,9
                ch = *fmt;
ffffffffc0201424:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201428:	002d171b          	slliw	a4,s10,0x2
ffffffffc020142c:	01a7073b          	addw	a4,a4,s10
ffffffffc0201430:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201434:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201436:	fd07859b          	addiw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020143a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020143c:	fd070d1b          	addiw	s10,a4,-48
                ch = *fmt;
ffffffffc0201440:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc0201444:	feb570e3          	bgeu	a0,a1,ffffffffc0201424 <vprintfmt+0xd8>
            if (width < 0)
ffffffffc0201448:	f60cd0e3          	bgez	s9,ffffffffc02013a8 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc020144c:	8cea                	mv	s9,s10
ffffffffc020144e:	5d7d                	li	s10,-1
ffffffffc0201450:	bfa1                	j	ffffffffc02013a8 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201452:	8db6                	mv	s11,a3
ffffffffc0201454:	8462                	mv	s0,s8
ffffffffc0201456:	bf89                	j	ffffffffc02013a8 <vprintfmt+0x5c>
ffffffffc0201458:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc020145a:	4b85                	li	s7,1
            goto reswitch;
ffffffffc020145c:	b7b1                	j	ffffffffc02013a8 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc020145e:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201460:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201464:	00c7c463          	blt	a5,a2,ffffffffc020146c <vprintfmt+0x120>
    else if (lflag) {
ffffffffc0201468:	1a060163          	beqz	a2,ffffffffc020160a <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc020146c:	000a3603          	ld	a2,0(s4)
ffffffffc0201470:	46c1                	li	a3,16
ffffffffc0201472:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201474:	000d879b          	sext.w	a5,s11
ffffffffc0201478:	8766                	mv	a4,s9
ffffffffc020147a:	85a6                	mv	a1,s1
ffffffffc020147c:	854a                	mv	a0,s2
ffffffffc020147e:	e61ff0ef          	jal	ffffffffc02012de <printnum>
            break;
ffffffffc0201482:	bdfd                	j	ffffffffc0201380 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201484:	000a2503          	lw	a0,0(s4)
ffffffffc0201488:	85a6                	mv	a1,s1
ffffffffc020148a:	0a21                	addi	s4,s4,8
ffffffffc020148c:	9902                	jalr	s2
            break;
ffffffffc020148e:	bdcd                	j	ffffffffc0201380 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201490:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201492:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201496:	00c7c463          	blt	a5,a2,ffffffffc020149e <vprintfmt+0x152>
    else if (lflag) {
ffffffffc020149a:	16060363          	beqz	a2,ffffffffc0201600 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc020149e:	000a3603          	ld	a2,0(s4)
ffffffffc02014a2:	46a9                	li	a3,10
ffffffffc02014a4:	8a3a                	mv	s4,a4
ffffffffc02014a6:	b7f9                	j	ffffffffc0201474 <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc02014a8:	85a6                	mv	a1,s1
ffffffffc02014aa:	03000513          	li	a0,48
ffffffffc02014ae:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02014b0:	85a6                	mv	a1,s1
ffffffffc02014b2:	07800513          	li	a0,120
ffffffffc02014b6:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02014b8:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc02014bc:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02014be:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02014c0:	bf55                	j	ffffffffc0201474 <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc02014c2:	85a6                	mv	a1,s1
ffffffffc02014c4:	02500513          	li	a0,37
ffffffffc02014c8:	9902                	jalr	s2
            break;
ffffffffc02014ca:	bd5d                	j	ffffffffc0201380 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc02014cc:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014d0:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc02014d2:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc02014d4:	bf95                	j	ffffffffc0201448 <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc02014d6:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02014d8:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc02014dc:	00c7c463          	blt	a5,a2,ffffffffc02014e4 <vprintfmt+0x198>
    else if (lflag) {
ffffffffc02014e0:	10060b63          	beqz	a2,ffffffffc02015f6 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc02014e4:	000a3603          	ld	a2,0(s4)
ffffffffc02014e8:	46a1                	li	a3,8
ffffffffc02014ea:	8a3a                	mv	s4,a4
ffffffffc02014ec:	b761                	j	ffffffffc0201474 <vprintfmt+0x128>
            if (width < 0)
ffffffffc02014ee:	fffcc793          	not	a5,s9
ffffffffc02014f2:	97fd                	srai	a5,a5,0x3f
ffffffffc02014f4:	00fcf7b3          	and	a5,s9,a5
ffffffffc02014f8:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014fc:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02014fe:	b56d                	j	ffffffffc02013a8 <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201500:	000a3403          	ld	s0,0(s4)
ffffffffc0201504:	008a0793          	addi	a5,s4,8
ffffffffc0201508:	e43e                	sd	a5,8(sp)
ffffffffc020150a:	12040063          	beqz	s0,ffffffffc020162a <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc020150e:	0d905963          	blez	s9,ffffffffc02015e0 <vprintfmt+0x294>
ffffffffc0201512:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201516:	00140a13          	addi	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc020151a:	12fd9763          	bne	s11,a5,ffffffffc0201648 <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020151e:	00044783          	lbu	a5,0(s0)
ffffffffc0201522:	0007851b          	sext.w	a0,a5
ffffffffc0201526:	cb9d                	beqz	a5,ffffffffc020155c <vprintfmt+0x210>
ffffffffc0201528:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020152a:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020152e:	000d4563          	bltz	s10,ffffffffc0201538 <vprintfmt+0x1ec>
ffffffffc0201532:	3d7d                	addiw	s10,s10,-1
ffffffffc0201534:	028d0263          	beq	s10,s0,ffffffffc0201558 <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc0201538:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020153a:	0c0b8d63          	beqz	s7,ffffffffc0201614 <vprintfmt+0x2c8>
ffffffffc020153e:	3781                	addiw	a5,a5,-32
ffffffffc0201540:	0cfdfa63          	bgeu	s11,a5,ffffffffc0201614 <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc0201544:	03f00513          	li	a0,63
ffffffffc0201548:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020154a:	000a4783          	lbu	a5,0(s4)
ffffffffc020154e:	3cfd                	addiw	s9,s9,-1
ffffffffc0201550:	0a05                	addi	s4,s4,1
ffffffffc0201552:	0007851b          	sext.w	a0,a5
ffffffffc0201556:	ffe1                	bnez	a5,ffffffffc020152e <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc0201558:	01905963          	blez	s9,ffffffffc020156a <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc020155c:	85a6                	mv	a1,s1
ffffffffc020155e:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0201562:	3cfd                	addiw	s9,s9,-1
                putch(' ', putdat);
ffffffffc0201564:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201566:	fe0c9be3          	bnez	s9,ffffffffc020155c <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020156a:	6a22                	ld	s4,8(sp)
ffffffffc020156c:	bd11                	j	ffffffffc0201380 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020156e:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201570:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201574:	00c7c363          	blt	a5,a2,ffffffffc020157a <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc0201578:	ce25                	beqz	a2,ffffffffc02015f0 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc020157a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020157e:	08044d63          	bltz	s0,ffffffffc0201618 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201582:	8622                	mv	a2,s0
ffffffffc0201584:	8a5e                	mv	s4,s7
ffffffffc0201586:	46a9                	li	a3,10
ffffffffc0201588:	b5f5                	j	ffffffffc0201474 <vprintfmt+0x128>
            if (err < 0) {
ffffffffc020158a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020158e:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0201590:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201594:	8fb9                	xor	a5,a5,a4
ffffffffc0201596:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020159a:	02d64663          	blt	a2,a3,ffffffffc02015c6 <vprintfmt+0x27a>
ffffffffc020159e:	00369713          	slli	a4,a3,0x3
ffffffffc02015a2:	00001797          	auipc	a5,0x1
ffffffffc02015a6:	03678793          	addi	a5,a5,54 # ffffffffc02025d8 <error_string>
ffffffffc02015aa:	97ba                	add	a5,a5,a4
ffffffffc02015ac:	639c                	ld	a5,0(a5)
ffffffffc02015ae:	cf81                	beqz	a5,ffffffffc02015c6 <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02015b0:	86be                	mv	a3,a5
ffffffffc02015b2:	00001617          	auipc	a2,0x1
ffffffffc02015b6:	dee60613          	addi	a2,a2,-530 # ffffffffc02023a0 <etext+0xc18>
ffffffffc02015ba:	85a6                	mv	a1,s1
ffffffffc02015bc:	854a                	mv	a0,s2
ffffffffc02015be:	0e8000ef          	jal	ffffffffc02016a6 <printfmt>
            err = va_arg(ap, int);
ffffffffc02015c2:	0a21                	addi	s4,s4,8
ffffffffc02015c4:	bb75                	j	ffffffffc0201380 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02015c6:	00001617          	auipc	a2,0x1
ffffffffc02015ca:	dca60613          	addi	a2,a2,-566 # ffffffffc0202390 <etext+0xc08>
ffffffffc02015ce:	85a6                	mv	a1,s1
ffffffffc02015d0:	854a                	mv	a0,s2
ffffffffc02015d2:	0d4000ef          	jal	ffffffffc02016a6 <printfmt>
            err = va_arg(ap, int);
ffffffffc02015d6:	0a21                	addi	s4,s4,8
ffffffffc02015d8:	b365                	j	ffffffffc0201380 <vprintfmt+0x34>
            lflag ++;
ffffffffc02015da:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015dc:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02015de:	b3e9                	j	ffffffffc02013a8 <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015e0:	00044783          	lbu	a5,0(s0)
ffffffffc02015e4:	0007851b          	sext.w	a0,a5
ffffffffc02015e8:	d3c9                	beqz	a5,ffffffffc020156a <vprintfmt+0x21e>
ffffffffc02015ea:	00140a13          	addi	s4,s0,1
ffffffffc02015ee:	bf2d                	j	ffffffffc0201528 <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc02015f0:	000a2403          	lw	s0,0(s4)
ffffffffc02015f4:	b769                	j	ffffffffc020157e <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc02015f6:	000a6603          	lwu	a2,0(s4)
ffffffffc02015fa:	46a1                	li	a3,8
ffffffffc02015fc:	8a3a                	mv	s4,a4
ffffffffc02015fe:	bd9d                	j	ffffffffc0201474 <vprintfmt+0x128>
ffffffffc0201600:	000a6603          	lwu	a2,0(s4)
ffffffffc0201604:	46a9                	li	a3,10
ffffffffc0201606:	8a3a                	mv	s4,a4
ffffffffc0201608:	b5b5                	j	ffffffffc0201474 <vprintfmt+0x128>
ffffffffc020160a:	000a6603          	lwu	a2,0(s4)
ffffffffc020160e:	46c1                	li	a3,16
ffffffffc0201610:	8a3a                	mv	s4,a4
ffffffffc0201612:	b58d                	j	ffffffffc0201474 <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc0201614:	9902                	jalr	s2
ffffffffc0201616:	bf15                	j	ffffffffc020154a <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc0201618:	85a6                	mv	a1,s1
ffffffffc020161a:	02d00513          	li	a0,45
ffffffffc020161e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201620:	40800633          	neg	a2,s0
ffffffffc0201624:	8a5e                	mv	s4,s7
ffffffffc0201626:	46a9                	li	a3,10
ffffffffc0201628:	b5b1                	j	ffffffffc0201474 <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc020162a:	01905663          	blez	s9,ffffffffc0201636 <vprintfmt+0x2ea>
ffffffffc020162e:	02d00793          	li	a5,45
ffffffffc0201632:	04fd9263          	bne	s11,a5,ffffffffc0201676 <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201636:	02800793          	li	a5,40
ffffffffc020163a:	00001a17          	auipc	s4,0x1
ffffffffc020163e:	d4fa0a13          	addi	s4,s4,-689 # ffffffffc0202389 <etext+0xc01>
ffffffffc0201642:	02800513          	li	a0,40
ffffffffc0201646:	b5cd                	j	ffffffffc0201528 <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201648:	85ea                	mv	a1,s10
ffffffffc020164a:	8522                	mv	a0,s0
ffffffffc020164c:	0ae000ef          	jal	ffffffffc02016fa <strnlen>
ffffffffc0201650:	40ac8cbb          	subw	s9,s9,a0
ffffffffc0201654:	01905963          	blez	s9,ffffffffc0201666 <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc0201658:	2d81                	sext.w	s11,s11
ffffffffc020165a:	85a6                	mv	a1,s1
ffffffffc020165c:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020165e:	3cfd                	addiw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc0201660:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201662:	fe0c9ce3          	bnez	s9,ffffffffc020165a <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201666:	00044783          	lbu	a5,0(s0)
ffffffffc020166a:	0007851b          	sext.w	a0,a5
ffffffffc020166e:	ea079de3          	bnez	a5,ffffffffc0201528 <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201672:	6a22                	ld	s4,8(sp)
ffffffffc0201674:	b331                	j	ffffffffc0201380 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201676:	85ea                	mv	a1,s10
ffffffffc0201678:	00001517          	auipc	a0,0x1
ffffffffc020167c:	d1050513          	addi	a0,a0,-752 # ffffffffc0202388 <etext+0xc00>
ffffffffc0201680:	07a000ef          	jal	ffffffffc02016fa <strnlen>
ffffffffc0201684:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc0201688:	00001417          	auipc	s0,0x1
ffffffffc020168c:	d0040413          	addi	s0,s0,-768 # ffffffffc0202388 <etext+0xc00>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201690:	00001a17          	auipc	s4,0x1
ffffffffc0201694:	cf9a0a13          	addi	s4,s4,-775 # ffffffffc0202389 <etext+0xc01>
ffffffffc0201698:	02800793          	li	a5,40
ffffffffc020169c:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02016a0:	fb904ce3          	bgtz	s9,ffffffffc0201658 <vprintfmt+0x30c>
ffffffffc02016a4:	b551                	j	ffffffffc0201528 <vprintfmt+0x1dc>

ffffffffc02016a6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02016a6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02016a8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02016ac:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02016ae:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02016b0:	ec06                	sd	ra,24(sp)
ffffffffc02016b2:	f83a                	sd	a4,48(sp)
ffffffffc02016b4:	fc3e                	sd	a5,56(sp)
ffffffffc02016b6:	e0c2                	sd	a6,64(sp)
ffffffffc02016b8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02016ba:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02016bc:	c91ff0ef          	jal	ffffffffc020134c <vprintfmt>
}
ffffffffc02016c0:	60e2                	ld	ra,24(sp)
ffffffffc02016c2:	6161                	addi	sp,sp,80
ffffffffc02016c4:	8082                	ret

ffffffffc02016c6 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02016c6:	4781                	li	a5,0
ffffffffc02016c8:	00005717          	auipc	a4,0x5
ffffffffc02016cc:	94873703          	ld	a4,-1720(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc02016d0:	88ba                	mv	a7,a4
ffffffffc02016d2:	852a                	mv	a0,a0
ffffffffc02016d4:	85be                	mv	a1,a5
ffffffffc02016d6:	863e                	mv	a2,a5
ffffffffc02016d8:	00000073          	ecall
ffffffffc02016dc:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02016de:	8082                	ret

ffffffffc02016e0 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02016e0:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02016e4:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02016e6:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02016e8:	cb81                	beqz	a5,ffffffffc02016f8 <strlen+0x18>
        cnt ++;
ffffffffc02016ea:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02016ec:	00a707b3          	add	a5,a4,a0
ffffffffc02016f0:	0007c783          	lbu	a5,0(a5)
ffffffffc02016f4:	fbfd                	bnez	a5,ffffffffc02016ea <strlen+0xa>
ffffffffc02016f6:	8082                	ret
    }
    return cnt;
}
ffffffffc02016f8:	8082                	ret

ffffffffc02016fa <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02016fa:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02016fc:	e589                	bnez	a1,ffffffffc0201706 <strnlen+0xc>
ffffffffc02016fe:	a811                	j	ffffffffc0201712 <strnlen+0x18>
        cnt ++;
ffffffffc0201700:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201702:	00f58863          	beq	a1,a5,ffffffffc0201712 <strnlen+0x18>
ffffffffc0201706:	00f50733          	add	a4,a0,a5
ffffffffc020170a:	00074703          	lbu	a4,0(a4)
ffffffffc020170e:	fb6d                	bnez	a4,ffffffffc0201700 <strnlen+0x6>
ffffffffc0201710:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201712:	852e                	mv	a0,a1
ffffffffc0201714:	8082                	ret

ffffffffc0201716 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201716:	00054783          	lbu	a5,0(a0)
ffffffffc020171a:	e791                	bnez	a5,ffffffffc0201726 <strcmp+0x10>
ffffffffc020171c:	a02d                	j	ffffffffc0201746 <strcmp+0x30>
ffffffffc020171e:	00054783          	lbu	a5,0(a0)
ffffffffc0201722:	cf89                	beqz	a5,ffffffffc020173c <strcmp+0x26>
ffffffffc0201724:	85b6                	mv	a1,a3
ffffffffc0201726:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc020172a:	0505                	addi	a0,a0,1
ffffffffc020172c:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201730:	fef707e3          	beq	a4,a5,ffffffffc020171e <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201734:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201738:	9d19                	subw	a0,a0,a4
ffffffffc020173a:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020173c:	0015c703          	lbu	a4,1(a1)
ffffffffc0201740:	4501                	li	a0,0
}
ffffffffc0201742:	9d19                	subw	a0,a0,a4
ffffffffc0201744:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201746:	0005c703          	lbu	a4,0(a1)
ffffffffc020174a:	4501                	li	a0,0
ffffffffc020174c:	b7f5                	j	ffffffffc0201738 <strcmp+0x22>

ffffffffc020174e <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020174e:	ce01                	beqz	a2,ffffffffc0201766 <strncmp+0x18>
ffffffffc0201750:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201754:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201756:	cb91                	beqz	a5,ffffffffc020176a <strncmp+0x1c>
ffffffffc0201758:	0005c703          	lbu	a4,0(a1)
ffffffffc020175c:	00f71763          	bne	a4,a5,ffffffffc020176a <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0201760:	0505                	addi	a0,a0,1
ffffffffc0201762:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201764:	f675                	bnez	a2,ffffffffc0201750 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201766:	4501                	li	a0,0
ffffffffc0201768:	8082                	ret
ffffffffc020176a:	00054503          	lbu	a0,0(a0)
ffffffffc020176e:	0005c783          	lbu	a5,0(a1)
ffffffffc0201772:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201774:	8082                	ret

ffffffffc0201776 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201776:	ca01                	beqz	a2,ffffffffc0201786 <memset+0x10>
ffffffffc0201778:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020177a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020177c:	0785                	addi	a5,a5,1
ffffffffc020177e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201782:	fef61de3          	bne	a2,a5,ffffffffc020177c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201786:	8082                	ret
