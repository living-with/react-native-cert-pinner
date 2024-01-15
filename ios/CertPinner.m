
#import "CertPinner.h"
#import <Sentry/SentrySDK.h>

@import TrustKit;

@implementation CertPinner

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

static TSKSPKIHashCache *spkiHashCache;

- (instancetype)init {
    self = [super init];

    [[TrustKit sharedInstance] setPinningValidatorCallback:^(TSKPinningValidatorResult *_Nonnull result, NSString *_Nonnull notedHostname, TKSDomainPinningPolicy *_Nonnull policy) {
        if (result.evaluationResult != TSKTrustEvaluationSuccess) {
            NSMutableArray *peerSpkiHashes = [[NSMutableArray alloc] initWithCapacity:result.certificateChain.count];
            NSMutableArray *peerCommonNames = [[NSMutableArray alloc] initWithCapacity:result.certificateChain.count];
            for (id certificateString in result.certificateChain) {
                NSString *pemString = [NSString stringWithString:certificateString];
                pemString = [pemString stringByReplacingOccurrencesOfString:@"-----BEGIN CERTIFICATE-----" withString:@""];
                pemString = [pemString stringByReplacingOccurrencesOfString:@"-----END CERTIFICATE-----" withString:@""];
                pemString = [pemString stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

                NSData *der = [[NSData alloc] initWithBase64EncodedString:pemString options:NSDataBase64DecodingIgnoreUnknownCharacters];
                SecCertificateRef certificate = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef) der);
                [peerCommonNames addObject:(NSString *) CFBridgingRelease(SecCertificateCopySubjectSummary(certificate))];
            }

            NSDictionary *userInfo = @{
                    @"Pinned domain": notedHostname,
                    @"Peer certificate PEMs:": result.certificateChain,                    
                    @"Peer certificate common names:": peerCommonNames
            };
            NSError *error = [NSError errorWithDomain:@"PinningValidationError" code:-1001 userInfo:userInfo];
            [SentrySDK captureError:error];
        }
    }];

    return self;
}

@end
