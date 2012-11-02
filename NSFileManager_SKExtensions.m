//
//  NSFileManager_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 9/4/09.
/*
 This software is Copyright (c) 2009-2012
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSFileManager_SKExtensions.h"


@implementation NSFileManager (SKExtensions)

- (BOOL)fileExistsAtURL:(NSURL *)aURL {
    return [self fileExistsAtPath:[aURL path]];
}

- (BOOL)isTrashedFileAtURL:(NSURL *)aURL {
    NSCParameterAssert([aURL isFileURL]);    
    FSRef fileRef;
    Boolean result = false;
    if (CFURLGetFSRef((CFURLRef)aURL, &fileRef)) {
        FSDetermineIfRefIsEnclosedByFolder(0, kTrashFolderType, &fileRef, &result);
        if (result == false)
            FSDetermineIfRefIsEnclosedByFolder(0, kSystemTrashFolderType, &fileRef, &result);
    }
    return result;
}

- (NSArray *)applicationSupportDirectoryURLs {
    static NSArray *applicationSupportDirectoryURLs = nil;
    if (applicationSupportDirectoryURLs == nil) {
        NSMutableArray *urlArray = [NSMutableArray array];
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
        for (NSURL *url in [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSAllDomainsMask])
            [urlArray addObject:[url URLByAppendingPathComponent:appName]];
        applicationSupportDirectoryURLs = [urlArray copy];
    }
    return applicationSupportDirectoryURLs;
}

- (NSURL *)uniqueFileURL:(NSURL *)fileURL {
    NSURL *uniqueFileURL = fileURL;
    NSURL *baseURL = [fileURL URLByDeletingLastPathComponent];
    NSString *baseName = [[fileURL lastPathComponent] stringByDeletingPathExtension];
    NSString *extension = [fileURL pathExtension];
    NSInteger i = 0;
    while ([self fileExistsAtURL:uniqueFileURL])
        uniqueFileURL = [baseURL URLByAppendingPathComponent:[[baseName stringByAppendingFormat:@"-%ld", (long)++i] stringByAppendingPathExtension:extension]];
    return uniqueFileURL;
}

- (NSURL *)uniqueChewableItemsDirectoryURL {
    // chewable items are automatically cleaned up at restart, and it's hidden from the user
    static NSURL *chewableItemsDirectoryURL = nil;
    if (chewableItemsDirectoryURL == nil) {
        FSRef chewableRef;
        if (noErr == FSFindFolder(kUserDomain, kChewableItemsFolderType, TRUE, &chewableRef)) {
            NSURL *chewableURL = (NSURL *)CFURLCreateFromFSRef(kCFAllocatorDefault, &chewableRef);
            chewableItemsDirectoryURL = [[chewableURL URLByAppendingPathComponent:@"Skim"] copy];
            if ([self fileExistsAtURL:chewableItemsDirectoryURL] == NO)
                [self createDirectoryAtPath:[chewableItemsDirectoryURL path] withIntermediateDirectories:NO attributes:nil error:NULL];
            [chewableURL release];
       }
    }
    
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *tmpDirName = [(NSString *)CFUUIDCreateString(NULL, uuid) autorelease];
    CFRelease(uuid);
    NSURL *uniqueURL = [chewableItemsDirectoryURL URLByAppendingPathComponent:tmpDirName];
    
    [self createDirectoryAtPath:[uniqueURL path] withIntermediateDirectories:NO attributes:nil error:NULL];
   
   return uniqueURL;
}

@end
