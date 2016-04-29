-- LZString for Lua
--
_M = { _VERSION = "0.1" }

local bit = require("bit")
local utf8 = require("lua-utf8")

local keyStrBase64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
local keyStrUriSafe = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-$"
local baseReverseDic_keyStrBase64 = {}
local baseReverseDic_keyStrUriSafe= {}

function getBaseValue_keyStrBase64(character)
    for i=0,string.len(keyStrBase64)-1,1
        do
        baseReverseDic_keyStrBase64 [string.char(string.byte(keyStrBase64, i+1))] = i
    end
    return baseReverseDic_keyStrBase64[character] 
end

function getBaseValue_keyStrUriSafe(character)
    for i=0,string.len(keyStrUriSafe)-1,1
    do
        baseReverseDic_keyStrUriSafe[string.char(string.byte(keyStrUriSafe, i+1))] = i
    end

    return baseReverseDic_keyStrUriSafe[character]
end

function funcBase64(a)
    return string.char(string.byte(keyStrBase64, a+1))
end

function _M.compressToBase64(inputStr)

    if not inputStr or inputStr =='' then
        return '' 
    end

    local res = _compress(inputStr, 6, funcBase64)
    if (string.len(res) % 4) == 0 then
        return res
    elseif (string.len(res) % 4) == 1 then
        return res .. '==='
    elseif (string.len(res) % 4) == 2 then
        return res .. '=='
    elseif (string.len(res) % 4) == 3 then
        return res .. '='
    end
end

function table_remove(table, key)
    local ret_table={}
    for k,v in pairs(table) do
        if k ~= key then
            ret_table[k]=v
        end
    end
    return ret_table
end

function table_length(table)
    local length=0
    for k,v in pairs(table) do
        length = length + 1
    end
    return length
end

function get_char_value(context, bitsPerChar)
    if bitsPerChar == 6 then
        return string.byte(context)
    end
    
    if bitsPerChar == 15 or bitsPerChar == 16 then
        return utf8.byte(context, 0, 1)
    end
end

function defunc_Base64(inputStr, index)
    return getBaseValue_keyStrBase64(string.char(string.byte(inputStr, index + 1)))
end

function _M.decompressFromBase64(inputStr)
    if not inputStr then
      return ''
    end
  
    if inputStr == '' then
        return nil
    end
    return _decompress(inputStr, 32, defunc_Base64)
end

function funcUTF16(a)
    return utf8.char(a+32)
end

function _M.compressToUTF16(input)
  if not input or input == '' then
      return ''
  end
  
  return _compress(input, 15, funcUTF16)
end

function defunc_UTF16(inputStr, index)
    return utf8.byte(inputStr, index+1, index +1 ) -32
end

function _M.decompressFromUTF16(compressedStr)
    if not compressedStr or compressedStr == '' then
        return ''
    end
    return _decompress(compressedStr, 16384, defunc_UTF16)
end

function funcURI(a)
    return string.char(string.byte(keyStrUriSafe, a+1))
end

function defunc_URI(inputStr, index)
    return getBaseValue_keyStrUriSafe(string.char(string.byte(inputStr, index + 1)))
end

function _M.compressToEncodeURIComponent(input)
  if not input then
      return ''
  end
  return _compress(input, 6, funcURI) 
end

function _M.decompressFromEncodedURIComponent(inputStr)
    if  not inputStr then
        return ''
    end
    
    if inputStr == '' then
        return nil
    end
    
    inputStr = string.gsub(inputStr, ' ', '+')
    return _decompress(inputStr, 32, defunc_URI)
end

function defunc(inputStr, i)
  return string.char(string.byte(inputStr, index + 1))
end


function _M.compress(input)
  if not input or input == '' then
      return ''
  end
  
  return _compress(input, 16, fc)
end

function defunc(inputStr, index)
    return utf8.byte(inputStr, index+1, index +1)
end

