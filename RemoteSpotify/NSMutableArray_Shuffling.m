//
//  NSMutableArray_Shuffling.m
//  RemoteSpotify
//
//  Created by Alex Schimp on 2/9/14.
//  Copyright (c) 2014 Alex Schimp. All rights reserved.
//

#import "NSMutableArray_Shuffling.h"

@implementation NSMutableArray (Shuffling)

- (void) shuffle {
    NSUInteger count = [self count];
    for (NSUInteger i = 0; i < count; ++i) {
        // Select a random element between iand the end of the array to swap with
        NSInteger nElements = count - i;
        NSInteger n = arc4random_uniform(nElements) + i;
        [self exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
}

@end
