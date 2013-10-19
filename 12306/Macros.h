//
//  Macros.h
//  12306
//
//  Created by Wenzhe Zhou on 13-10-19.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#ifndef _2306_Macros_h
#define _2306_Macros_h

#define CHECK_INSTANCE_EXIST(var) \
    if (var == nil) { NSLog(@"not exist"); return; }

#define WeakSelfDefine(var) \
    __weak typeof(self) var = self

#define StrongSelf(var, wself) \
    typeof(wself) var = wself

#endif
