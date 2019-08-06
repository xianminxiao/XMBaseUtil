//
//  ToolFunctions.m
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/8/6.
//  Copyright © 2019 xianminxiao. All rights reserved.
//

#import "ToolFunctions.h"

int hex2strUpper(const char *hex, int hexlen, char *str)
{
    unsigned char c, s;
    int i = 0;
    
    while(hexlen > 0)
    {
        c = *hex++;
        hexlen--;
        
        s = 0x0F & c;
        if ( s < 10 )
        {
            str[i + 1] = '0' + s;
        }
        else
        {
            str[i + 1] = 'A' + (s - 10);
        }
        
        c >>= 4;
        s = 0x0F & c;
        if ( s < 10 )
        {
            str[i] = '0' + s;
        }
        else
        {
            str[i] = 'A' + (s - 10);
        }
        i += 2;
    }
    str[i++] = '\0';
    return i;
}
