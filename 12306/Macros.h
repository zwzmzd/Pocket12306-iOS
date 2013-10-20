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

#define USER_AGENT_STR (@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.101 Safari/537.36")

#endif