function _M.decompress(inputStr)
    if not inputStr then 
        return ''
    end

    if inputStr == '' then
        return nil
    end
    
    return _decompress(inputStr, 32768, defunc)
end

function get_uncompressed_length(context, bitsPerChar)
    
    if bitsPerChar == 6 then
        length = string.len(context)
    end

    if bitsPerChar == 15 or bitsPerChar == 16 then
        length =utf8.len(context)
    end
    
    return length
end

function get_char_from_uncompressed(context, bitsPerChar, i)
    if bitsPerChar == 15 or bitsPerChar == 16 then
        context_c =  utf8.sub(context, i+1, i+1)
    else
        context_c = string.char(string.byte(context, i+1))
    end
    return context_c 
end


function _compress(uncompressedStr, bitsPerChar, getCharFromInt)
    if not uncompressedStr or uncompressedStr == '' then
        return ""
    end

    local length = get_uncompressed_length(uncompressedStr, bitsPerChar)
    local i
    local value
    context_dictionary = {}
    context_dictionaryToCreate = {}
    local context_c
    local context_wc
    local context_w=''
    local context_enlargeIn = 2
    local context_dictSize = 3
    local context_numBits = 2
    local context_data = ''
    local context_data_val = 0
    local context_data_position = 0
    local ii

    for i=0, length -1,1
    do

        context_c = get_char_from_uncompressed(uncompressedStr, bitsPerChar, i)
        if not context_dictionary[context_c] then
            context_dictionary[context_c] = context_dictSize
            context_dictSize = context_dictSize + 1
            context_dictionaryToCreate[context_c]=1
        end

        context_wc = context_w..context_c

        if context_dictionary[context_wc] then
            context_w = context_wc
        else
            if context_dictionaryToCreate[context_w] then
                if  get_char_value(context_w, bitsPerChar) < 256 then
                    for i=0,context_numBits-1,1
                    do
                        context_data_val = bit.lshift(context_data_val, 1)
                        if context_data_position == bitsPerChar - 1 then
                            context_data_position = 0
                            context_data = context_data..getCharFromInt(context_data_val)
                            context_data_val = 0
                        else
                            context_data_position = context_data_position + 1
                        end
                    end

                    value = get_char_value(context_w, bitsPerChar)

                    for i=0, 8-1, 1
                    do
                        context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
                        if context_data_position == bitsPerChar -1 then
                            context_data_position = 0
                            context_data = context_data..getCharFromInt(context_data_val)
                            context_data_val = 0
                        else
                            context_data_position = context_data_position + 1
                        end
                        value = bit.arshift(value, 1)
                    end

                else
                    value = 1
                    for i=0,context_numBits-1,1
                    do
                        context_data_val = bit.bor(bit.lshift(context_data_val, 1), value)
                        if context_data_position == bitsPerChar - 1 then
                            context_data_position = 0
                            context_data = context_data..getCharFromInt(context_data_val)
                            context_data_val = 0
                        else
                            context_data_position = context_data_position + 1
                        end
                        value = 0
                    end

                     value = get_char_value(context_w, bitsPerChar)
                    for i=0,16-1,1
                    do
                        context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
                        if context_data_position == bitsPerChar -1 then
                            context_data_position = 0
                            context_data = context_data..getCharFromInt(context_data_val)
                            context_data_val = 0
                        else
                            context_data_position = context_data_position + 1
                        end
                        value = bit.arshift(value, 1)
                    end

                end

                context_enlargeIn=context_enlargeIn - 1
                if context_enlargeIn == 0 then
                    context_enlargeIn = 2^context_numBits
                    context_numBits = context_numBits + 1
                end
                context_dictionaryToCreate = table_remove(context_dictionaryToCreate, context_w)

            else
                value = context_dictionary[context_w]
                for i=0,context_numBits-1,1
                do
                    context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
                    if context_data_position == bitsPerChar -1 then
                        context_data_position = 0
                        context_data = context_data..getCharFromInt(context_data_val)
                        context_data_val = 0
                    else
                        context_data_position = context_data_position + 1
                    end
                    value = bit.arshift(value, 1)
                end

            end

            context_enlargeIn = context_enlargeIn - 1
            if context_enlargeIn == 0 then
                context_enlargeIn = 2 ^ context_numBits
                context_numBits = context_numBits + 1
            end
            -- Add wc to the dictionary
            context_dictionary[context_wc] = context_dictSize
            context_dictSize = context_dictSize + 1
            context_w = context_c

      end  
    end

     -- Output the code for w.
    if context_w and context_wc ~= '' then
        if context_dictionaryToCreate[context_w] then
            if get_char_value(context_w, bitsPerChar) < 256 then
                for i=0,context_numBits-1,1
                do
                    context_data_val = bit.lshift(context_data_val, 1)
                    if context_data_position == bitsPerChar - 1 then
                        context_data_position = 0
                        context_data = context_data..getCharFromInt(context_data_val)
                        context_data_val = 0
                    else
                        context_data_position = context_data_position + 1
                    end
                end

                value = get_char_value(context_w , bitsPerChar)

                for i=0, 8-1, 1
                do
                    context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
                    if context_data_position == bitsPerChar -1 then
                        context_data_position = 0
                        context_data = context_data..getCharFromInt(context_data_val)
                        context_data_val = 0
                    else
                        context_data_position = context_data_position + 1
                    end
                    value = bit.arshift(value, 1)
                end
            else
                value = 1
                for i=0,context_numBits-1,1
                do
                    context_data_val = bit.bor(bit.lshift(context_data_val, 1), value)
                    if context_data_position == bitsPerChar - 1 then
                        context_data_position = 0
                        context_data = context_data..getCharFromInt(context_data_val)
                        context_data_val = 0
                    else
                        context_data_position = context_data_position + 1
                    end
                    value = 0
                end

                value = get_char_value(context_w , bitsPerChar)
                for i=0,16-1,1
                do
                    context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
                    if context_data_position == bitsPerChar -1 then
                        context_data_position = 0
                        context_data = context_data..getCharFromInt(context_data_val)
                        context_data_val = 0
                    else
                        context_data_position = context_data_position + 1
                    end
                    value = bit.arshift(value, 1)
                end
            end

            context_enlargeIn=context_enlargeIn - 1
            if context_enlargeIn == 0 then
                context_enlargeIn = 2^context_numBits
                context_numBits = context_numBits + 1
            end
            context_dictionaryToCreate = table_remove(context_dictionaryToCreate, context_w)
        else
            value = context_dictionary[context_w]
            for i=0,context_numBits-1,1
            do
                context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
                if context_data_position == bitsPerChar -1 then
                    context_data_position = 0
                    context_data = context_data..getCharFromInt(context_data_val)
                    context_data_val = 0
                else
                    context_data_position = context_data_position + 1
                end
                value = bit.arshift(value, 1)
            end
        end
        context_enlargeIn = context_enlargeIn - 1
        if context_enlargeIn == 0 then
            context_enlargeIn = 2 ^ context_numBits
            context_numBits = context_numBits + 1
        end
    end

        -- Mark the end of the stream
        value = 2
        for i=0,context_numBits-1,1
        do
            context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
            if context_data_position == bitsPerChar -1 then
                context_data_position = 0
                context_data = context_data..getCharFromInt(context_data_val)
                context_data_val = 0
            else
                context_data_position = context_data_position + 1
            end
            value = bit.arshift(value, 1)
        end

    --Flush the last char
    while 1 == 1
    do
        context_data_val = bit.lshift(context_data_val, 1)
        if context_data_position == bitsPerChar - 1 then
            context_data = context_data..getCharFromInt(context_data_val)
            break
        else
            context_data_position = context_data_position + 1
        end
    end
    
    return context_data
