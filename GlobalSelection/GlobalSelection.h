//
//  GlobalSelection.h
//  GlobalSelection
//
//  Created by Keaton Burleson on 5/6/21.
//

#import <Foundation/Foundation.h>

//! Project version number for GlobalSelection.
FOUNDATION_EXPORT double GlobalSelectionVersionNumber;

//! Project version string for GlobalSelection.
FOUNDATION_EXPORT const unsigned char GlobalSelectionVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <GlobalSelection/PublicHeader.h>


typedef int CGSConnectionID;
CGError CGSSetConnectionProperty(CGSConnectionID cid, CGSConnectionID targetCID, CFStringRef key, CFTypeRef value);
int _CGSDefaultConnection();
