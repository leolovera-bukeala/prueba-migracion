//
//  PDFSelection_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/24/07.
/*
 This software is Copyright (c) 2007
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

#import "PDFSelection_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSParagraphStyle_SKExtensions.h"
#import "PDFPage_SKExtensions.h"


@interface PDFSelection (PDFSelectionPrivateDeclarations)

- (int)numberOfRangesOnPage:(PDFPage *)page;
- (NSRange)rangeAtIndex:(int)index onPage:(PDFPage *)page;

@end


@implementation PDFSelection (SKExtensions)

// returns the label of the first page (if the selection spans multiple pages)
- (NSString *)firstPageLabel { 
    NSArray *pages = [self pages];
    return [pages count] ? [[pages objectAtIndex:0] label] : nil;
}

- (NSAttributedString *)contextString {
    PDFSelection *extendedSelection = [self copy]; // see remark in -tableViewSelectionDidChange:
	NSMutableAttributedString *attributedSample;
	NSString *searchString = [[self string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
	NSString *sample;
    NSMutableString *attributedString;
	NSString *ellipse = [NSString stringWithFormat:@"%C", 0x2026];
	NSRange foundRange;
    NSDictionary *attributes;
	
	// Extend selection.
	[extendedSelection extendSelectionAtStart:10];
	[extendedSelection extendSelectionAtEnd:30];
	
    // get the cleaned string
    sample = [[extendedSelection string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
    
	// Finally, create attributed string.
 	attributedSample = [[NSMutableAttributedString alloc] initWithString:sample];
    attributedString = [attributedSample mutableString];
    [attributedString insertString:ellipse atIndex:0];
    [attributedString appendString:ellipse];
	
	// Find instances of search string and "bold" them.
	foundRange = [sample rangeOfString:searchString options:NSCaseInsensitiveSearch];
    if (foundRange.location != NSNotFound) {
        // Bold the text range where the search term was found.
        attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName, nil];
        [attributedSample setAttributes:attributes range:NSMakeRange(foundRange.location + 1, foundRange.length)];
        [attributes release];
    }
    
	attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSParagraphStyle defaultTruncatingTailParagraphStyle], NSParagraphStyleAttributeName, nil];
	// Add paragraph style.
    [attributedSample addAttributes:attributes range:NSMakeRange(0, [attributedSample length])];
	// Clean.
	[attributes release];
	[extendedSelection release];
	
	return [attributedSample autorelease];
}

- (int)safeNumberOfRangesOnPage:(PDFPage *)page {
    if ([self respondsToSelector:@selector(numberOfRangesOnPage:)])
        return [self numberOfRangesOnPage:page];
    else
        return 0;
}

- (NSRange)safeRangeAtIndex:(int)index onPage:(PDFPage *)page {
    if ([self respondsToSelector:@selector(rangeAtIndex:onPage:)])
        return [self rangeAtIndex:index onPage:page];
    else
        return NSMakeRange(NSNotFound, 0);
}

+ (id)selectionWithSpecifier:(id)specifier {
    if ([specifier isEqual:[NSNull null]])
        return nil;
    if ([specifier isKindOfClass:[NSArray class]] == NO)
        specifier = [NSArray arrayWithObject:specifier];
    if ([specifier count] == 1) {
        NSScriptObjectSpecifier *spec = [specifier objectAtIndex:0];
        if ([spec isKindOfClass:[NSPropertySpecifier class]]) {
            NSString *key = [spec key];
            if ([key isEqualToString:@"characters"] == NO && [key isEqualToString:@"words"] == NO && [key isEqualToString:@"paragraphs"] == NO)
                // this allows to use selection properties directly
                specifier = [spec objectsByEvaluatingSpecifier];
        }
    }
    
    PDFSelection *selection = nil;
    NSEnumerator *specEnum = [specifier objectEnumerator];
    NSScriptObjectSpecifier *spec;
    
    while (spec = [specEnum nextObject]) {
        if ([spec isKindOfClass:[NSScriptObjectSpecifier class]] == NO)
            continue;
        
        // we should get ranges of characters, words, or parapgraphs of the richText of a page
        NSString *key = [spec key];
        if ([key isEqualToString:@"characters"] == NO && [key isEqualToString:@"words"] == NO && [key isEqualToString:@"paragraphs"] == NO)
            continue;
        
        // get the richText specifier
        NSScriptObjectSpecifier *textSpec = [spec containerSpecifier];
        if ([[textSpec key] isEqualToString:@"richText"] == NO)
            continue;
        
        // get the page
        NSScriptObjectSpecifier *pageSpec = [textSpec containerSpecifier];
        PDFPage *page = [pageSpec objectsByEvaluatingSpecifier];
        if ([page isKindOfClass:[NSArray class]])
            page = [(NSArray *)page count] ? [(NSArray *)page objectAtIndex:0] : nil;
        if ([page isKindOfClass:[PDFPage class]] == NO)
            continue;
        
        // we could also evaluate textSpec, but we already have the page
        NSTextStorage *textStorage = [page richText];
        
        // now get the ranges, which can be any kind of specifier
        int startIndex, endIndex, i, count, *indices;
        NSRange *ranges = NULL;
        int numRanges = 0;
        
        if ([spec isKindOfClass:[NSPropertySpecifier class]]) {
            // this should be the full range of characters, words, or paragraphs
            numRanges = 1;
            ranges = NSZoneRealloc([self zone], ranges, sizeof(NSRange));
            ranges[0] = NSMakeRange(0, [[textStorage valueForKey:key] count]);
        } else if ([spec isKindOfClass:[NSRangeSpecifier class]]) {
            // somehow getting the indices as for the general case sometimes leads to an exception for NSRangeSpecifier, so we get the indices of the start/endSpecifiers
            NSScriptObjectSpecifier *startSpec = [(NSRangeSpecifier *)spec startSpecifier];
            NSScriptObjectSpecifier *endSpec = [(NSRangeSpecifier *)spec endSpecifier];
            
            if (startSpec == nil && endSpec == nil)
                continue;
            
            if (startSpec) {
                indices = [startSpec indicesOfObjectsByEvaluatingWithContainer:textStorage count:&count];
                if (count <= 0)
                    continue;
                startIndex = indices[0];
            } else {
                startIndex = 0;
            }
            
            if (endSpec) {
                indices = [endSpec indicesOfObjectsByEvaluatingWithContainer:textStorage count:&count];
                if (count <= 0)
                    continue;
                endIndex = indices[count - 1];
            } else {
                endIndex = [[textStorage valueForKey:key] count];
            }
            
            numRanges = 1;
            ranges = NSZoneRealloc([self zone], ranges, sizeof(NSRange));
            ranges[0] = NSMakeRange(MIN(startIndex, endIndex), MAX(startIndex, endIndex) + 1 - MIN(startIndex, endIndex));
        } else {
            // this handles other objectSpecifiers (index, middel, random, relative, whose). It can contain several ranges, e.g. for aan NSWhoseSpecifier
            indices = [spec indicesOfObjectsByEvaluatingWithContainer:textStorage count:&count];
            if (count <= 0)
                continue;
            
            for (i = 0; i < count; i++) {
                unsigned int index = indices[i];
                if (numRanges == 0 || index > NSMaxRange(ranges[numRanges - 1])) {
                    numRanges++;
                    ranges = NSZoneRealloc([self zone], ranges, numRanges * sizeof(NSRange));
                    ranges[numRanges - 1] = NSMakeRange(index, 1);
                } else {
                    ++(ranges[numRanges - 1].length);
                }
            }
        }
        
        if ([key isEqualToString:@"words"]) {
            // translate from word ranges to character ranges
            for (i = 0; i < numRanges; i++) {
                startIndex = ranges[i].location;
                endIndex = NSMaxRange(ranges[i]) - 1;
                NSRange range = [textStorage characterRangeForWordAtIndex:startIndex];
                if (range.location == NSNotFound) {
                    ranges[i] = NSMakeRange(NSNotFound, 0);
                    continue;
                }
                startIndex = range.location;
                if (ranges[i].length > 1) {
                    range = [textStorage characterRangeForWordAtIndex:endIndex];
                    if (range.location == NSNotFound) {
                        ranges[i] = NSMakeRange(NSNotFound, 0);
                        continue;
                    }
                }
                endIndex = NSMaxRange(range) - 1;
                ranges[i] = NSMakeRange(startIndex, endIndex + 1 - startIndex);
            }
        } else if ([key isEqualToString:@"paragraphs"]) {
            // translate from paragraph ranges to character ranges
            for (i = 0; i < numRanges; i++) {
                startIndex = ranges[i].location;
                endIndex = NSMaxRange(ranges[i]) - 1;
                NSRange range = [textStorage characterRangeForParagraphAtIndex:startIndex];
                if (range.location == NSNotFound) {
                    ranges[i] = NSMakeRange(NSNotFound, 0);
                    continue;
                }
                startIndex = range.location;
                if (ranges[i].length > 1) {
                    range = [textStorage characterRangeForParagraphAtIndex:endIndex];
                    if (range.location == NSNotFound) {
                        ranges[i] = NSMakeRange(NSNotFound, 0);
                        continue;
                    }
                }
                endIndex = NSMaxRange(range) - 1;
                ranges[i] = NSMakeRange(startIndex, endIndex + 1 - startIndex);
            }
        }
        
        for (i = 0; i < numRanges; i++) {
            PDFSelection *sel;
            NSRange range = ranges[i];
            if (range.length && (sel = [page selectionForRange:range])) {
                if (selection == nil)
                    selection = sel;
                else
                    [selection addSelection:sel];
            }
        }
        if (ranges) NSZoneFree([self zone], ranges);
    }
    return selection;
}

- (id)objectSpecifier {
    NSArray *pages = [self pages];
    if ([pages count] == 0)
        return [NSArray array];
    NSMutableArray *ranges = [NSMutableArray array];
    NSEnumerator *pageEnum = [pages objectEnumerator];
    PDFPage *page;
    while (page = [pageEnum nextObject]) {
        int i, iMax = [self safeNumberOfRangesOnPage:page];
        for (i = 0; i < iMax; i++) {
            NSRange range = [self safeRangeAtIndex:i onPage:page];
            if (range.length == 0)
                continue;
            
            NSScriptObjectSpecifier *textSpec = [[NSPropertySpecifier alloc] initWithContainerSpecifier:[page objectSpecifier] key:@"richText"];
            if (textSpec == nil)
                continue;
            
            NSIndexSpecifier *startSpec = [[NSIndexSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" index:range.location];
            NSIndexSpecifier *endSpec = [[NSIndexSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" index:NSMaxRange(range) - 1];
            if (startSpec == nil || endSpec == nil) {
                [startSpec release];
                [endSpec release];
                continue;
            }
            
            NSRangeSpecifier *rangeSpec = [[NSRangeSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" startSpecifier:startSpec endSpecifier:endSpec];
            if (rangeSpec == nil)
                continue;
            
            [ranges addObject:rangeSpec];
            [rangeSpec release];
            [startSpec release];
            [endSpec release];
            [textSpec release];
        }
    }
    return ranges;
}

@end


@implementation NSTextStorage (SKExtensions) 

- (NSRange)characterRangeForWordAtIndex:(unsigned int)index {
    NSString *string = [self string];
    NSArray *words = [self words];
    unsigned int length = [string length];
    NSRange range = NSMakeRange(0, 0);
    unsigned int i, iMax = [words count];
    
    if (index >= iMax)
        return NSMakeRange(NSNotFound, 0);
    for (i = 0; i <= index; i++) {
        NSString *word = [[words objectAtIndex:i] string];
        NSRange searchRange = NSMakeRange(NSMaxRange(range), length - NSMaxRange(range));
        if ([word length] == 0)
            continue;
        range = [string rangeOfString:word options:NSLiteralSearch range:searchRange];
        if (range.location == NSNotFound)
            return NSMakeRange(NSNotFound, 0);
    }
    return range;
}

- (NSRange)characterRangeForParagraphAtIndex:(unsigned int)index {
    NSString *string = [self string];
    NSArray *paragraphs = [self paragraphs];
    unsigned int length = [string length];
    NSRange range = NSMakeRange(0, 0);
    unsigned int i, iMax = [paragraphs count];
    
    if (index >= iMax)
        return NSMakeRange(NSNotFound, 0);
    for (i = 0; i <= index; i++) {
        NSString *paragraph = [[paragraphs objectAtIndex:i] string];
        NSRange searchRange = NSMakeRange(NSMaxRange(range), length - NSMaxRange(range));
        if ([paragraph length] == 0)
            continue;
        range = [string rangeOfString:paragraph options:NSLiteralSearch range:searchRange];
        if (range.location == NSNotFound)
            return NSMakeRange(NSNotFound, 0);
    }
    return range;
}

@end

