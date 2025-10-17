#ifndef __KERN_MM_SLUB_PMM_H__
#define __KERN_MM_SLUB_PMM_H__

#include <pmm.h>
#include <buddy_system_pmm.h>

extern const struct pmm_manager slub_pmm_manager;

// SLUB 分配器配置
#define SLUB_MIN_SIZE      32      // 最小对象大小
#define SLUB_MAX_SIZE      4096    // 最大对象大小  
#define SLUB_MIN_ORDER     0       // 最小阶数（1页）
#define SLUB_MAX_ORDER     4       // 最大阶数（16页）

// SLUB 缓存状态
enum slub_state {
    SLUB_FULL = 0,
    SLUB_PARTIAL,
    SLUB_EMPTY
};

// SLUB 页面结构
struct slub_page {
    void *freelist;           // 空闲对象链表
    struct slub_page *next;   // 下一个slub页面
    int inuse;               // 已使用对象数量
    int objects;             // 总对象数量
    int frozen;              // 是否被冻结
};

// SLUB 缓存结构
struct slub_cache {
    char name[32];           // 缓存名称
    size_t object_size;      // 对象大小
    size_t size;             // 实际分配大小（包含元数据）
    int order;               // 从伙伴系统申请的页框阶数
    int objects_per_page;    // 每页对象数量
    unsigned long flags;     // 标志位
    
    // 页面链表
    struct slub_page *full;
    struct slub_page *partial;
    struct slub_page *empty;
    
    // 统计信息
    unsigned long total_allocated;
    unsigned long total_freed;
    unsigned long active_objects;
};

#endif /* ! __KERN_MM_SLUB_PMM_H__ */