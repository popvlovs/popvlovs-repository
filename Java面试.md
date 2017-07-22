# Java面试题整理

标签: Java基础

---

[TOC]

---

## 1. hashCode和equals的区别与联系
> - `Object.equals()`：判断两个Object是否相等，在Object类中，其默认实现是比较Object之间是否为相同引用。

> - `Object.hashcode()`：获取对象的散列值，主要用于`HashMap`和`HashSet`等集合中。

---

> 1. equals的两个对象，其hashcode值一定相同
2. hashcode相同的两个对象，不一定equals

## 2. hashmap的底层实现
>###hashmap的定义    
HashMap是基于哈希表的Map接口的[非同步实现](#sync)。此实现提供所有可选的映射操作，并允许使用null值和null键。[此类不保证映射的顺序](#treemap)，特别是它不保证该顺序恒久不变。

> - <span id = "treemap"></span>`Map接口的另一个实现TreeMap是保序的`
> - <span id = "sync"></span>`据说可以通过Collection中的方法，变为线程安全的`

---

>###hashmap的数据结构
HashMap实际上是一个“链表散列”的数据结构，即数组和链表的结合体。
![hashmap的底层实现][hashmap.jpg]

---

###hashmap数据结构的代码表示
`table` 为链表数组
`Entry` 为链表节点，包括`Key-Value`和对下一个`Entry`的引用
```java
/** 
 * The table, resized as necessary. Length MUST Always be a power of two. 
 */  
transient Entry[] table;  
  
static class Entry<K,V> implements Map.Entry<K,V> {  
    final K key;  
    V value;  
    Entry<K,V> next;  
    final int hash;  
    ……  
}  
```
###hashmap存储，put
1. 计算`key`的`hashcode`值
2. 通过[hash](#hash) ,获取`hashcode`值在`table`中的索引
3. 索引处的`entry`不为空时（hash冲突），遍历`entry`链
4. 若`key.equals( entry.key )`则覆盖原`entry`否则执行 [addEntry](#addEntry)
5. 索引处的`entry`为空时，执行 [addEntry](#addEntry)
```
public V put(K key, V value) {  
    // HashMap允许存放null键和null值。  
    // 当key为null时，调用putForNullKey方法，将value放置在数组第一个位置。  
    if (key == null)  
        return putForNullKey(value);  
        
    // 根据key的keyCode重新计算hash值。  
    int hash = hash(key.hashCode());  
    // 搜索指定hash值在对应table中的索引。  
    int i = indexFor(hash, table.length);  
    // 如果 i 索引处的 Entry 不为 null，通过循环不断遍历 e 元素的下一个元素。  
    for (Entry<K,V> e = table[i]; e != null; e = e.next) {  
        Object k;  
        if (e.hash == hash && ((k = e.key) == key || key.equals(k))) {  
            V oldValue = e.value;  
            e.value = value;  
            e.recordAccess(this);  
            return oldValue;  
        }  
    }  
    // 如果i索引处的Entry为null，表明此处还没有Entry。  
    modCount++;  
    // 将key、value添加到i索引处。  
    addEntry(hash, key, value, i);  
    return null;  
}  
```
- **hashmap.addEntry**<span id='addEntry'></span>
1. `Entry`的挂接采用`insert`到头部的方法，即在`table[index]`处新建`Entry`，并指向原`Entry`
2. `table`长度一旦不够用，就会自动扩充到原来的两倍，并重新进行`hash`
```
void addEntry(int hash, K key, V value, int bucketIndex) {  
    // 获取指定 bucketIndex 索引处的 Entry   
    Entry<K,V> e = table[bucketIndex];  
    // 将新创建的 Entry 放入 bucketIndex 索引处，并让新的 Entry 指向原来的 Entry  
    table[bucketIndex] = new Entry<K,V>(hash, key, value, e);  
    // 如果 Map 中的 key-value 对的数量超过了极限  
    if (size++ >= threshold)  
    // 把 table 对象的长度扩充到原来的2倍。  
        resize(2 * table.length);  
}  
```
- **hashmap.hash**
```
static int hash(int h) {  
    h ^= (h >>> 20) ^ (h >>> 12);  
    return h ^ (h >>> 7) ^ (h >>> 4);  
}  
```
- **hashmap.indexFor**
当`length = pow( 2, n )`时，该操作等价于取模运算，但比`%`操作效率更高

    这也是为什么要求`hashmap.length`必须是2的指数幂

```
static int indexFor(int h, int length) {  
    return h & (length-1);  
}  
```
### hashmap读取，get
基本和put的逻辑一样
```
public V get(Object key) {  
    if (key == null)  
        return getForNullKey();  
    int hash = hash(key.hashCode());  
    for (Entry<K,V> e = table[indexFor(hash, table.length)];  
        e != null;  
        e = e.next) {  
        Object k;  
        if (e.hash == hash && ((k = e.key) == key || key.equals(k)))  
            return e.value;  
    }  
    return null;  
}  
```
### hashmap扩容，resize
当`HashMap`中的元素个数超过`length * loadFactor`时，就会执行扩容，默认情况下

    loadFactor = 0.75
    length = 16
[hashmap.jpg]: https://raw.githubusercontent.com/popvlovs/popvlovs-repository/master/hashmap.jpg
