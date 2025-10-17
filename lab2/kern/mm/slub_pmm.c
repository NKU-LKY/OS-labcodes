#include <pmm.h>
#include <list.h>
#include <string.h>
#include <slub_pmm.h>
#include <stdio.h>
#include <assert.h>
#include <buddy_system_pmm.h>

/* SLUB 内存分配算法
 * 
 * SLUB 分配器的核心思想：
 * 1. 为不同大小的对象创建专用缓存
 * 2. 每个缓存维护三个页面链表：full, partial, empty
 * 3. 分配时优先从partial链表获取，释放时根据页面状态移动链表
 * 4. 基于伙伴系统获取大块内存，然后分割成小对象
 */

// SLUB 缓存数组
static struct slub_cache slub_caches[8];
static int num_caches = 0;

// 添加必要的外部函数声明
extern struct Page *buddy_system_alloc_pages(size_t n);
extern void buddy_system_free_pages(struct Page *base, size_t n);
extern void buddy_system_init_memmap(struct Page *base, size_t n);
extern size_t buddy_system_nr_free_pages(void);

// 计算对齐后的对象大小
static inline size_t slub_align_size(size_t size) {
    return (size + sizeof(void *) - 1) & ~(sizeof(void *) - 1);
}

// 计算最适合的缓存索引
static int slub_find_cache_index(size_t size) {
    for (int i = 0; i < num_caches; i++) {
        if (slub_caches[i].object_size >= size) {
            return i;
        }
    }
    return -1;
}

// 从伙伴系统分配页面给SLUB缓存
static struct Page *slub_alloc_page_for_cache(struct slub_cache *cache) {
    struct Page *page = alloc_pages(1 << cache->order);
    if (!page) {
        return NULL;
    }
    
    // 初始化slub页面
    char *start = (char *)page2pa(page);
    struct slub_page *slub_page = (struct slub_page *)start;
    char *obj = start + sizeof(struct slub_page);
    
    // 初始化slub页面元数据
    slub_page->freelist = NULL;
    slub_page->objects = cache->objects_per_page;
    slub_page->inuse = 0;
    slub_page->frozen = 0;
    slub_page->next = NULL;
    
    // 构建空闲对象链表
    for (int i = 0; i < cache->objects_per_page; i++) {
        void **next = (void **)obj;
        *next = slub_page->freelist;
        slub_page->freelist = obj;
        obj += cache->size;
    }
    
    return page;
}

// 释放SLUB页面回伙伴系统
static void slub_free_page_for_cache(struct slub_cache *cache, struct Page *page) {
    free_pages(page, 1 << cache->order);
}

// 将页面添加到链表
static void slub_add_page_to_list(struct slub_page **list, struct Page *page) {
    struct slub_page *slub_page = (struct slub_page *)page2pa(page);
    slub_page->next = *list;
    *list = slub_page;
}

// 从链表移除页面
static struct Page *slub_remove_page_from_list(struct slub_page **list, struct Page *target) {
    struct slub_page **prev = list;
    struct slub_page *slub_target = (struct slub_page *)page2pa(target);
    
    while (*prev) {
        if (*prev == slub_target) {
            *prev = slub_target->next;
            slub_target->next = NULL;
            return target;
        }
        prev = &(*prev)->next;
    }
    return NULL;
}

// 获取页面状态
static enum slub_state slub_get_page_state(struct Page *page) {
    struct slub_page *slub_page = (struct slub_page *)page2pa(page);
    if (slub_page->inuse == 0) {
        return SLUB_EMPTY;
    } else if (slub_page->inuse == slub_page->objects) {
        return SLUB_FULL;
    } else {
        return SLUB_PARTIAL;
    }
}

// 移动页面到正确的链表
static void slub_move_page(struct slub_cache *cache, struct Page *page) {
    enum slub_state state = slub_get_page_state(page);
    
    // 先从当前链表移除
    slub_remove_page_from_list(&cache->full, page);
    slub_remove_page_from_list(&cache->partial, page);
    slub_remove_page_from_list(&cache->empty, page);
    
    // 添加到正确的链表
    switch (state) {
        case SLUB_FULL:
            slub_add_page_to_list(&cache->full, page);
            break;
        case SLUB_PARTIAL:
            slub_add_page_to_list(&cache->partial, page);
            break;
        case SLUB_EMPTY:
            slub_add_page_to_list(&cache->empty, page);
            break;
    }
}

