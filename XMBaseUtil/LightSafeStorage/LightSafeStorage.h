//
//  LightSafeStorage.h
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/9/10.
//  Copyright © 2019 xianminxiao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LightSafeStorage;

typedef void (^LightSafeStorageWriteBlock) (LightSafeStorage *storage, NSString* __nonnull key, id<NSCoding> object, BOOL bSuccess);
typedef void (^LightSafeStorageReadBlock)  (LightSafeStorage *storage, NSString* __nonnull key, id<NSCoding> __nonnull object, BOOL bSuccess);
typedef void (^LightSafeStorageRemoveBlock)(LightSafeStorage *storage, NSString* __nonnull key, BOOL bSuccess);
typedef void (^LightSafeStorageClearBlock) (LightSafeStorage *storage, BOOL bSuccess);

@protocol NFSuspectApplyNotifyManagerDelegate <NSObject>

@required

@optional
- (void)logInfo:(NSString*)strLog;

@end

@interface LightSafeStorage : NSObject

@property(nonatomic, weak) id<NFSuspectApplyNotifyManagerDelegate>       storageDelegate;

- (instancetype)init NS_UNAVAILABLE;

/**
 *  使用默认的文件路径  Document/LYStorage/md5(nameSpace name)
 *  其中无subNameSpace，默认为nil
 *  @param nameSpace 不同的nameSpace，缓存路径不同
 */
- (instancetype)initWithNameSpace:(Class)nameSpace;

/**
 *  参数主要影响文件路径  比如Library/LYStorage/md5(nameSpace name)/md5(subNamespace)/key
 *  @param nameSpace 不同的nameSpace，缓存路径不同，直接用class，免得namespace容易一样冲突
 *  @param subNameSpace   根据Uin创建不同的文件目录
 *  @param isInLibraryCache   存在library还是documentr
 */
- (instancetype)initWithNameSpace:(Class)nameSpace
                     subNameSpace:(nullable NSString*)subNameSpace
                   inLibraryCache:(BOOL)isInLibraryCache;

/**
* @brief       获取业务对应的磁盘缓存的路径/key值
*
* @param    key    待获取路径信息对应的key
*
* @return    返回NSString，路径信息，如果创建失败或异常之类的，会返回@“”，不会是nil
* @warning 会检测key的有效性，只能key的length>0才会执行，如果对应业务路径不存在会进行创建，如果创建失败，才会返回空字符串
*/
- (NSString *)cachePathWithKey:(nullable NSString *)key;

/**
* @brief       同步读数据，如果有内存缓存，则直接返回内存缓存，否则会从磁盘读取
*
* @param    key    待读取数据缓存对应的key
*
* @return    返回id <NSCoding> ，如果没有对应缓存，会返回nil
* @warning 会检测key的有效性，只能key的length>0才会执行
*/
- (id <NSCoding>)objectForKey:(NSString *)key;

/**
* @brief       异步读数据，如果有内存缓存，则会返回内存缓存，否则会从磁盘读取
*
* @param    key    待读取数据缓存对应的key
*                   block 读取结果如何通过block通知外层调用方
*
* @warning 会检测key的有效性，只能key的length>0才会执行，block不为nil，可能会读取失败，具体含义见block的参数定义
*/
- (void)asyncObjectForKey:(NSString *)key block:(LightSafeStorageReadBlock)block;

/**
* @brief       异步写数据，会同时更新内存和磁盘缓存，会在全部读完才会执行写数据，多读单写
*
* @param    object    待写入的数据对象
*                   key    写入数据缓存对应的key
*                   block 设置结果如何通过block通知外层调用方
*
* @warning 会检测key的有效性，只能key的length>0才会执行，block可为nil
*/
- (void)asyncSetObject:(id <NSCoding>)object forKey:(NSString *)key block:(nullable LightSafeStorageWriteBlock)block;

/**
* @brief       异步移除内存和磁盘中key对应的缓存
*
* @param    key    待移除缓存的key
*                   block 移除结果如何通过block通知外层调用方
*
* @warning 会检测key的有效性，只能key的length>0才会执行，block可为nil
*/
- (void)asyncRemoveObjectForKey:(NSString *)key block:(nullable LightSafeStorageRemoveBlock)block;

/**
* @brief       根据key移除内存中对应的缓存
*
* @param    key   待清理缓存的key
*
* @warning 会检测key的有效性，只能key的length>0才会执行
*/
- (void)clearMemoryCacheForKey:(NSString *)key;

/**
* @brief      移除内存中所有缓存
*
*/
- (void)clearAllMemoryCache;

/**
* @brief      异步移除当前namespace内存以及磁盘中所有缓存
*
*/
- (void)asyncClearAllCacheWithBlock:(nullable LightSafeStorageClearBlock)block;



@end

NS_ASSUME_NONNULL_END
