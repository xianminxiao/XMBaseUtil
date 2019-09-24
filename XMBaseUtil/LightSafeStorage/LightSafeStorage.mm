//
//  LightSafeStorage.m
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/9/10.
//  Copyright © 2019 xianminxiao. All rights reserved.
//

#import "LightSafeStorage.h"
#import "NSStringEX.h"
#import "ModuleDefine.h"

@interface LightSafeStorage()
{
    dispatch_queue_t      _ioQueue;
}

@property(nonatomic, strong) Class             nameSpace;               // 磁盘路径构成部分,各个业务需要不同的nameSpace
@property(nonatomic, strong) NSString*         subNameSpace;            // 磁盘路径构成部分,各个业务需要不同的nameSpace
@property(nonatomic, strong) NSString*         rootPath;                // 磁盘缓存的root路径  根据nameSpace，isInLibraryCache，pathWithUin来生成，不建议修改，默认为 rootPath/key为文件路径 或者rootPath/uin/key

@property(nonatomic, assign) BOOL              isInLibraryCache;        // 存取到Library/caches目录还是Document目录，默认存在Document目录

@property(nonatomic, strong) NSCache*          memoryCache;             // 内存缓存

@end

@implementation LightSafeStorage

#pragma mark - public method
- (instancetype)initWithNameSpace:(Class)nameSpace
{
    return [self initWithNameSpace:nameSpace subNameSpace:nil inLibraryCache:NO];
}

- (instancetype)initWithNameSpace:(Class)nameSpace
                     subNameSpace:(nullable NSString*)subNameSpace
                   inLibraryCache:(BOOL)isInLibraryCache
{
    if (self = [super init])
    {
        _nameSpace = nameSpace;
        _subNameSpace = subNameSpace;
        _isInLibraryCache = isInLibraryCache;
        
        NSString *queueString = [NSString stringWithFormat:@"%@_%p", MODULE_LIGHT_SAFE_STORAGE, self];
        _ioQueue = dispatch_queue_create([queueString UTF8String], DISPATCH_QUEUE_SERIAL);
        _memoryCache = [NSCache new];
    }
    return self;
}

/**
 *  获取磁盘缓存的filePath
 */
- (NSString *)cachePathWithKey:(NSString *)key
{
    NSString* log = [NSString stringWithFormat:@"%s, key=%s", __FUNCTION__, key.UTF8String];
    [self printLog:log];
    if (key.length <= 0 || ![self creatStorageFilePath]) //先创建目录
        return @"";
    return [self.rootPath stringByAppendingPathComponent:key];
}


- (id <NSCoding>)objectForKey:(NSString *)key
{
    NSString* log = [NSString stringWithFormat:@"%s, key=%s", __FUNCTION__, key.UTF8String];
    [self printLog:log];
    if (key.length == 0)
        return nil;
    
    __block id<NSCoding> object = nil;
    __weak __typeof__(self) weakSelf = self;
    dispatch_sync(_ioQueue, ^{
        __strong __typeof(self) strongSelf = weakSelf;
        if (!strongSelf || ![strongSelf respondsToSelector:@selector(initWithNameSpace:subNameSpace:inLibraryCache:)])
        {
            return;
        }
        BOOL bResult = YES;
        object = [strongSelf getObjectForKeyFromCacheOrDisk:key bGetResult:bResult];
        NSString* resultLog = [NSString stringWithFormat:@"%s, key=%s, bResult=%d", __FUNCTION__, key.UTF8String, bResult];
        [strongSelf printLog:resultLog];
    });
    return object;
}

/**
 *  异步读数据，如果有内存缓存，则直接返回内存缓存
 */
- (void)asyncObjectForKey:(NSString *)key block:(LightSafeStorageReadBlock)block
{
    NSString* log = [NSString stringWithFormat:@"%s, key=%s, key length=%ld", __FUNCTION__, key.UTF8String, (unsigned long)key.length];
    [self printLog:log];
    if (!block)
        return;
    if (key.length == 0)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        block(self, key, nil, NO);
#pragma clang diagnostic pop
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_ioQueue, ^{
        __strong __typeof(self) strongSelf = weakSelf;
        if (!strongSelf || ![strongSelf respondsToSelector:@selector(initWithNameSpace:subNameSpace:inLibraryCache:)])
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
            block(strongSelf, key, nil, NO);
#pragma clang diagnostic pop
            return;
        }
        BOOL bResult = YES;
        id<NSCoding> object = [strongSelf getObjectForKeyFromCacheOrDisk:key bGetResult:bResult];
        block(strongSelf, key, object, bResult);
        NSString* resultLog = [NSString stringWithFormat:@"%s, key=%s, key length=%ld, bResult=%d", __FUNCTION__, key.UTF8String, (unsigned long)key.length, bResult];
        [strongSelf printLog:resultLog];
    });
}