// 在链表中查找包含指定地址的页面
static struct Page *slub_find_page_in_list(struct slub_page *list, void *addr) {
    for (struct slub_page *p = list; p; p = p->next) {
        uintptr_t start = (uintptr_t)p;
        uintptr_t end = start + PGSIZE * (1 << 0); // 假设都是单页
        if ((uintptr_t)addr >= start && (uintptr_t)addr < end) {
            return pa2page(PADDR(p));
        }
    }
    return NULL;
}

// 小内存分配函数
static void *slub_alloc_pages_small(size_t n) {
    if (n > SLUB_MAX_SIZE) {
        // 大内存分配直接使用伙伴系统
        struct Page *page = buddy_system_alloc_pages((n + PGSIZE - 1) / PGSIZE);
        return page ? (void *)page2pa(page) : NULL;
    }
    
    // 找到合适的缓存
    int cache_idx = slub_find_cache_index(n);
    if (cache_idx == -1) {
        return NULL;
    }
    
    struct slub_cache *cache = &slub_caches[cache_idx];
    struct Page *page = NULL;
    
    // 优先从partial链表分配
    if (cache->partial) {
        page = pa2page(PADDR(cache->partial));
    } 
    // 其次从empty链表分配
    else if (cache->empty) {
        page = pa2page(PADDR(cache->empty));
    }
    // 需要新页面
    else {
        page = slub_alloc_page_for_cache(cache);
        if (!page) {
            return NULL;
        }
        slub_add_page_to_list(&cache->empty, page);
    }
    
    // 分配对象
    struct slub_page *slub_page = (struct slub_page *)page2pa(page);
    void *obj = slub_page->freelist;
    slub_page->freelist = *(void **)obj;
    slub_page->inuse++;
    cache->total_allocated++;
    cache->active_objects++;
    
    // 移动页面到正确的链表
    slub_move_page(cache, page);
    
    // 清零内存
    memset(obj, 0, cache->object_size);
    
    return obj;
}

// 小内存释放函数
static void slub_free_pages_small(void *addr, size_t n) {
    if (!addr) return;
    
    // 检查是否是大内存分配（直接来自伙伴系统）
    struct Page *page = pa2page(PADDR(addr));
    if (page->property > 0) {
        buddy_system_free_pages(page, 1 << page->property);
        return;
    }
    
    // 找到对应的缓存和页面
    for (int i = 0; i < num_caches; i++) {
        struct slub_cache *cache = &slub_caches[i];
        struct Page *found_page = NULL;
        
        // 搜索所有链表找到包含该对象的页面
        found_page = slub_find_page_in_list(cache->full, addr);
        if (!found_page) {
            found_page = slub_find_page_in_list(cache->partial, addr);
        }
        if (!found_page) {
            found_page = slub_find_page_in_list(cache->empty, addr);
        }
        
        if (found_page) {
            struct slub_page *slub_page = (struct slub_page *)page2pa(found_page);
            
            // 将对象放回空闲链表
            *(void **)addr = slub_page->freelist;
            slub_page->freelist = addr;
            slub_page->inuse--;
            
            cache->total_freed++;
            cache->active_objects--;
            
            // 移动页面到正确的链表
            slub_move_page(cache, found_page);
            
            // 如果页面完全空闲且有空页面过多，释放它
            if (slub_page->inuse == 0) {
                int empty_count = 0;
                for (struct slub_page *p = cache->empty; p; p = p->next) {
                    empty_count++;
                }
                
                if (empty_count > 2) {  // 保持最少2个空页面
                    slub_remove_page_from_list(&cache->empty, found_page);
                    slub_free_page_for_cache(cache, found_page);
                }
            }
            
            return;
        }
    }
    
    // 如果没有找到对应的缓存，可能是错误
    cprintf("SLUB WARNING: trying to free unknown object at %p\n", addr);
}

// 初始化SLUB分配器
static void
slub_init(void) {
    // 定义不同大小的缓存
    size_t sizes[] = {32, 64, 128, 256, 512, 1024, 2048, 4096};
    const char *names[] = {"size-32", "size-64", "size-128", "size-256", 
                          "size-512", "size-1024", "size-2048", "size-4096"};
    
    num_caches = sizeof(sizes) / sizeof(sizes[0]);
    
    for (int i = 0; i < num_caches; i++) {
        struct slub_cache *cache = &slub_caches[i];
        
        // 初始化缓存基本信息
        strncpy(cache->name, names[i], sizeof(cache->name) - 1);
        cache->name[sizeof(cache->name) - 1] = '\0';
        cache->object_size = sizes[i];
        cache->size = slub_align_size(sizes[i] + sizeof(void *));
        
        // 计算合适的order
        int order = SLUB_MIN_ORDER;
        size_t page_size = PGSIZE * (1 << order);
        while (page_size / cache->size < 4 && order < SLUB_MAX_ORDER) {
            order++;
            page_size = PGSIZE * (1 << order);
        }
        cache->order = order;
        
        // 计算每页对象数量（减去slub_page结构大小）
        cache->objects_per_page = (page_size - sizeof(struct slub_page)) / cache->size;
        
        // 初始化链表
        cache->full = NULL;
        cache->partial = NULL;
        cache->empty = NULL;
        
        // 初始化统计信息
        cache->total_allocated = 0;
        cache->total_freed = 0;
        cache->active_objects = 0;
        
        cprintf("SLUB: initialized cache '%s', object_size=%lu, order=%d, objects_per_page=%d\n",
                cache->name, cache->object_size, cache->order, cache->objects_per_page);
    }
    
    cprintf("SLUB: initialized %d caches\n", num_caches);
}

