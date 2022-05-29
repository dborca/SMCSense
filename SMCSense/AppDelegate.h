//
//  AppDelegate.h
//  SMCSense
//
//  Created by Daniel Borca on 29/02/16.
//  Copyright © 2016 Daniel Borca. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SMCSensors;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>

@property (nonatomic, readonly) NSStatusItem *statusItem;
@property (nonatomic, readonly) SMCSensors *smcSensors;
@property (nonatomic, readonly) NSMutableDictionary *profile;
@property (atomic, readonly) BOOL isMenuOpen;

@end