end

DecData = {
    val='',
    postion=0,
    index=0
}

function DecData:new(o, val, position, index)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.val = val or ''
    self.position = position or 0
    self.index = index or 0
   setmetatable(o, self)
    return o
end

function DecData:set_val(val)
    self.val = val
end

function DecData:set_position(position)
    self.position = position
end

function DecData:get_val()
    return self.val
end

function DecData:get_index()
    return self.index
end

function DecData:get_position()
    return self.position
end

function DecData:set_index(index)
    self.index = index
end

function f(i, resetValue)
    if resetValue == 16384 or resetValue == 32768 then
        return utf8.char(i)
    else
        if i >= 256 then
              
        local high = bit.rshift(i, 8)
        local low = bit.band(i, 0xff)
        return  string.char(high)..string.char(low)
        else
       return string.char(i)
        end
    end
      
end

function fc(i)
    return utf8.char(i)
end

function get_char_int(context, bitsPerChar)
    if bitsPerChar == 6 then
        return string.byte(context)
    end
      
    if bitsPerChar == 15 or bitsPerChar == 16 then
        return utf8.byte(context,0 ,1)
    end
end

function def_get_char_value(context, resetValue)
    if resetValue == 16384 or resetValue == 32768 then
        value = utf8.char(utf8.byte(context, 0,  1 ))
    else
        value = string.char(string.byte(context,1))
    end
    return value