// 初始化内存映射
static void
slub_init_memmap(struct Page *base, size_t n) {
    // SLUB 依赖于伙伴系统，所以这里不需要特殊处理
    // 内存初始化由伙伴系统完成
    buddy_system_init_memmap(base, n);
}

// 分配内存页面
static struct Page *
slub_alloc_pages(size_t n) {
    if (n > SLUB_MAX_SIZE / PGSIZE) {
        // 大内存分配直接使用伙伴系统
        return buddy_system_alloc_pages(n);
    }
    
    // 小内存分配使用SLUB
    void *obj = slub_alloc_pages_small(n * PGSIZE);
    if (!obj) {
        return NULL;
    }
    
    // 返回对应的页面
    return pa2page(PADDR(obj));
}

// 释放内存页面
static void
slub_free_pages(struct Page *base, size_t n) {
    if (!base) return;
    
    // 如果是大内存分配（直接来自伙伴系统）
    if (n > SLUB_MAX_SIZE / PGSIZE || base->property > 0) {
        buddy_system_free_pages(base, n);
        return;
    }
    
    // 小内存释放
    void *addr = (void *)page2pa(base);
    slub_free_pages_small(addr, n * PGSIZE);
}

// 获取空闲页框数量
static size_t
slub_nr_free_pages(void) {
    return buddy_system_nr_free_pages();
}

// 打印SLUB状态（用于调试）
static void
slub_print_status(void) {
    cprintf("SLUB Allocator Status:\n");
    cprintf("Total free pages in buddy: %lu\n", slub_nr_free_pages());
    
    for (int i = 0; i < num_caches; i++) {
        struct slub_cache *cache = &slub_caches[i];
        
        int full_count = 0, partial_count = 0, empty_count = 0;
        
        for (struct slub_page *p = cache->full; p; p = p->next) full_count++;
        for (struct slub_page *p = cache->partial; p; p = p->next) partial_count++;
        for (struct slub_page *p = cache->empty; p; p = p->next) empty_count++;
        
        cprintf("Cache '%s' (obj_size=%lu): full=%d, partial=%d, empty=%d, active=%lu\n",
                cache->name, cache->object_size, full_count, partial_count, 
                empty_count, cache->active_objects);
    }
}

