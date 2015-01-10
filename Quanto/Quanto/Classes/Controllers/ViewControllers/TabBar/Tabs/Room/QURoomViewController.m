//
//  QURoomViewController.m
//  Quanto
//
//  Created by Pascal Fritzen on 09.01.15.
//  Copyright (c) 2015 Pascal Fritzen. All rights reserved.
//

#import "QURoomViewController.h"
#import <CoreData/CoreData.h>
#import "QULock.h"
#import "QURoom.h"
#import "PFCoreDataManager.h"
#import "QUGuestManager.h"
#import "QUKeyManager.h"
#import "QULoginViewController.h"
#import "QURoom+QUUtils.h"
#import "QULockManager.h"
#import "QULock+QUUtils.h"

@interface QURoomViewController ()

@property (nonatomic, retain) NSFetchRequest *locksFetchRequest;
@property (nonatomic, retain) NSArray *fetchedLocks;

@property (nonatomic, retain) NSTimer *reloadLocksTimer;

@end

@implementation QURoomViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.locksFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([QULock class])];
	NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"room.number" ascending:YES];
	self.locksFetchRequest.sortDescriptors = @[descriptor];

	[self fetchLocks];

	[self performSelector:@selector(reloadLocks) withObject:nil afterDelay:0.0f];
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];

	self.openLockSwitch.onTintColor = [UIColor peterRiverColor];
	self.openLockSwitch.inactiveColor = [UIColor whiteColor];
	self.openLockSwitch.isRounded = NO;
	self.openLockSwitch.thumbTintColor = [UIColor peterRiverColor];
	self.openLockSwitch.onThumbTintColor = [UIColor whiteColor];
	self.openLockSwitch.borderColor = [UIColor peterRiverColor];

	[self.openLockSwitch.offLabel setTextColor:[UIColor peterRiverColor]];
	self.openLockSwitch.offLabel.font = [UIFont fontWithName:@"Montserrat-Light" size:15.0f];
	self.openLockSwitch.offLabel.text = @"Slide to unlock";

	self.openLockSwitch.onLabel.text = @"Unlocking...";
	[self.openLockSwitch.onLabel setTextColor:[UIColor whiteColor]];
	self.openLockSwitch.onLabel.font = [UIFont fontWithName:@"Montserrat-Light" size:15.0f];

	/*
	   self.dvSwitch = [[DVSwitch alloc] initWithStringsArray:@[@"Lock", @"Unlock"]];
	   self.dvSwitch.frame = self.dvSwitchPlaceholder.frame;
	   [self.dvSwitch setPressedHandler:^(NSUInteger index) {
	    DLOG(@"Pressed!");
	   }];
	   [self.view addSubview:self.dvSwitch];*/
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.view.frame;
    gradientLayer.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor darkerDarkGrayColor].CGColor];
    gradientLayer.locations = @[@0.0, @1.0];
    //[self.roomPictureImageView.layer insertSublayer:gradientLayer atIndex:0];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	self.reloadLocksTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(reloadLocks) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	[self.reloadLocksTimer invalidate];
	self.reloadLocksTimer = nil;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

#pragma mark - Reload Locks

- (void)reloadLocks
{
	if ([QUGuestManager isCurrentGuestLoggedIn]) {
		[QUKeyManager synchronizeAllMyKeysWithSuccessHandler:^(NSSet *keys) {
		     // [self.refreshControl endRefreshing];
			 [self fetchLocks];
		 } failureHandler:^(NSError *error) {
		     // [self.refreshControl endRefreshing];
			 [self fetchLocks];
		 }];
	} else {
		[QULoginViewController showWithPresentingViewController:self successHandler:^(QUGuest *guest) {
			 [self reloadLocks];
		 } failureHandler:^(NSError *error) {
			 [self reloadLocks];
		 }];
	}
}

- (void)fetchLocks
{
	NSError *error = nil;

	self.fetchedLocks = [[PFCoreDataManager sharedManager].managedObjectContext executeFetchRequest:self.locksFetchRequest error:&error];

	if (self.fetchedLocks == nil) {
		// Error Handling
		self.noRoomMessageLabel.hidden = NO;
	} else {
		self.noRoomMessageLabel.hidden = YES;

		QULock *lock = [self.fetchedLocks firstObject];

		self.roomNumberLabel.text = [NSString stringWithFormat:@"Room No. %i", [lock.room.number intValue]];
		self.roomDetailsLabel.text = lock.room.descriptionText;
        
        if ([lock isOpen]) {
            [self.openLockSwitch setOn:[lock isOpen] animated:NO];
            self.openLockSwitch.onLabel.text = @"Unlocked!";
            self.openLockSwitch.onTintColor = [UIColor emeraldColor];
        }

		[lock.room downloadPictureWithSuccessHandler:^{
			 self.roomPictureImageView.image = [UIImage imageWithData:lock.room.pictureData];
		 } failureHandler:^(NSError *error) {
			 DLOG(@"FAIL");
		 }];
	}
}

- (void)closeLockAfterDelay:(float)delay
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.openLockSwitch setOn:NO animated:YES];
        [QULockManager closeLock:[self.fetchedLocks firstObject] withCompletionHandler:^(NSError *error, QULock *lock) {
        }];
        self.openLockSwitch.onLabel.text = @"Unlocking ...";
        self.openLockSwitch.onTintColor = [UIColor peterRiverColor];
    });
}

#pragma mark - IBActions

- (IBAction)didTouchOpenLockSwitch:(id)sender
{
	if (self.openLockSwitch.isOn) {
        [QULockManager openLock:[self.fetchedLocks firstObject] withCompletionHandler:^(NSError *error, QULock *lock) {
            if (error) {
                DLOG(@"ERROR: %@", error);
                self.openLockSwitch.onLabel.text = @"Error...";
                [self closeLockAfterDelay:3.0f];
            } else {
                self.openLockSwitch.onLabel.text = @"Unlocked!";
                self.openLockSwitch.onTintColor = [UIColor emeraldColor];
                
                [self closeLockAfterDelay:5.0f];
            }
        }];
	} else {
        self.openLockSwitch.onLabel.text = @"Unlocking ...";
        self.openLockSwitch.onTintColor = [UIColor peterRiverColor];

        [QULockManager closeLock:[self.fetchedLocks firstObject] withCompletionHandler:^(NSError *error, QULock *lock) {
        }];
	}
}

@end
