//#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *plistPath = @"/private/var/mobile/Library/Preferences/com.fadexz.osversionspooferprefs.plist";
static NSString *spoofedUserAgent = nil;
static NSString *storedBuildNumber = nil;
static NSUUID *sharedUUID = nil;

// Generate randomised build number once
NSString* getRandomisedBuildNumber() {
    if (!storedBuildNumber) {
        int  firstPart  = arc4random_uniform(100);
        char letterPart = 'A' + arc4random_uniform(26);
        int  secondPart = 100 + arc4random_uniform(900);
        storedBuildNumber = [NSString stringWithFormat:@"%02d%c%d", firstPart, letterPart, secondPart];
    }
    return storedBuildNumber;
}

static NSUUID *generateAndStoreUUID() {
    static NSUUID *sharedUUID = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedUUID = [NSUUID UUID];
    });
    return sharedUUID;
}

// Generate predicted latest version using the current date
NSOperatingSystemVersion getPredictedLatestVersion() {
    NSInteger currentYear  = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]];
    NSInteger currentMonth = [[NSCalendar currentCalendar] component:NSCalendarUnitMonth fromDate:[NSDate date]];
    NSOperatingSystemVersion osVersion;
    // Increment predicted major version based on year and month of stored .0 version month
    osVersion.majorVersion = 17 + (currentYear - 2024) + (currentMonth >= 10 ? 1 : 0);
    NSDictionary *monthToMinorVersion = @{
        @10: @0,
        @11: @1,
        @ 1: @2,
        @ 2: @3,
        @ 4: @4,
        @ 6: @5,
        @ 8: @6
    };
    NSNumber *lastValidMinorVersion = @0;
    NSArray *sortedMonths = [[monthToMinorVersion allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSNumber *month in sortedMonths) {
        if ([month integerValue] <= currentMonth) {
            lastValidMinorVersion = monthToMinorVersion[month];
        } else {
            break;
        }
    }
    osVersion.minorVersion = [lastValidMinorVersion integerValue];
    osVersion.patchVersion = 0;
    return osVersion;
}

NSString *updateOSVersion(NSString *userAgent) {
    NSString *patternOS = @"OS (\\d+(_\\d+)*) like Mac OS X";
    NSError *error = nil;
    NSRegularExpression *regexOS = [NSRegularExpression regularExpressionWithPattern:patternOS options:0 error:&error];
    if (!error && regexOS) {
        NSTextCheckingResult *matchOS = [regexOS firstMatchInString:userAgent options:0 range:NSMakeRange(0, [userAgent length])];
        if (matchOS) {
            NSRange matchRangeOS = [matchOS rangeAtIndex:1];
            NSOperatingSystemVersion osVersion = getPredictedLatestVersion();
            NSString *spoofedOSVersion = [NSString stringWithFormat:@"%ld_%ld", (long)osVersion.majorVersion, (long)osVersion.minorVersion];
            userAgent = [userAgent stringByReplacingCharactersInRange:matchRangeOS withString:spoofedOSVersion];
        } else {
            NSLog(@"Regex error for OS pattern: %@", [error localizedDescription]);
        }
    }
    return userAgent;
}

NSString *updateAppVersion(NSString *userAgent) {
    NSString *patternAppVer = @"appver=(\\d+(\\.\\d+)*)";
    NSError *error = nil;
    NSRegularExpression *regexAppVer = [NSRegularExpression regularExpressionWithPattern:patternAppVer options:0 error:&error];
    if (!error && regexAppVer) {
        NSTextCheckingResult *matchAppVer = [regexAppVer firstMatchInString:userAgent options:0 range:NSMakeRange(0, [userAgent length])];
        if (matchAppVer) {
            NSRange matchRangeAppVer = [matchAppVer rangeAtIndex:1];
            NSString *spoofedAppVer = @"2147483647";
            userAgent = [userAgent stringByReplacingCharactersInRange:matchRangeAppVer withString:spoofedAppVer];
        } else {
            NSLog(@"Regex error for app version pattern: %@", [error localizedDescription]);
        }
    }
    return userAgent;
}

NSString *updateVersion(NSString *userAgent) {
    NSOperatingSystemVersion osVersion = getPredictedLatestVersion();
    NSString *majorVersion = [NSString stringWithFormat:@"%ld.0", (long)osVersion.majorVersion];
    userAgent = [userAgent stringByReplacingOccurrencesOfString:@"Version/\\d+\\.\\d+\\.\\d+"
                                                     withString:[NSString stringWithFormat:@"Version/%@", majorVersion]
                                                        options:NSRegularExpressionSearch
                                                          range:NSMakeRange(0, [userAgent length])];
    return userAgent;
}

// Store if the tweak has been enabled in the preferences file
BOOL isTweakEnabled() {
    NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    return [plistDict[@"masterEnabled"] boolValue];
}