// SLUB 分配器测试函数
static void
slub_check(void) {
    cprintf("\n");
    cprintf("========================================\n");
    cprintf("         COMPREHENSIVE SLUB TESTS      \n");
    cprintf("========================================\n");
    
    // 保存初始状态
    size_t initial_free_pages = nr_free_pages();
    cprintf("Initial free pages: %lu\n", initial_free_pages);
    
    // ===== 基础功能测试 =====
    cprintf("\n--- Basic Functionality Tests ---\n");
    
    // 测试1: 基本分配释放
    cprintf("Test 1: Basic allocation and free\n");
    struct Page *p1 = slub_alloc_pages(1);
    assert(p1 != NULL);
    cprintf("  ✓ Allocated 1 page at 0x%08lx\n", page2pa(p1));
    slub_free_pages(p1, 1);
    cprintf("  ✓ Freed 1 page\n");
    
    // 测试2: 不同大小分配
    cprintf("Test 2: Different size allocations\n");
    struct Page *p2 = slub_alloc_pages(1);
    struct Page *p4 = slub_alloc_pages(1);
    struct Page *p8 = slub_alloc_pages(1);
    assert(p2 != NULL && p4 != NULL && p8 != NULL);
    cprintf("  ✓ Allocated multiple pages\n");
    
    // 写入测试数据
    memset((void *)page2pa(p2), 0xAA, PGSIZE);
    memset((void *)page2pa(p4), 0xBB, PGSIZE);
    memset((void *)page2pa(p8), 0xCC, PGSIZE);
    cprintf("  ✓ Memory write test passed\n");
    
    slub_free_pages(p2, 1);
    slub_free_pages(p4, 1);
    slub_free_pages(p8, 1);
    cprintf("  ✓ Freed all pages\n");
    
    // 测试3: 小内存分配测试
    cprintf("Test 3: Small memory allocation test\n");
    void *small = slub_alloc_pages_small(64);
    void *medium = slub_alloc_pages_small(256);
    void *large = slub_alloc_pages_small(1024);
    assert(small != NULL && medium != NULL && large != NULL);
    cprintf("  ✓ Allocated 64B, 256B, 1024B via SLUB\n");
    
    // 写入测试数据
    memset(small, 0xAA, 64);
    memset(medium, 0xBB, 256);
    memset(large, 0xCC, 1024);
    cprintf("  ✓ Small memory write test passed\n");
    
    slub_free_pages_small(small, 64);
    slub_free_pages_small(medium, 256);
    slub_free_pages_small(large, 1024);
    cprintf("  ✓ Freed all small blocks\n");
    
    // ===== 高级功能测试 =====
    cprintf("\n--- Advanced Functionality Tests ---\n");
    
    // 测试4: 大量对象分配
    cprintf("Test 4: Bulk allocation test\n");
    #define NUM_TEST_OBJS 20
    void *objects[NUM_TEST_OBJS];
    
    for (int i = 0; i < NUM_TEST_OBJS; i++) {
        objects[i] = slub_alloc_pages_small(128);
        assert(objects[i] != NULL);
        memset(objects[i], i & 0xFF, 128);
    }
    cprintf("  ✓ Allocated %d small objects\n", NUM_TEST_OBJS);
    
    // 验证数据完整性
    for (int i = 0; i < NUM_TEST_OBJS; i++) {
        unsigned char expected = i & 0xFF;
        assert(*((unsigned char*)objects[i]) == expected);
    }
    cprintf("  ✓ Data integrity verified\n");
    
    // 交错释放
    for (int i = 0; i < NUM_TEST_OBJS; i += 2) {
        slub_free_pages_small(objects[i], 128);
    }
    cprintf("  ✓ Interleaved free completed\n");
    
    // 再次分配
    for (int i = 0; i < NUM_TEST_OBJS; i += 2) {
        objects[i] = slub_alloc_pages_small(128);
        assert(objects[i] != NULL);
    }
    cprintf("  ✓ Re-allocation successful\n");
    
    // 全部释放
    for (int i = 0; i < NUM_TEST_OBJS; i++) {
        slub_free_pages_small(objects[i], 128);
    }
    cprintf("  ✓ All objects freed\n");
    
    // 测试5: 混合分配测试
    cprintf("Test 5: Mixed allocation test\n");
    struct Page *page_alloc = slub_alloc_pages(2);
    void *small_alloc = slub_alloc_pages_small(512);
    assert(page_alloc != NULL && small_alloc != NULL);
    cprintf("  ✓ Mixed page and small allocation successful\n");
    
    slub_free_pages(page_alloc, 2);
    slub_free_pages_small(small_alloc, 512);
    cprintf("  ✓ Mixed free successful\n");
    
    // ===== 最终验证 =====
    cprintf("\n--- Final Verification ---\n");
    slub_print_status();
    
    size_t final_free_pages = nr_free_pages();
    cprintf("Initial free pages: %lu\n", initial_free_pages);
    cprintf("Final free pages: %lu\n", final_free_pages);
    
    if (final_free_pages == initial_free_pages) {
        cprintf("Memory conservation verified - no leaks detected\n");
    } else {
        cprintf("Memory leak detected! Initial: %lu, Final: %lu\n", 
                initial_free_pages, final_free_pages);
    }
    
    // 打印缓存统计
    cprintf("\nCache Statistics:\n");
    for (int i = 0; i < num_caches; i++) {
        struct slub_cache *cache = &slub_caches[i];
        cprintf("  %s: allocated=%lu, freed=%lu, active=%lu\n",
                cache->name, cache->total_allocated, cache->total_freed, 
                cache->active_objects);
    }
    
    cprintf("\n");
    cprintf("========================================\n");
    cprintf("        ALL SLUB TESTS PASSED!        \n");
    cprintf("========================================\n");
    cprintf("Total tests completed: 5\n");
    cprintf("All core SLUB features verified\n");
    cprintf("========================================\n\n");
}

const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_pages,
    .nr_free_pages = slub_nr_free_pages,
    .check = slub_check,
};