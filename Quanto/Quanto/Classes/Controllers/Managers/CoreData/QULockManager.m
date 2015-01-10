//
//  QULockManager.m
//  Quanto
//
//  Created by Pascal Fritzen on 30.12.14.
//  Copyright (c) 2014 Pascal Fritzen. All rights reserved.
//

#import "QULockManager.h"
#import "QUKeyManager.h"
#import "QURoomManager.h"

// REST API Endpoints
static NSString *QUAPIEndpointLocks     = @"locks/";
static NSString *QUAPIEndpointLock      = @"locks/:lockID/";
static NSString *QUAPIEndpointLockOpen  = @"locks/:lockID/open/";
static NSString *QUAPIEndpointLockClose = @"locks/:lockID/close/";

@implementation QULockManager

#pragma mark - CoreData

+ (Class)entityClass
{
	return [QULock class];
}

+ (NSString *)entityIDKey
{
	return @"lockID";
}

+ (BOOL)shouldInvokeSimpleUpdate
{
	return NO;
}

+ (BOOL)checkToUpdateEntity:(id)entity withJSON:(NSDictionary *)JSON
{
	QULock *lock = entity;
	BOOL didUpdate = NO;

	if (![lock.name isEqualToString:JSON[@"name"]]) {
		lock.name = JSON[@"name"];
		didUpdate = YES;
	}

	if (![lock.name isEqualToString:JSON[@"status"]]) {
		lock.status = JSON[@"status"];
		didUpdate = YES;
	}
    
    if (![lock.locationLat isEqualToNumber:JSON[@"location_lat"]]) {
		lock.locationLat = JSON[@"location_lat"];
		didUpdate = YES;
	}
    
    if (![lock.locationLon isEqualToNumber:JSON[@"location_lon"]]) {
		lock.locationLon = JSON[@"location_lon"];
		didUpdate = YES;
	}

    //    lock.keys = [QUKeyManager fetchOrCreateEntitiesWithEntityIDs:JSON[@"keys"]];
    
	QURoom *room = [QURoomManager updateOrCreateEntityWithJSON:JSON[@"room"]];
    if (lock.room != room) {
        lock.room = room;
		didUpdate = YES;
	}
    
	// DLOG(@"Updated User Profile with JSON:%@\n%@", JSON, userProfile);
    
    if (didUpdate) {
        DLOG(@"Updated QULock %@", lock.name);
    }
    
    return didUpdate;
}

#pragma mark - REST-API

+ (void)openLock:(QULock *)lock withCompletionHandler:(void (^)(NSError *, QULock *))completionHandler
{
	NSString *endpoint = [QUAPIEndpointLockOpen stringByReplacingOccurrencesOfString:@":lockID" withString:[lock.lockID stringValue]];

	[[PFRESTManager sharedManager].operationManager POST:endpoint
											  parameters:nil
												 success:^(AFHTTPRequestOperation *operation, id responseObject) {
		 QULock *lock = [self updateOrCreateEntityWithJSON:responseObject];
		 completionHandler(nil, lock);
	 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		 completionHandler(error, nil);
	 }];
}

+ (void)closeLock:(QULock *)lock withCompletionHandler:(void (^)(NSError *, QULock *))completionHandler
{
	NSString *endpoint = [QUAPIEndpointLockClose stringByReplacingOccurrencesOfString:@":lockID" withString:[lock.lockID stringValue]];

	[[PFRESTManager sharedManager].operationManager POST:endpoint
											  parameters:nil
												 success:^(AFHTTPRequestOperation *operation, id responseObject) {
		 QULock *lock = [self updateOrCreateEntityWithJSON:responseObject];
		 completionHandler(nil, lock);
	 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		 completionHandler(error, nil);
	 }];
}

+ (void)synchronizeLockWithLockID:(NSNumber *)lockID successHandler:(void (^)(QULock *))successHandler failureHandler:(void (^)(NSError *))failureHandler
{
	NSString *endpoint = [QUAPIEndpointLock stringByReplacingOccurrencesOfString:@":lockID" withString:[lockID stringValue]];
	[super fetchSingleRemoteEntityAtEndpoint:endpoint successHandler:successHandler failureHandler:failureHandler];
}

+ (void)synchronizeAllLocksWithSuccessHandler:(void (^)(NSSet *))successHandler failureHandler:(void (^)(NSError *))failureHandler
{
	[super fetchAllRemoteEntitiesAtEndpoint:QUAPIEndpointLocks successHandler:successHandler failureHandler:failureHandler];
}

@end