end

function get_compressed_length(context, resetValue)

    if resetValue == 16384 or resetValue == 32768 then
        length = utf8.len(context)
    else
        length = string.len(context)
    end
    return length
end

function _decompress(inputStr, resetValue, getNextValue)
 
    local length = get_compressed_length(inputStr, resetValue)
    local dictionary = {}
    local next=0
    local enlargeIn = 4
    local dictSize = 4
    local numBits = 3
    local entry = ''
    local result_index=0
    local result = {}
    local w
    local bits
    local resb
    local maxpower
    local power
    local c
    data = DecData:new(nil, getNextValue(inputStr, 0), resetValue , 1)

    for i = 0, 3-1, 1
    do
        dictionary[i] = f(i, resetValue)
    end

    local bits=0
    local maxpower=2^2
    local power=1

    while power ~= maxpower
    do
        resb = bit.band(data:get_val(), data:get_position())
        data:set_position(bit.rshift(data:get_position(), 1))
        if data:get_position() == 0 then
            data:set_position(resetValue)
            if resetValue ~= 16384 then
                data:set_val(getNextValue(inputStr, data:get_index()))
                data:set_index(data:get_index()+1)
            else
                data:set_val(getNextValue(inputStr, data:get_index()))
                data:set_index(data:get_index()+1)
            end
        end

        if resb > 0 then
            bits = bit.bor(bits, 1*power)
        else
            bits = bit.bor(bits, 0)
        end
        power = bit.lshift(power, 1)
    end

    next = bits
    if next == 0 then
        bits = 0
        -- why not use 256 ??
        maxpower = 2^8
        power = 1
        while power ~= maxpower
        do
            resb = bit.band(data:get_val(), data:get_position())
            data:set_position(bit.rshift(data:get_position(), 1))
            if data:get_position() == 0 then
                data:set_position(resetValue)
                data:set_val(getNextValue(inputStr, data:get_index()))
                data:set_index(data:get_index()+1)
            end

            if resb > 0 then
                bits = bit.bor(bits, 1*power)
            else
                bits = bit.bor(bits, 0)
            end
            power = bit.lshift(power, 1)
        end
        c = f(bits, resetValue)
    elseif next == 1 then
        bits = 0
        maxpower = 2^16
        power = 1
        while power ~= maxpower
        do
            resb = bit.band(data:get_val(), data:get_position())
            data:set_position(bit.rshift(data:get_position(), 1))
            if data:get_position() == 0 then
                data:set_position(resetValue)
                data:set_val(getNextValue(inputStr, data:get_index()))
                data:set_index(data:get_index()+1)
            end

            if resb > 0 then
                bits = bit.bor(bits, 1*power)
            else
                bits = bit.bor(bits, 0)
            end
            power = bit.lshift(power, 1) 
        end
        c = f(bits,resetValue)
    elseif next == 2 then
        return ""
    end

    dictionary[3] = c
    w = c
    -- mock set??
    result[result_index]=w
    result_index=result_index+1


    while 1 == 1
    do
        if data:get_index() > length then
            return ""
        end

        bits = 0
        maxpower = 2^numBits
        power=1

        while power ~= maxpower
        do
            resb = bit.band(data:get_val(), data:get_position())
            data:set_position(bit.rshift(data:get_position(), 1))
            if data:get_position() == 0 then
                data:set_position(resetValue)
                data:set_val(getNextValue(inputStr, data:get_index()))
                data:set_index(data:get_index()+1)
            end
            if resb > 0 then
                bits = bit.bor(bits, 1*power)
            else
                bits = bit.bor(bits, 0)
            end
            power = bit.lshift(power, 1)
        end
        -- TODO: very strange here, c above is as char/string, here further is a int, rename "c" in the switch as "cc"
        local cc = bits
        if cc == 0 then
            bits = 0
            maxpower = 2^8
            power = 1
            while power ~= maxpower
            do
                resb = bit.band(data:get_val(), data:get_position())
                data:set_position(bit.rshift(data:get_position(), 1))
                if data:get_position() == 0 then
                    data:set_position(resetValue)
                    data:set_val(getNextValue(inputStr, data:get_index()))
                    data:set_index(data:get_index()+1)
                end
                if resb > 0 then
                    bits = bit.bor(bits, 1*power)
                else
                    bits = bit.bor(bits, 0)
                end
                power = bit.lshift(power, 1)
            end

            dictionary[dictSize] = f(bits, resetValue)
            dictSize = dictSize + 1
            cc = dictSize - 1
            enlargeIn = enlargeIn -1
        
        elseif cc == 1 then
            bits = 0
            maxpower = 2^16
            power = 1
            while power ~= maxpower
            do
                resb = bit.band(data:get_val(), data:get_position())
                data:set_position(bit.rshift(data:get_position(), 1))
                if data:get_position() == 0 then
                    data:set_position(resetValue)
                    data:set_val(getNextValue(inputStr, data:get_index()))
                    data:set_index(data:get_index()+1)
                end
                if resb > 0 then
                    bits = bit.bor(bits, 1*power)
                else
                    bits = bit.bor(bits, 0)
                end
                power = bit.lshift(power, 1)
            end
            
            dictionary[dictSize] = f(bits, resetValue)
            dictSize = dictSize + 1
            cc = dictSize - 1
            enlargeIn = enlargeIn -1
        
        elseif cc == 2 then
            local decomString=''
            for key,value in pairs(result)
            do
                --print("key is",key, "value=",value)
                decomString=decomString..value
            end
            return decomString
        end
        
        if enlargeIn == 0 then
            enlargeIn = 2 ^ numBits
            numBits = numBits + 1
        end

        if cc < table_length(dictionary) and dictionary[cc] ~= nil then
            entry = dictionary[cc]
        else
            if cc == dictSize then
                entry = w..def_get_char_value(w, resetValue)
            else
                return nil
            end
        end

        result[result_index]=entry
        result_index=result_index+1
        --Add w+entry[0] to the dictionary
        dictionary[dictSize]=w..def_get_char_value(entry, resetValue)
        dictSize = dictSize + 1
        enlargeIn = enlargeIn - 1
        
        w = entry

        if enlargeIn == 0 then
            enlargeIn = 2^numBits
            numBits = numBits + 1
        end
    end
end

return _M