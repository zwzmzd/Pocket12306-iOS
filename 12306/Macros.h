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
    if (var == nil) { NSLog(@"%s: line %d in %s, not exist", __func__, __LINE__, __FILE__); return; }

// 这个函数不要使用，尽量使用下面的显式形式
// 仍然保留是因为迁移成本太大
#define WeakSelfDefine(var) \
    typeof(self) __weak var = self

#define WeakSelf(var, sself) \
    typeof(sself) __weak var = sself

#define StrongSelf(var, wself) \
    typeof(wself) __strong var = wself

#define RefRelease(var) \
    var = nil

#endif
