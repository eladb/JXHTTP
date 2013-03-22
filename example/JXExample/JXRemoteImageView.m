#import "JXRemoteImageView.h"
#import "JXHTTP.h"

@interface JXRemoteImageView ()
@property (strong, nonatomic) JXHTTPOperation *operation;
@end

@implementation JXRemoteImageView

- (void)dealloc
{
    [self.operation cancel];
}

- (void)setImageURL:(NSURL *)imageURL
{
    _imageURL = imageURL;
    
    if (self.operation) {
        [self.operation cancel];
        self.operation = nil;
    }
    
    if (!self.imageURL) {
        self.image = nil;
        return;
    }
    
    self.operation = [[JXHTTPOperation alloc] initWithURL:self.imageURL];
    self.operation.performsBlocksOnMainQueue = YES;
    
    __weak __typeof(self) weakSelf = self;

    self.operation.didFinishLoadingBlock = ^(JXHTTPOperation *op) {
        weakSelf.image = [[UIImage alloc] initWithData:[op responseData]];
        weakSelf.operation = nil;
    };
    
    self.operation.didFailBlock = ^(JXHTTPOperation *op) {
        NSLog(@"load failed! received %lld bytes. error: %@", op.bytesDownloaded, op.error);
        weakSelf.operation = nil;
    };
    
    [[JXHTTPOperationQueue sharedQueue] addOperation:self.operation];
}

@end
