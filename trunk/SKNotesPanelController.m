//
//  SKNotesPanelController.m
//  Skim
//
//  Created by Christiaan Hofman on 10/31/07.
/*
 This software is Copyright (c) 2007-2008
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

#import "SKNotesPanelController.h"
#import "SKMainWindowController.h"

static NSString *SKNotesPanelFrameAutosaveName = @"SKNotesPanel";

@implementation SKNotesPanelController

static SKNotesPanelController *sharedController = nil;

+ (id)sharedController {
    if (sharedController == nil)
        [[self alloc] init];
    return sharedController;
}

+ (BOOL)sharedControllerExists {
    return sharedController != nil;
}

+ (id)allocWithZone:(NSZone *)zone {
    if (sharedController == nil)
        return [super allocWithZone:[self zone]];
    else
        return sharedController;
}

- (id)init {
    if (sharedController == nil && (self = [super initWithWindowNibName:@"NotesPanel"])) {
        sharedController = self;
    }
    return sharedController;
}

- (id)retain { return self; }

- (id)autorelease { return self; }

- (void)release {}

- (unsigned)retainCount { return UINT_MAX; }

- (void)windowDidLoad {
    [self setWindowFrameAutosaveName:SKNotesPanelFrameAutosaveName];
}

- (IBAction)addNote:(id)sender {
    id controller = [[NSApp mainWindow] windowController];
    if ([controller respondsToSelector:@selector(createNewNote:)]) {
        [(SKMainWindowController *)controller createNewNote:sender];
        [[controller window] makeKeyWindow];
        [[controller window] makeFirstResponder:(NSResponder *)[(SKMainWindowController *)controller pdfView]];
    } else {
        NSBeep();
    }
}

@end
