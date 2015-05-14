//
//  KBLaunchCtl.m
//  Keybase
//
//  Created by Gabriel on 3/12/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import "KBLaunchService.h"
#import "KBEnvironment.h"
#import "KBLaunchCtl.h"
#import "AppDelegate.h"

@interface KBLaunchService ()
@property NSString *name;
@property NSString *label;
@property NSString *bundleVersion;
@property NSString *versionPath;
@property NSDictionary *plist;
@end

@implementation KBLaunchService

- (instancetype)initWithName:(NSString *)name label:(NSString *)label bundleVersion:(NSString *)bundleVersion versionPath:(NSString *)versionPath plist:(NSDictionary *)plist {
  if ((self = [super init])) {
    _name = name;
    _label = label;
    _bundleVersion = bundleVersion;
    _versionPath = versionPath;
    _plist = plist;
  }
  return self;
}

- (void)installStatus:(KBInstallableStatus)completion {
  NSString *bundleVersion = _bundleVersion;
  NSString *runningVersion = _versionPath ? [NSString stringWithContentsOfFile:_versionPath encoding:NSUTF8StringEncoding error:nil] : nil;
  GHODictionary *info = [GHODictionary dictionary];
  if (runningVersion) info[@"Version"] = runningVersion;
  [KBLaunchCtl status:_label completion:^(KBServiceStatus *status) {
    if (status.error) {
      completion([KBInstallStatus installStatusWithError:status.error]);
    } else {
      if (status.isRunning) {
        info[@"pid"] = status.pid;
        if (![runningVersion isEqualToString:bundleVersion]) {
          if (bundleVersion) info[@"New Version"] = bundleVersion;
          completion([KBInstallStatus installStatusWithStatus:KBInstalledStatusNeedsUpgrade runtimeStatus:KBRuntimeStatusRunning info:info]);
        } else {
          completion([KBInstallStatus installStatusWithStatus:KBInstalledStatusInstalled runtimeStatus:KBRuntimeStatusRunning info:info]);
        }
      } else {
        info[@"exit"] = status.lastExitStatus;
        completion([KBInstallStatus installStatusWithStatus:KBInstalledStatusInstalled runtimeStatus:KBRuntimeStatusNotRunning info:info]);
      }
    }
  }];
}

- (NSString *)info {
  return _name;
}

- (void)install:(KBCompletion)completion {
  [self installLaunchAgent:completion];
}

- (void)installLaunchAgent:(KBCompletion)completion {
  NSString *launchAgentDir = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"LaunchAgents"];
  NSString *plistDest = [launchAgentDir stringByAppendingPathComponent:NSStringWithFormat(@"%@.plist", _label)];

  if (!plistDest) {
    NSError *error = KBMakeErrorWithRecovery(-1, @"Install Error", @"No launch agent destination.", nil);
    completion(error);
    return;
  }

  //
  // TODO
  // Only install if not exists or upgrade. We are currently always installing/updating the plist.
  //
  //if (![NSFileManager.defaultManager fileExistsAtPath:launchAgentPlistDest]) {
  NSError *error = nil;

  // Remove if exists
  if ([NSFileManager.defaultManager fileExistsAtPath:plistDest]) {
    if (![NSFileManager.defaultManager removeItemAtPath:plistDest error:&error]) {
      if (!error) error = KBMakeErrorWithRecovery(-1, @"Install Error", @"Unable to remove existing luanch agent plist for upgrade.", nil);
      completion(error);
      return;
    }
  }

  NSDictionary *plistDict = _plist;
  NSData *data = [NSPropertyListSerialization dataWithPropertyList:plistDict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
  if (!data) {
    if (!error) error = KBMakeErrorWithRecovery(-1, @"Install Error", @"Unable to create plist data.", nil);
    completion(error);
    return;
  }

  if (![data writeToFile:plistDest atomically:YES]) {
    if (!error) error = KBMakeErrorWithRecovery(-1, @"Install Error", @"Unable to create launch agent plist.", nil);
    completion(error);
    return;
  }

  // We installed the launch agent plist
  DDLogDebug(@"Installed launch agent plist");

  [KBLaunchCtl reload:plistDest label:_label completion:^(KBServiceStatus *status) {
    completion(status.error);
  }];
}

//- (void)checkLaunch:(void (^)(NSError *error))completion {
//  launch_data_t config = launch_data_alloc(LAUNCH_DATA_DICTIONARY);
//
//  launch_data_t val;
//  val = launch_data_new_string("keybase.keybased");
//  launch_data_dict_insert(config, val, LAUNCH_JOBKEY_LABEL);
//  val = launch_data_new_string("/Applications/Keybase.app/Contents/MacOS/keybased");
//  launch_data_dict_insert(config, val, LAUNCH_JOBKEY_PROGRAM);
//  val = launch_data_new_bool(YES);
//  launch_data_dict_insert(config, val, LAUNCH_JOBKEY_KEEPALIVE);
//
//  launch_data_t msg = launch_data_alloc(LAUNCH_DATA_DICTIONARY);
//  launch_data_dict_insert(msg, config, LAUNCH_KEY_SUBMITJOB);
//
//  launch_data_t response = launch_msg(msg);
//  if (!response) {
//    NSError *error = KBMakeErrorWithRecovery(-1, @"Launchd Error", @"Unable to launch keybased agent.", nil);
//    completion(error);
//  } else if (response && launch_data_get_type(response) == LAUNCH_DATA_ERRNO) {
//    //strerror(launch_data_get_errno(response))
//    //NSError *error = KBMakeErrorWithRecovery(-1, @"Launchd Error", @"Unable to launch keybased agent (LAUNCH_DATA_ERRNO).", nil);
//    //completion(error);
//    completion(nil);
//  } else {
//    completion(nil);
//  }
//}

- (void)uninstall {
  NSAssert(NO, @"Not implemented");
}

@end
