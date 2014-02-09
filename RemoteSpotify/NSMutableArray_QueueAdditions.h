//
//  NSMutableArray_QueueAdditions.h
//  RemoteSpotify
//
//  Created by Alex Schimp on 2/9/14.
//  Copyright (c) 2014 Alex Schimp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (QueueAdditions)

- (id) dequeue;
- (void) enqueue:(id)obj;
- (id) peek:(int)index;
- (id) peekHead;
- (id) peekTail;
- (BOOL) empty;

@end
