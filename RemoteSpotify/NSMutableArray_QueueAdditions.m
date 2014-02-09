//
//  NSMutableArray_QueueAdditions.m
//  RemoteSpotify
//
//  Created by Alex Schimp on 2/9/14.
//  Copyright (c) 2014 Alex Schimp. All rights reserved.
//

#import "NSMutableArray_QueueAdditions.h"

@implementation NSMutableArray (QueueAdditions)

// Add to the tail of the queue
- (void) enqueue:(id)obj {
    [self addObject: obj];
}

// Grab the next item in the queue, if there is one
- (id) dequeue {
    id queueObj = nil;
    if ([self lastObject]) {
#if !__has_feature(objc_arc)
        queueObj = [[[self objectAtIndex: 0] retain] autorelease];
#else
        queueObj = [self objectAtIndex:0];
#endif
        
        [self removeObjectAtIndex:0];
    }
    
    return queueObj;
}

- (id) peek:(int)index {
    id peekObj = nil;
    if ([self lastObject]) {
        if (index < [self count]) {
            peekObj = [self objectAtIndex:index];
        }
    }
    
    return peekObj;
}

- (id) peekHead {
    return [self peek:0];
}

- (id) peekTail {
    return [self lastObject];
}

- (BOOL) empty {
    return [self lastObject] == nil;
}

@end
