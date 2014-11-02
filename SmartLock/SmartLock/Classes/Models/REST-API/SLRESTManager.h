//
//  SLRESTManager.h
//  SmartLock
//
//  Created by Pascal Fritzen on 26.10.14.
//  Copyright (c) 2014 Center for Digital Management. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>
#import "SLUser.h"

static NSString *BASE_URL_STRING = YES ? @"http://127.0.0.1:8000/api/" : @"http://213.165.86.29:8000/api/";

static NSString *SLAPIEndpointUsers = @"users/";

static NSString *SLAPIEndpointUserProfiles  = @"user-profiles/";
static NSString *SLAPIEndpointUserProfile   = @"user-profiles/:ID/";

static NSString *SLAPIEndpointLocks     = @"locks/";
static NSString *SLAPIEndpointLocksMy   = @"locks/my/";
static NSString *SLAPIEndpointLock      = @"locks/:lockID/";
static NSString *SLAPIEndpointLockOpen  = @"locks/:lockID/open/";
static NSString *SLAPIEndpointLockClose = @"locks/:lockID/close/";

static NSString *SLAPIEndpointAccessLogEntries  = @"access-log-entries/";
static NSString *SLAPIEndpointAccessLogEntry    = @"access-log-entries/:ID/";

@interface SLRESTManager : NSObject

+ (SLRESTManager *)sharedManager;

@property (nonatomic, retain) RKObjectManager *objectManager;

- (void)clearAuthorizationHeader;
- (BOOL)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password;

@end
