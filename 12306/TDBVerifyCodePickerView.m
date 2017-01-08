//
//  TDBVerifyCodePickerView.m
//  12306
//
//  Created by Wenzhe Zhou on 17/1/8.
//  Copyright © 2017年 zwz. All rights reserved.
//

#import "TDBVerifyCodePickerView.h"
#import "OLImage.h"

@interface TDBVerifyCodePickerView()

@property (nonatomic) NSMutableArray *selectedImagePoints;

@end

@implementation TDBVerifyCodePickerView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [self addGestureRecognizer:singleTap];
        self.selectedImagePoints = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    if (self.image != nil) {
        CGPoint imageViewPoint = [recognizer locationInView:self];
        CGPoint imagePoint = [self convertToImagePoint:imageViewPoint];
        NSLog(@"%f %f", imagePoint.x, imagePoint.y);
        
        BOOL exists = NO;
        for (NSInteger i = 0; i < self.selectedImagePoints.count; i++) {
            NSValue *val = [self.selectedImagePoints objectAtIndex:i];
            CGPoint p = [val CGPointValue];
            if ([self distanceBetweenPoint:imagePoint andPoint:p] < 10.f) {
                [self.selectedImagePoints removeObjectAtIndex:i];
                exists = YES;
                NSLog(@"removed");
                break;
            }
        }
        
        if (!exists) {
            [self.selectedImagePoints addObject:[NSValue valueWithCGPoint:imagePoint]];
            NSLog(@"added");
        }
    }
}

- (CGPoint)convertToImageViewPoint:(CGPoint)imagePoint {
    float percentX = imagePoint.x / self.image.size.width;
    float percentY = imagePoint.y / self.image.size.height;
    return CGPointMake(self.frame.size.width * percentX, self.frame.size.height * percentY);
}

- (CGPoint)convertToImagePoint:(CGPoint)imageViewPoint {
    float percentX = imageViewPoint.x / self.frame.size.width;
    float percentY = imageViewPoint.y / self.frame.size.height;
    return CGPointMake(self.image.size.width * percentX, self.image.size.height * percentY);
}

- (CGFloat)distanceBetweenPoint:(CGPoint)p1 andPoint:(CGPoint)p2 {
    CGFloat xDist = (p2.x - p1.x);
    CGFloat yDist = (p2.y - p1.y);
    return sqrt((xDist * xDist) + (yDist * yDist));
}

- (NSString *)exportSelectedPoints {
    NSMutableArray *data = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < self.selectedImagePoints.count; i++) {
        NSValue *val = [self.selectedImagePoints objectAtIndex:i];
        CGPoint p = [val CGPointValue];
        [data addObject:[NSString stringWithFormat:@"%.0f,%.0f", p.x, p.y]];
    }
    return [data componentsJoinedByString:@","];
}

@end
