# Modifier


## copy, strong, assign, weak

* weak, assign
   weak是ARC中用于修饰引用类型变量，被weak修饰的变量，其指向的对象引用计数不会加1。当其指向的对象被释放后，变量会置为nil。
   assign用于修饰值类型。
   使用assign修饰引用类型，当其指向的对象被释放后，变量不会置为nil，会出现野指针风险。
* copy, strong
1. 被copy修饰的变量，指向可变地址时，进行深拷贝，指向不可变地址时，进行浅拷贝。
2. 对于不可变变量(NSString, NSArray...)，使用copy修饰可以确保其值不会因为指向对象的值发生改变(追加)而改变。
3. 对于可变变量(NSMutableString, NSMutableArray...), 使用copy修饰会导致其不可变(不能追加,但可以重新赋值)。
4. [test code](/TestCopyStrong.m) 
* strong, weak
   被weak修饰的变量会被添加到weak表中，其所指对象引用计数不会增加。对象被释放后，变量会被置为nil。
   被strong修饰的变量会使其指向的对象引用计数加1。
* 关于深copy和浅copy
1. 深copy是指内容copy，即申请一块新内存，将源对象的内容拷贝到新申请的内存中。被拷贝对象的值发生改变不会影响到拷贝对象。拷贝对象的地址和其指针地址都发生改变。
2. 浅copy是指指针copy，即申请一块内存，将源对象的指针指向新内存。被拷贝对象的值发生改变后，被拷贝对象的值也会发生改变。拷贝对象的地址不变，指针地址发生改变。
3. 对于可变变量(NSMutable__), copy 和 mutableCopy都是深拷贝
4. 对于不可变变量(NS__), copy 是浅拷贝，mutableCopy是深拷贝
5. 可变变量指向不可变变量时，如果使用copy或直接赋值，则可变变量地址不可变(无法追加, 强行追加会crash)
6. [test code](/TestCopy.m) 
-----------

## 底层结构
### 关系图 ![pic](/SideTables.png)
### SideTables
```
static StripedMap<SideTable>& SideTables() {
    return *reinterpret_cast<StripedMap<SideTable>*>(SideTableBuf);
}
```
是一个64个元素长度的hash数组，里面存储了SideTable。SideTables的hash键值就是一个对象的address。一个obj对应一个SideTable， 一个SideTable可能对应多个obj。
### SideTable
```
struct SideTable {
    RefcountMap refcnts;//引用计数
    weak_table_t weak_table;//弱引用表
    ...
};
```
### RefcountMap
```
//key, value, value == 0时是否释放相应的节点
//key是obj的地址，value是对象的引用计数
typedef objc::DenseMap<DisguisedPtr<objc_object>,size_t,true> RefcountMap;
```
### weak_table_t
```
struct weak_table_t {
    weak_entry_t *weak_entries; //hash数组, 存储弱引用对象的相关信息
    size_t    num_entries; //hash数组中的个数
    uintptr_t mask; // hash数组长度-1，会参与hash计算。（注意，这里是hash数组的长度，而不是元素个数。比如，数组长度可能是64，而元素个数仅存了2个）
    uintptr_t max_hash_displacement; // 可能会发生的hash冲突的最大次数，用于判断是否出现了逻辑错误（hash表中的冲突次数绝不会超过改值）
};

```
### weak_entry_t
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
## 底层函数
------
### weak

* objc_initWeak
没有老的指向
```
id
objc_initWeak(id *location, id newObj)
{
    if (!newObj) {
        *location = nil;
        return nil;
    }

    return storeWeak<DontHaveOld, DoHaveNew, DoCrashIfDeallocating>
        (location, (objc_object*)newObj);
}
```

* objc_storeWeak
有老的指向
```
/** 
 * This function stores a new value into a __weak variable. It would
 * be used anywhere a __weak variable is the target of an assignment.
 * 
 * @param location The address of the weak pointer itself
 * @param newObj The new object this weak ptr should now point to
 * 
 * @return \e newObj
 */
 // location 当前weak指针
 // newObj 新的指向
id
objc_storeWeak(id *location, id newObj)
{
    return storeWeak<DoHaveOld, DoHaveNew, DoCrashIfDeallocating>
        (location, (objc_object *)newObj);
}

```
* storeWeak
如果有老的指向，从老的weak表中删除当前weak指针，如果有新的指向，将weak指针添加到新的指向的weak表中
```
// If HaveOld is true, the variable has an existing value 
//   that needs to be cleaned up. This value might be nil.
// If HaveNew is true, there is a new value that needs to be 
//   assigned into the variable. This value might be nil.
// If CrashIfDeallocating is true, the process is halted if newObj is 
//   deallocating or newObj's class does not support weak references. 
//   If CrashIfDeallocating is false, nil is stored instead.

static id 
storeWeak(id *location, objc_object *newObj)
{
    assert(haveOld  ||  haveNew);
    if (!haveNew) assert(newObj == nil);

    Class previouslyInitializedClass = nil;
    id oldObj;
    SideTable *oldTable;
    SideTable *newTable;

   ... 

    // Clean up old value, if any.
    if (haveOld) {
        weak_unregister_no_lock(&oldTable->weak_table, oldObj, location);
    }

    // Assign new value, if any.
    if (haveNew) {
        newObj = (objc_object *)
            weak_register_no_lock(&newTable->weak_table, (id)newObj, location, 
                                  crashIfDeallocating);
        // weak_register_no_lock returns nil if weak store should be rejected

        // Set is-weakly-referenced bit in refcount table.
        if (newObj  &&  !newObj->isTaggedPointer()) {
            newObj->setWeaklyReferenced_nolock();
        }

        // Do not set *location anywhere else. That would introduce a race.
        *location = (id)newObj;
    }
    else {
        // No new value. The storage is not changed.
    }
    
    SideTable::unlockTwo<haveOld, haveNew>(oldTable, newTable);

    return (id)newObj;
}
```
------
### strong
* objc_storeStrong
如果新的引用和当前的引用的地址相等，直接返回。retain新的引用(新的引用计数-1)，释放老的引用(老的引用计数-1)

```
// location 当前引用对象地址
// 指向
void
objc_storeStrong(id *location, id obj)
{
    id prev = *location;
    if (obj == prev) {
        return;
    }
    objc_retain(obj);
    *location = obj;
    objc_release(prev);
}
```
* objc_retain
```
id 
objc_retain(id obj)
{
    if (!obj) return obj;
    if (obj->isTaggedPointer()) return obj;
    return obj->retain();
}
```
---
### copy
```
id 
object_copy(id oldObj, size_t extraBytes)
{
    return _object_copyFromZone(oldObj, extraBytes, malloc_default_zone());
}

```