- (void)asyncSetObject:(id <NSCoding>)object forKey:(NSString *)key block:(nullable LightSafeStorageWriteBlock)block
{
    NSString* log = [NSString stringWithFormat:@"%s, key=%s, key length=%ld, object %s nil", __FUNCTION__, key.UTF8String, (unsigned long)key.length, object?"not":"is"];
    [self printLog:log];
    if (!object || key.length <= 0)
    {
        if (block)
            block(self, key, object, NO);
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    dispatch_barrier_async(_ioQueue, ^{
        __strong __typeof(self) strongSelf = weakSelf;
        if (!strongSelf || ![strongSelf respondsToSelector:@selector(initWithNameSpace:subNameSpace:inLibraryCache:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
                if (block)
                    block(strongSelf, key, object, NO);
#pragma clang diagnostic pop
            });
            return;
        }
        @try {
            NSString *filePath = [self cachePathWithKey:key];
            BOOL written = [NSKeyedArchiver archiveRootObject:object toFile:filePath];
            [strongSelf.memoryCache setObject:object forKey:key];
            NSString* resultLog = [NSString stringWithFormat:@"%s, key=%s, key length=%ld, written=%d", __FUNCTION__, key.UTF8String, (unsigned long)key.length, written];
            [strongSelf printLog:resultLog];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block)
                    block(strongSelf, key, object, written);
            });
        }
        @catch (NSException *e) {
            NSString* eName = e.name==nil?@"":e.name;
            NSString* eReason = e.reason==nil?@"":e.reason;
            NSString* resultLog = [NSString stringWithFormat:@"%s, key=%s, key length=%ld, exception name=%s, reason=%s", __FUNCTION__, key.UTF8String, (unsigned long)key.length, eName.UTF8String, eReason.UTF8String];
            [strongSelf printLog:resultLog];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block)
                    block(strongSelf, key, object, NO);
            });
        }
    });
}

- (void)asyncRemoveObjectForKey:(NSString *)key block:(nullable LightSafeStorageRemoveBlock)block
{
    NSString* log = [NSString stringWithFormat:@"%s, key=%s, key length=%ld, block %s nil", __FUNCTION__, key.UTF8String, (unsigned long)key.length, block?"not":"is"];
    [self printLog:log];
    if (key.length <= 0)
    {
        if (block)
            block(self, key, NO);
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_barrier_async(_ioQueue, ^{
        __strong __typeof(self) strongSelf = weakSelf;
        if (!strongSelf || ![strongSelf respondsToSelector:@selector(initWithNameSpace:subNameSpace:inLibraryCache:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block)
                    block(strongSelf, key, NO);
            });
            return;
        }
        @try {
            [strongSelf.memoryCache removeObjectForKey:key];
            
            NSString *filePath = [strongSelf cachePathWithKey:key];
            
            BOOL success = YES;
            NSFileManager *fileManager =  [NSFileManager defaultManager];
            BOOL bFileExist = [fileManager fileExistsAtPath:filePath];
            if (bFileExist)
                success = [fileManager removeItemAtPath:filePath error:nil];
            NSString* resultLog = [NSString stringWithFormat:@"%s, key=%s, key length=%ld, bFileExist=%d, success=%d", __FUNCTION__, key.UTF8String, (unsigned long)key.length, bFileExist, success];
            [strongSelf printLog:resultLog];
            
            if (block)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(strongSelf, key, success);
                });
            }
        }
        @catch (NSException *e) {
            NSString* eName = e.name==nil?@"":e.name;
            NSString* eReason = e.reason==nil?@"":e.reason;
            NSString* resultLog = [NSString stringWithFormat:@"%s, key=%s, key length=%ld, exception name=%s, reason=%s", __FUNCTION__, key.UTF8String, (unsigned long)key.length, eName.UTF8String, eReason.UTF8String];
            [strongSelf printLog:resultLog];
            dispatch_async(dispatch_get_main_queue(), ^{
                block(strongSelf, key, NO);
            });
        }
    });
}

- (void)clearMemoryCacheForKey:(NSString *)key
{
    NSString* log = [NSString stringWithFormat:@"%s, key=%s, key length=%ld", __FUNCTION__, key.UTF8String, (unsigned long)key.length];
    [self printLog:log];
    if (key.length <= 0)
        return;
    [_memoryCache removeObjectForKey:key];
}

- (void)clearAllMemoryCache
{
    NSString* log = [NSString stringWithFormat:@"%s", __FUNCTION__];
    [self printLog:log];
    [_memoryCache removeAllObjects];
}

