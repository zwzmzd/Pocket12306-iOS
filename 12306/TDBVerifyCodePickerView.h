//
//  TDBVerifyCodePickerView.h
//  12306
//
//  Created by Wenzhe Zhou on 17/1/8.
//  Copyright © 2017年 zwz. All rights reserved.
//

#include "OLImageView.h"

@interface TDBVerifyCodePickerView : OLImageView

- (void)clearSelectedPoints;
- (NSString *)exportSelectedPoints;

@end
