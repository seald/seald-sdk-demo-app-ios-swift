#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "Helpers.h"
#import "SealdEncryptionSession.h"
#import "SealdSdk.h"

FOUNDATION_EXPORT double SealdSdkVersionNumber;
FOUNDATION_EXPORT const unsigned char SealdSdkVersionString[];