- (void)asyncClearAllCacheWithBlock:(nullable LightSafeStorageClearBlock)block
{
    NSString* log = [NSString stringWithFormat:@"%s, block %s nil", __FUNCTION__, block?"not":"is"];
    [self printLog:log];

    __weak __typeof__(self) weakSelf = self;
    dispatch_barrier_async(_ioQueue, ^{
        __strong __typeof(self) strongSelf = weakSelf;
        if (!strongSelf || ![strongSelf respondsToSelector:@selector(initWithNameSpace:subNameSpace:inLibraryCache:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block)
                    block(strongSelf, NO);
            });
            return;
        }
        @try {
            [strongSelf.memoryCache removeAllObjects];
            BOOL success = YES;
            NSFileManager *fileManager =  [NSFileManager defaultManager];
            BOOL bFileExist = [fileManager fileExistsAtPath:strongSelf.rootPath isDirectory:nil];
            if (bFileExist)
                success = [fileManager removeItemAtPath:strongSelf.rootPath error:nil];
            NSString* resultLog = [NSString stringWithFormat:@"%s, path=%s, bFileExist=%d, success=%d", __FUNCTION__, strongSelf.rootPath.UTF8String, bFileExist, success];
            [strongSelf printLog:resultLog];
            
            if (block)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(strongSelf, success);
                });
            }
        }
        @catch (NSException *e) {
            NSString* eName = e.name==nil?@"":e.name;
            NSString* eReason = e.reason==nil?@"":e.reason;
            NSString* resultLog = [NSString stringWithFormat:@"%s, exception name=%s, reason=%s", __FUNCTION__, eName.UTF8String, eReason.UTF8String];
            [strongSelf printLog:resultLog];
            if (!block)
                return;
            dispatch_async(dispatch_get_main_queue(), ^{
                block(strongSelf, NO);
            });
        }
    });
}

#pragma mark - private method
- (NSString *)rootPath
{
    if (!_rootPath)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(self.isInLibraryCache ? NSCachesDirectory : NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docPath = [paths firstObject];
        NSString* namespaceClassName = NSStringFromClass(_nameSpace);
        NSString* bussinessPath = [NSString stringWithFormat:@"%@/%@", [MODULE_LIGHT_SAFE_STORAGE MD5String], [namespaceClassName MD5String]];
        if (_subNameSpace)
            bussinessPath = [NSString stringWithFormat:@"%@/%@", bussinessPath, [_subNameSpace MD5String]];
        _rootPath = [docPath stringByAppendingPathComponent:bussinessPath];
    }
    
    return _rootPath;
}

- (BOOL)creatStorageFilePath
{
    BOOL bCreateResult = YES;
    NSString *path = self.rootPath;
    NSFileManager *manager =  [NSFileManager defaultManager];
    BOOL dir = YES;
    if (![manager fileExistsAtPath:path isDirectory:&dir])
    {
        bCreateResult = [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        if (!bCreateResult)
        {
            // log
            bCreateResult = NO;
        }
    }
    NSString* log = [NSString stringWithFormat:@"%s create result=%d", __FUNCTION__, bCreateResult];
    [self printLog:log];
    return bCreateResult;
}

- (void)printLog:(NSString*)log
{
    if (log.length <= 0)
        return;
    if (!_storageDelegate || ![_storageDelegate respondsToSelector:@selector(logInfo:)])
    {
        [_storageDelegate logInfo:log];
    }
}

- (id<NSCoding>)getObjectForKeyFromCacheOrDisk:(NSString*)key bGetResult:(BOOL&)bResult
{
    NSString* log = [NSString stringWithFormat:@"%s, key=%s, key length=%ld", __FUNCTION__, key.UTF8String, (unsigned long)key.length];
    [self printLog:log];
    bResult = YES;
    id<NSCoding> object = nil;
    if (key.length <= 0)
    {
        bResult = NO;
        return object;
    }
    @try {
        BOOL isCache = YES;
        object = [_memoryCache objectForKey:key];
        if (!object)
        {
            isCache = NO;
            NSString *filePath = [self cachePathWithKey:key];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
            {
                object = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
                if(object)
                    [_memoryCache setObject:object forKey:key];
                else   // unarchiveObjectWithFile出的object为nil...
                    bResult = NO;
            }
            else
            {
                NSString* resultLog = [NSString stringWithFormat:@"%s, key=%s, key length=%ld, file not exist", __FUNCTION__, key.UTF8String, (unsigned long)key.length];
                [self printLog:resultLog];
            }
        }
        
        NSString* resultLog = [NSString stringWithFormat:@"%s, key=%s, key length=%ld, isCache=%d, bResult=%d", __FUNCTION__, key.UTF8String, (unsigned long)key.length, isCache, bResult];
        [self printLog:resultLog];

    }
    @catch (NSException *e) {
        NSString* eName = e.name==nil?@"":e.name;
        NSString* eReason = e.reason==nil?@"":e.reason;
        NSString* resultLog = [NSString stringWithFormat:@"%s, key=%s, key length=%ld, exception name=%s, reason=%s", __FUNCTION__, key.UTF8String, (unsigned long)key.length, eName.UTF8String, eReason.UTF8String];
        [self printLog:resultLog];
        bResult = NO;
    }
    
    return object;
}

@end
