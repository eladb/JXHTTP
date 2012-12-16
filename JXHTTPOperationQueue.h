#import "JXHTTPOperationQueueDelegate.h"

typedef void (^JXHTTPQueueBlock)(JXHTTPOperationQueue *queue);

@interface JXHTTPOperationQueue : NSOperationQueue

// Core

@property (weak) NSObject <JXHTTPOperationQueueDelegate> *delegate;
@property (assign) BOOL performsDelegateMethodsOnMainThread;
@property (strong, readonly) NSString *uniqueString;

// Progress

@property (strong, readonly) NSNumber *downloadProgress;
@property (strong, readonly) NSNumber *uploadProgress;

@property (strong, readonly) NSNumber *bytesDownloaded;
@property (strong, readonly) NSNumber *bytesUploaded;

@property (strong, readonly) NSNumber *expectedDownloadBytes;
@property (strong, readonly) NSNumber *expectedUploadBytes;

// Timing

@property (strong, readonly) NSDate *startDate;
@property (strong, readonly) NSDate *finishDate;
@property (readonly, nonatomic) NSTimeInterval elapsedSeconds;

// Blocks

@property (strong, readonly) NSOperationQueue *blockQueue;
@property (assign) BOOL performsBlocksOnMainThread;
@property (copy) JXHTTPQueueBlock willStartBlock;
@property (copy) JXHTTPQueueBlock willFinishBlock;
@property (copy) JXHTTPQueueBlock didStartBlock;
@property (copy) JXHTTPQueueBlock didUploadBlock;
@property (copy) JXHTTPQueueBlock didDownloadBlock;
@property (copy) JXHTTPQueueBlock didMakeProgressBlock;
@property (copy) JXHTTPQueueBlock didFinishBlock;

+ (instancetype)sharedQueue;

+ (instancetype)queue;

@end
