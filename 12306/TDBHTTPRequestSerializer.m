//
//  TDBHTTPRequestSerializer.m
//  12306
//
//  Created by Wenzhe Zhou on 17/1/7.
//  Copyright © 2017年 zwz. All rights reserved.
//

#import "TDBHTTPRequestSerializer.h"

@implementation TDBHTTPRequestSerializer

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(id)parameters
                                     error:(NSError *__autoreleasing *)error {
    NSMutableURLRequest *request;
    NSData *postBody = [parameters objectForKey:USER_DEFINED_POSTBODY];
    
    // 有的时候，我们需要自己构造数据提交
    if (postBody != nil) {
        request = [super requestWithMethod:method URLString:URLString parameters:nil error:error];
        request.HTTPMethod = @"POST";
        request.HTTPBody = postBody;
    } else {
        request = [super requestWithMethod:method URLString:URLString parameters:parameters error:error];
    }
    
    return request;
}

@end
