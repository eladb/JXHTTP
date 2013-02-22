#import "JXOperation.h"

@interface JXOperation ()

@property (assign) BOOL isExecuting;
@property (assign) BOOL isFinished;

#if OS_OBJECT_USE_OBJC
@property (strong) dispatch_queue_t stateQueue;
#else
@property (assign) dispatch_queue_t stateQueue;
#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
@property (assign) UIBackgroundTaskIdentifier backgroundTaskID;
#endif

@end

@implementation JXOperation

#pragma mark - Initialization

- (void)dealloc
{
    [self endAppBackgroundTask];
    
    #if !OS_OBJECT_USE_OBJC
    dispatch_release(_stateQueue);
    _stateQueue = NULL;
    #endif
}

- (instancetype)init
{
    if (self = [super init]) {
        NSString *queueName = [[NSString alloc] initWithFormat:@"%@.%p.state", NSStringFromClass([self class]), self];
        self.stateQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);

        self.isExecuting = NO;
        self.isFinished = NO;
        self.startsOnMainThread = NO;
        self.continuesInAppBackground = NO;
        
        #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
        self.backgroundTaskID = UIBackgroundTaskInvalid;
        #endif
    }
    return self;
}

+ (instancetype)operation
{
    return [[self alloc] init];
}

#pragma mark - NSOperation

- (void)start
{
    if (self.startsOnMainThread && ![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
        return;
    }
    
    if (![self isReady] || [self isCancelled])
        return;
    
    __block BOOL shouldStart = YES;
    
    dispatch_sync(self.stateQueue, ^{
        if (self.isExecuting || self.isFinished) {
            shouldStart = NO;
        } else {
            [self willChangeValueForKey:@"isExecuting"];
            self.isExecuting = YES;
            [self didChangeValueForKey:@"isExecuting"];
            
            if (self.continuesInAppBackground)
                [self startAppBackgroundTask];
        }
    });
    
    if (!shouldStart)
        return;

    @autoreleasepool {
        [self main];
    }
}

- (void)main
{
    NSAssert(NO, @"subclasses must implement and eventually call finish", nil);
}

#pragma mark - Public Methods

- (BOOL)isConcurrent
{
    return YES;
}

- (void)cancel
{
    [super cancel];
    
    @synchronized(self) {
        [self finish];
    }
}

- (void)finish
{
    dispatch_sync(self.stateQueue, ^{
        if (self.isExecuting) {
            [self willChangeValueForKey:@"isExecuting"];
            [self willChangeValueForKey:@"isFinished"];
            self.isExecuting = NO;
            self.isFinished = YES;
            [self didChangeValueForKey:@"isExecuting"];
            [self didChangeValueForKey:@"isFinished"];
        } else if (!self.isFinished) {
            self.isExecuting = NO;
            self.isFinished = YES;
        }
        
        [self endAppBackgroundTask];
    });
}

- (void)startAndWaitUntilFinished
{
    NSOperationQueue *tempQueue = [[NSOperationQueue alloc] init];
    [tempQueue addOperation:self];
    [tempQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - Private Methods

- (void)startAppBackgroundTask
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
    
    if (self.backgroundTaskID != UIBackgroundTaskInvalid || [self isCancelled])
        return;
    
    __weak __typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!weakSelf || [weakSelf isCancelled] || weakSelf.isFinished)
            return;

        UIBackgroundTaskIdentifier taskID = UIBackgroundTaskInvalid;
        taskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:taskID];
        }];

        weakSelf.backgroundTaskID = taskID;
    });

    #endif
}

- (void)endAppBackgroundTask
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
    
    UIBackgroundTaskIdentifier taskID = self.backgroundTaskID;
    if (taskID == UIBackgroundTaskInvalid)
        return;
    
    self.backgroundTaskID = UIBackgroundTaskInvalid;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] endBackgroundTask:taskID];
    });

    #endif
}

@end
