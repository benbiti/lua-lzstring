-- Test 
local lzstring = require "lzstring"

print(lzstring.decompress(lzstring.compress('{"v":"growingio.com 数据采集无需埋点 用户行为分析更专业"}')))
print(lzstring.decompressFromBase64(lzstring.compressToBase64('{"v":"growingio.com 数据采集无需埋点 用户行为分析更专业"}')))
print(lzstring.decompressFromUTF16(lzstring.compressToUTF16('{"v":"growingio.com 数据采集无需埋点 用户行为分析更专业"}')))
print(lzstring.decompressFromEncodedURIComponent(lzstring.compressToEncodeURIComponent('{"v":"growingio.com 数据采集无需埋点 用户行为分析更专业"}')))
print(lzstring.decompressFromEncodedURIComponent(lzstring.compressToEncodeURIComponent('AAAAABBABCABCABC')))
