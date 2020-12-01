
#import "CertPinner.h"
#import <TrustKit/TSKSPKIHashCache.h>
#import <TrustKit/reporting_utils.h>
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

    spkiHashCache = [[TSKSPKIHashCache alloc] initWithIdentifier:@"cert-pinner.spki-hash.cache"];

    [[TrustKit sharedInstance] setPinningValidatorCallback:^(TSKPinningValidatorResult *_Nonnull result, NSString *_Nonnull notedHostname, TKSDomainPinningPolicy *_Nonnull policy) {
        if (result.evaluationResult != TSKTrustEvaluationSuccess) {
            NSArray *formattedPins = convertPinsToHpkpPins(policy[kTSKPublicKeyHashes]);

            NSMutableArray *peerSpkiHashes = [[NSMutableArray alloc] initWithCapacity:result.certificateChain.count];
            NSMutableArray *peerCommonNames = [[NSMutableArray alloc] initWithCapacity:result.certificateChain.count];
            for (id certificateString in result.certificateChain) {
                NSString *pemString = [NSString stringWithString:certificateString];
                pemString = [pemString stringByReplacingOccurrencesOfString:@"-----BEGIN CERTIFICATE-----" withString:@""];
                pemString = [pemString stringByReplacingOccurrencesOfString:@"-----END CERTIFICATE-----" withString:@""];
                pemString = [pemString stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

                NSData *der = [[NSData alloc] initWithBase64EncodedString:pemString options:NSDataBase64DecodingIgnoreUnknownCharacters];
                SecCertificateRef certificate = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef) der);
                NSData *subjectPublicKeyInfoHash = [spkiHashCache hashSubjectPublicKeyInfoFromCertificate:certificate];
                [peerSpkiHashes addObject:subjectPublicKeyInfoHash];
                [peerCommonNames addObject:(NSString *) CFBridgingRelease(SecCertificateCopySubjectSummary(certificate))];
            }
            NSArray *formattedPeers = convertPinsToHpkpPins([peerSpkiHashes copy]);
            NSMutableArray *formattedPeersWithCommonNames = [[NSMutableArray alloc] initWithCapacity:formattedPeers.count];
            for (int i = 0; i < formattedPeers.count; i++) {
                [formattedPeersWithCommonNames addObject:[NSString stringWithFormat:@"%@: CN=%@", formattedPeers[i], peerCommonNames[i]]];
            }

            NSDictionary *userInfo = @{
                    @"Peer certificate chain": formattedPeersWithCommonNames,
                    @"Pinned domain": notedHostname,
                    @"Pinned certificates": formattedPins,
                    @"Peer certificate PEMs:": result.certificateChain
            };
            NSError *error = [NSError errorWithDomain:@"PinningValidationError" code:-1001 userInfo:userInfo];
            [SentrySDK captureError:error];
        }
    }];

    return self;
}

@end
