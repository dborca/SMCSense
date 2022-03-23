//
//  AppDelegate.m
//  SMCSense
//
//  Created by Daniel Borca on 29/02/16.
//  Copyright © 2016 Daniel Borca. All rights reserved.
//

#import "AppDelegate.h"
#import "APSL/SMCSensors.h"
#import "APSL/XRGAppleSiliconSensorMiner.h"
#import "NSMenuItem Additions.h"
#include <sys/sysctl.h>

NSString * const kSMCSenseRefresh = @"SMCSenseRefresh";
NSString * const kSMCSenseShowFan = @"SMCSenseShowFan";

@interface AppDelegate ()

@property (nonatomic, strong, readwrite) NSStatusItem *statusItem;
@property (nonatomic, strong, readwrite) SMCSensors *smcSensors;
@property (nonatomic, strong, readwrite) NSDictionary *profile;
@property (atomic, readwrite) BOOL isMenuOpen;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kSMCSenseRefresh: @10.0}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kSMCSenseShowFan: @TRUE}];
    
    self.smcSensors = [[SMCSensors alloc] init];
    self.profile = [self loadProfile];

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.menu = [[NSMenu alloc] init];
    [self.statusItem.menu setDelegate:self];
#ifdef NON_SELECTABLE
    [self.statusItem.menu setAutoenablesItems:NO];
#endif
    [self.statusItem.menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"Q"];
    self.statusItem.button.image = [NSImage imageNamed:@"StatusItem-Image"];

    [self updateStatusItemMenu:[NSApplication sharedApplication]];
    
    NSTimeInterval timeInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:kSMCSenseRefresh];
    NSTimer *timer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(updateStatusItemMenu:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)updateStatusItemMenu:(id)sender
{
	NSMenuItem *item;
	NSMenu *menu = self.statusItem.menu;
	[menu removeAllItems];

	id key;
	BOOL showUnknownSensors = TRUE;
	NSDictionary *values = [XRGAppleSiliconSensorMiner sensorData];
	NSArray *sortedKeys = nil;
	float maxTemp = -273.16;
	NSColor *color;
	bool any;

	if (values == nil) {
		// maybe switch to https://github.com/hholtmann/smcFanControl.git
		values = [self.smcSensors temperatureValuesIncludingUnknown:showUnknownSensors];
	}
	sortedKeys = [[values allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	any = FALSE;
	for (key in sortedKeys) {
		id aValue = values[key];
		if (![aValue isKindOfClass:[NSNumber class]]) continue;
		float temperature = [aValue floatValue];
		if (temperature < 0 || temperature > 150) {
			continue;
		}
		NSString *humanReadableName = [self getHumanReadableString:key];
//		NSLog(@"%@: %.1f C\n", humanReadableName, temperature);
		if (self.isMenuOpen && temperature >= 20) {
			color = [self getTempColor:temperature];
			item = [[NSMenuItem alloc] initWithTitle:humanReadableName action:@selector(doNothing:) keyEquivalent:@""];
#ifdef NON_SELECTABLE
			if (color == nil) color = [NSColor blackColor];
			[item setEnabled:NO];
#endif
			[item setActivationString:[NSString stringWithFormat:@"%.1f °C", temperature] withFont:nil andColor:color];
			[menu addItem:item];
			any = TRUE;
		}
		if (maxTemp < temperature) {
			maxTemp = temperature;
		}
	}
	if (any) {
		[menu addItem:[NSMenuItem separatorItem]];
	}

	if (self.isMenuOpen && [[NSUserDefaults standardUserDefaults] boolForKey:kSMCSenseShowFan]) {
		values = [self.smcSensors fanValues];
		sortedKeys = [[values allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		any = FALSE;
		for (key in sortedKeys) {
			id fanDict = values[key];
			NSArray *fanDictKeys = [fanDict allKeys];
			NSUInteger speedKeyIndex = [fanDictKeys indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
				if ([obj hasSuffix:@"Ac"]) {
					*stop = YES;
					return YES;
				}
				return NO;
			}];
			if (speedKeyIndex != NSNotFound) {
				id fanSpeedKey = fanDictKeys[speedKeyIndex];
//				NSLog(@"%@ = %d\n", key, [fanDict[fanSpeedKey] intValue]);
				color = [self getFanColor:[fanDict[fanSpeedKey] intValue]];
				item = [[NSMenuItem alloc] initWithTitle:key action:@selector(doNothing:) keyEquivalent:@""];
#ifdef NON_SELECTABLE
				if (color == nil) color = [NSColor blackColor];
				[item setEnabled:NO];
#endif
				[item setActivationString:[NSString stringWithFormat:@"%d rpm", [fanDict[fanSpeedKey] intValue]] withFont:nil andColor:color];
				[menu addItem:item];
				any = TRUE;
			}
		}
		if (any) {
			[menu addItem:[NSMenuItem separatorItem]];
		}
	}

	[menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"Q"];

	NSString *title = [NSString stringWithFormat:@"%.1f °C", maxTemp];
	self.statusItem.button.image = nil;
	self.statusItem.title = title;
	self.statusItem.title = title; // Work around bug where setting the title only once will cause a layout issue

	NSDictionary *titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:menu.font, NSFontAttributeName, [self getTempColor:maxTemp], NSForegroundColorAttributeName, nil];
	self.statusItem.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:titleAttributes];

	if (maxTemp > 95) {
		[[NSSound soundNamed:@"Ping"] play]; // NSBeep();
	}
}

- (NSColor *)getTempColor:(float)temperature
{
    if (temperature > 85) {
        return [NSColor redColor];
    }
    if (temperature > 70) {
        return [NSColor brownColor];
    }
    return nil;
}

- (NSColor *)getFanColor:(int)rpm
{
    if (rpm > 2500) {
        return [NSColor redColor];
    }
    return nil;
}

#pragma mark - Profiles

- (NSString *)sysctlByName:(const char *)name
{
    int rv;
    char *p;
    size_t len;
    NSString *str = nil;
    rv = sysctlbyname(name, NULL, &len, NULL, 0);
    if (rv) {
        return nil;
    }
    p = malloc(len);
    if (!p) {
        return nil;
    }
    rv = sysctlbyname(name, p, &len, NULL, 0);
    if (rv == 0) {
        str = [NSString stringWithUTF8String:p];
    }
    free(p);
    return str;
}

- (NSDictionary *)loadProfile
{
    NSString *config;
    NSString *machine = [self sysctlByName:"hw.model"];
    if (machine) {
        config = [[NSBundle mainBundle] pathForResource:machine ofType:@"plist" inDirectory:@"Profiles"];
        if (config) {
            NSDictionary *profile = [NSDictionary dictionaryWithContentsOfFile:config];
            if (profile) {
                return profile;
            }
        }
    }
    config = [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"plist" inDirectory:@"Profiles"];
    return config ? [NSDictionary dictionaryWithContentsOfFile:config] : nil;
}

- (NSString *)getHumanReadableString:(NSString *)key
{
    NSString *val = self.profile ? self.profile[key] : nil;
    return val ?: [self.smcSensors humanReadableNameForKey:key];
}

#pragma mark - NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)menu
{
    self.isMenuOpen = YES;
    [self updateStatusItemMenu:self];
}

- (void)menuDidClose:(NSMenu *)menu
{
    self.isMenuOpen = NO;
}

#pragma mark - Menu actions

- (void)doNothing:(id)sender
{
}

@end
