# Copyright (c) 2013 William Denniss
#  
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#  
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#  
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

module APNS
  class Truncate

    TRUNCATE_METHOD_SOFT = 'soft'
    TRUNCATE_METHOD_HARD = 'hard'
  
    NOTIFICATION_MAX_BYTE_SIZE = 256
  
    # calculates the byte-length of an object when encoded with APNS friendly JSON encoding (i.e. ascii-only)
    def self.json_byte_length(object)
      if object.is_a?(Hash) || object.is_a?(Array)
        return JSON.generate(object, :ascii_only => true).length
      else object.is_a?(String)
        # wraps string in an array but discounts the extra chars
        return JSON.generate([object], :ascii_only => true).length - 4
      end
    end
    
    # forces a notification to fit within Apple's payload limits by truncating the message as required
    def self.truncate_notification(notification, clean_whitespace = true, truncate_mode = TRUNCATE_METHOD_SOFT, truncate_soft_max_chopped = 10)
    
      return notification if !notification[:aps][:alert] || notification[:aps][:alert] == ""
      
      # cleans up whitespace
      notification[:aps][:alert].gsub!(/([\s])+/, " ") if clean_whitespace
                
      # wd: trims the notification payload to fit in 255 bytes
      if json_byte_length(notification) > NOTIFICATION_MAX_BYTE_SIZE

        oversize_by = json_byte_length(notification) - NOTIFICATION_MAX_BYTE_SIZE
        message_target_byte_size = json_byte_length(notification[:aps][:alert]) - oversize_by

        notification[:aps][:alert] = truncate_string(notification[:aps][:alert], message_target_byte_size, truncate_mode, truncate_soft_max_chopped)
      end
      
      return notification
    end
    
    # truncates a string to a given byte size
    def self.truncate_string(string, target_byte_size, truncate_mode = TRUNCATE_METHOD_SOFT, truncate_soft_max_chopped = 10, ellipsis = "\u2026", truncate_soft_regex = /\s/)
    
      return string if json_byte_length(string) <= target_byte_size
      
      target_byte_size -= json_byte_length(ellipsis)

      if truncate_mode == TRUNCATE_METHOD_SOFT
        target_byte_size += 1 # allows one extra byte in case the string ended on a space, will be chopped off later
      end

      # starts with a string length equal to the target number bytes (which for an ASCII-only string is the final string)
      string = string[0,target_byte_size]
      # chops off characters one at a time until the byte-size is within our target size, to handle multi-byte char strings
      while json_byte_length(string) > target_byte_size
        string = string[0,string.length-1]
      end
      
      if truncate_mode == TRUNCATE_METHOD_SOFT
        # trims to before last space character for a nicer result, or length less one byte to match if no strings or the chopped chars exceed our threshold (the latter threshold should prevent scripts that don't use spaces getting too truncated)
        trim_index = string.rindex(/\s/)
        trim_index = string.length-1 if !trim_index || string.length - trim_index > truncate_soft_max_chopped
        string = string[0,trim_index]
      end
      
      return string + ellipsis
    end
    
  end
end