// Check if the current app has been added in the preferences file as an app to spoof
BOOL isAppEnabled() {
    NSString *currentAppIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSArray *enabledApps = plistDict[@"spoofedApps"];
    return [enabledApps containsObject:currentAppIdentifier];
}

BOOL isAppVersionEnabled() {
    NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    return [plistDict[@"appVersionEnabled"] boolValue];
}

// Spoof process provided info
%hook NSProcessInfo
-(NSOperatingSystemVersion)operatingSystemVersion {
    if (isTweakEnabled() && isAppEnabled()) {
        return getPredictedLatestVersion();
    }
    else {
        return %orig;
    }
}
-(id)operatingSystemVersionString {
    if (isTweakEnabled() && isAppEnabled()) {
        NSOperatingSystemVersion osVersion = getPredictedLatestVersion();
        NSString *changedVersion = [NSString stringWithFormat:@"%ld.%ld", (long)osVersion.majorVersion, (long)osVersion.minorVersion];
        return [NSString stringWithFormat:@"Version %@ (Build %@)", changedVersion, getRandomisedBuildNumber()];
    }
    else {
        return %orig;
    }
}
-(BOOL)isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion)compareOSVersion {
    if (isTweakEnabled() && isAppEnabled()) {
        NSOperatingSystemVersion spoofedOSVersion = getPredictedLatestVersion();
        if ((compareOSVersion.majorVersion < spoofedOSVersion.majorVersion) ||
            (compareOSVersion.majorVersion == spoofedOSVersion.majorVersion && compareOSVersion.minorVersion < spoofedOSVersion.minorVersion) ||
            (compareOSVersion.majorVersion == spoofedOSVersion.majorVersion && compareOSVersion.minorVersion == spoofedOSVersion.minorVersion && compareOSVersion.patchVersion <= spoofedOSVersion.patchVersion)) {
            return TRUE;
        } else {
            return FALSE;
        }
    } else {
        return %orig;
    }
}
/*
-(CGFloat)systemUptime {
    CGFloat randomUptime = ((CGFloat)arc4random() / UINT32_MAX) * (86400 - 1) + 1;
    return [[NSString stringWithFormat:@"%.9f", randomUptime] doubleValue];
}
*/
-(NSString *)hostName {
    if (isTweakEnabled() && isAppEnabled()) {
        return @"iphone.local";
    }
    else {
        return %orig;
    }
}
%end

// Spoof device supplied OS Version
%hook UIDevice
-(NSString *)systemVersion {
    if (isTweakEnabled() && isAppEnabled()) {
        NSOperatingSystemVersion osVersion = getPredictedLatestVersion();
        return [NSString stringWithFormat:@"%ld.%ld", (long)osVersion.majorVersion, (long)osVersion.minorVersion];
    }
    else {
        return %orig;
    }
}
-(id)buildVersion {
    if (isTweakEnabled() && isAppEnabled()) {
        return getRandomisedBuildNumber();
    }
    else {
        return %orig;
    }

}
-(NSString *)name {
    if (isTweakEnabled() && isAppEnabled()) {
        return @"iPhone";
    }
    else {
        return %orig;
    }
}
-(NSString *)hostName {
    if (isTweakEnabled() && isAppEnabled()) {
        return @"iphone.local";
    }
    else {
        return %orig;
    }
}
-(NSUUID *)identifierForVendor {
    if (isTweakEnabled() && isAppEnabled()) {
        return generateAndStoreUUID();
    }
    else {
        return %orig;
    }
}
%end

%hook NSMutableURLRequest
-(void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)header {
    NSString *userAgentHeaderField = @"User-Agent";
    if (isTweakEnabled() && isAppEnabled() && value && [header isEqualToString:userAgentHeaderField]) {
        if (isAppVersionEnabled()) {
            value = updateAppVersion(value);
        }
        value = updateOSVersion(value);
        NSLog(@"User Agent (NSMutableURLReq): %@", value);
    }
    %orig(value, header);
}
%end

%hook NSURLRequest
-(NSString *)valueForHTTPHeaderField:(NSString *)header {
    NSString *value = %orig;
    NSString *userAgentHeaderField = @"User-Agent";
    if (isTweakEnabled() && isAppEnabled() && value && [header isEqualToString:userAgentHeaderField]) {
        if (isAppVersionEnabled()) {
            value = updateAppVersion(value);
        }
        value = updateOSVersion(value);
        NSLog(@"User Agent (NSURLReq): %@", value);
        return value;
    }
    return %orig;
}
%end

//UIWebView
//URLConnection
//NURLSession

