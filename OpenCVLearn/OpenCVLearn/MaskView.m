//
//  MaskView.m
//  OpenCVLearn
//
//  Created by 曾坚 on 2019/1/14.
//  Copyright © 2019年 JK. All rights reserved.
//

#import "MaskView.h"

@implementation MaskView


- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    [[UIColor colorWithWhite:0 alpha:1] setFill];
    CGContextAddRect(ref, rect);
    for (int i = 0; i < self.redrawRectArr.count; i++) {
        CGRect r = [[self.redrawRectArr objectAtIndex:i] CGRectValue];
        CGContextAddEllipseInRect(ref, r);
    }
    CGContextEOFillPath(ref);
}

- (void)setRedrawRectArr:(NSArray *)redrawRectArr
{
    _redrawRectArr = redrawRectArr;
    
    [self setNeedsDisplay];
}


@end
