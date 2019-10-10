# Modifier

## 对比 
-------------------

### copy, strong, assign, weak

* weak, assign
   weak是ARC中用于修饰引用类型变量，被weak修饰的变量，其指向的对象引用计数不会加1。当其指向的对象被释放后，变量会置为nil。
   assign用于修饰值类型。
   使用assign修饰引用类型，当其指向的对象被释放后，变量不会置为nil，会出现野指针风险。
* [copy, strong](/TestCopyStrong)
   被copy修饰的变量，指向可变地址时，进行深拷贝，指向不可变地址时，进行浅拷贝。
   对于不可变变量(NSString, NSArray...)，使用copy修饰可以确保其值不会因为指向对象的值发生改变(追加)而改变。
   对于可变变量(NSMutableString, NSMutableArray...), 使用copy修饰会导致其不可变(不能追加,但可以重新赋值)。
* strong, weak
   被weak修饰的变量会被添加到weak表中，其所指对象引用计数不会增加。对象被释放后，变量会被置为nil。
   被strong修饰的变量会使其指向的对象引用计数加1。
* 关于深copy和浅copy
   深copy是指内容copy，即申请一块新内存，将源对象的内容拷贝到新申请的内存中。被拷贝对象的值发生改变不会影响到拷贝对象。拷贝对象的地址和其指针地址都发生改变。
   浅copy是指指针copy，即申请一块内存，将源对象的指针指向新内存。被拷贝对象的值发生改变后，被拷贝对象的值也会发生改变。拷贝对象的地址不变，指针地址发生改变。

-----------

## 底层
### SideTables
* 关系图 ![pic](/SideTables.png)
* SideTables
```
static StripedMap<SideTable>& SideTables() {
    return *reinterpret_cast<StripedMap<SideTable>*>(SideTableBuf);
}
```
   是一个64个元素长度的hash数组，里面存储了SideTable。SideTables的hash键值就是一个对象的address
* 一个obj对应一个SideTable， 一个SideTable可能对应多个obj。
* SideTable
```
struct SideTable {
    RefcountMap refcnts;//引用计数
    weak_table_t weak_table;//弱引用表
    ...
};
```
* RefcountMap
```
//key, value, value == 0时是否释放相应的节点
//key是obj的地址，value是对象的引用计数
typedef objc::DenseMap<DisguisedPtr<objc_object>,size_t,true> RefcountMap;
```
* weak_table_t
```
struct weak_table_t {
    weak_entry_t *weak_entries; //hash数组, 存储弱引用对象的相关信息
    size_t    num_entries; //hash数组中的个数
    uintptr_t mask; // hash数组长度-1，会参与hash计算。（注意，这里是hash数组的长度，而不是元素个数。比如，数组长度可能是64，而元素个数仅存了2个）
    uintptr_t max_hash_displacement; // 可能会发生的hash冲突的最大次数，用于判断是否出现了逻辑错误（hash表中的冲突次数绝不会超过改值）
};

```
* weak_entry_t
```
struct weak_entry_t {
    DisguisedPtr<objc_object> referent; //obj 对象
    union {
        struct {
            weak_referrer_t *referrers; //对象的弱引用数组
            ...
        };
        ...
    };
    ...
};
```

### storeStrong
### storeweak