// Spoof User Agent OS Version
%hook WKWebView
-(NSString *)_userAgent {
    NSString *originalUserAgent = %orig;
    if (isTweakEnabled() && isAppEnabled() && originalUserAgent) {
		if (isAppVersionEnabled()) {
			originalUserAgent = updateAppVersion(originalUserAgent);
		}
        originalUserAgent = updateOSVersion(originalUserAgent);
        NSLog(@"User Agent (WKWebView): %@", originalUserAgent);
    }
    return originalUserAgent;
}
-(NSString *)_applicationNameForUserAgent {
    NSString *originalAppUserAgent = %orig;
    if (isTweakEnabled() && isAppEnabled() && originalAppUserAgent) {
		if (isAppVersionEnabled()) {
			originalAppUserAgent = updateAppVersion(originalAppUserAgent);
		}
        originalAppUserAgent = updateVersion(originalAppUserAgent);
        NSLog(@"User Agent (WKWebViewConfiguration): %@", originalAppUserAgent);
    }
    return originalAppUserAgent;
}
//-(void)_setApplicationNameForUserAgent:(id)arg1
//-(NSString *)customUserAgent
//-(NSString *)_customUserAgent
%end

// Note: Maybe remove OS version spoof from this as it is not in this
%hook WKWebViewConfiguration
-(NSString *)applicationNameForUserAgent {
    NSString *originalAppUserAgent = %orig;
    if (isTweakEnabled() && isAppEnabled() && originalAppUserAgent) {
		if (isAppVersionEnabled()) {
			originalAppUserAgent = updateAppVersion(originalAppUserAgent);
		}
        originalAppUserAgent = updateVersion(originalAppUserAgent);
    }
    return originalAppUserAgent;
}
-(NSString *)_applicationNameForDesktopUserAgent {
    NSString *originalAppUserAgent = %orig;
    if (isTweakEnabled() && isAppEnabled() && originalAppUserAgent) {
		if (isAppVersionEnabled()) {
			originalAppUserAgent = updateAppVersion(originalAppUserAgent);
		}
        originalAppUserAgent = updateVersion(originalAppUserAgent);
    }
    return originalAppUserAgent;
}
//-(void)setApplicationNameForUserAgent:(NSString *)arg1
%end

// Spoof Custom User Agent OS Version
%hook WKBrowsingContextController
-(NSString *)applicationNameForUserAgent {
    NSString *originalAppUserAgent = %orig;
    if (isTweakEnabled() && isAppEnabled() && originalAppUserAgent) {
		if (isAppVersionEnabled()) {
			originalAppUserAgent = updateAppVersion(originalAppUserAgent);
		}
        originalAppUserAgent = updateVersion(originalAppUserAgent);
        NSLog(@"User Agent (WKBrowsingContextController): %@", originalAppUserAgent);
    }
    return originalAppUserAgent;
}
/*
-(NSString *)customUserAgent {
    NSString *originalAppUserAgent = %orig;
    if (isTweakEnabled() && isAppEnabled() && spoofedUserAgent != nil) {
	NSLog(@"User Agent (brow): %@", spoofedUserAgent);
        return spoofedUserAgent;
    }
    return originalAppUserAgent;
}
*/
//-(void)setApplicationNameForUserAgent:(NSString *)arg1
%end

/*
%hook WKWebpagePreferences
-(NSString *)customUserAgent {
    NSString *originalAppUserAgent = %orig;
    if (isTweakEnabled() && isAppEnabled() && spoofedUserAgent != nil) {
        NSLog(@"User Agent (pref): %@", spoofedUserAgent);
        return spoofedUserAgent;
    }
    return originalAppUserAgent;
}
%end
*/

%hook BrowserController
-(NSUUID *)UUID {
    if (isTweakEnabled() && isAppEnabled()) {
        return generateAndStoreUUID();
    }
    else {
        return %orig;
    }
}
%end

%hook ASIdentifierManager
-(NSUUID *)advertisingIdentifier {
    if (isTweakEnabled() && isAppEnabled()) {
        return generateAndStoreUUID();
    }
    else {
        return %orig;
    }
}
%end


/*
#include <sys/sysctl.h>
#include <substrate.h>

%hookf(int, sysctlbyname, const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    // Check if the requested attribute is "kern.osversion"
    if (strcmp(name, "kern.osversion") == 0) {
        // Override the OS version value with a fake version
        const char *fakeVersion = "17.5";
        // Ensure the buffer is large enough to hold the fake version
        if (oldp && oldlenp && *oldlenp >= strlen(fakeVersion) + 1) {
            // Copy the fake version into the buffer
            strcpy((char *)oldp, fakeVersion);
            // Update the length of the data
            *oldlenp = strlen(fakeVersion) + 1;
            // Return 0 to indicate success
            return 0;
        }
    }
    // Call the original function for other cases
    return %orig(name, oldp, oldlenp, newp, newlen);
}
*/
