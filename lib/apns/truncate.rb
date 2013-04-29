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
  
    # forces a notification to fit within Apple's payload limits by truncating the message as required
    def self.truncate_notification(notification, clean_whitespace = true, truncate_mode = TRUNCATE_METHOD_SOFT, truncate_soft_max_chopped = 10, ellipsis = "\u2026")
      
      raise ArgumentError, "notification is not a hash" unless notification.is_a?(Hash)
      raise ArgumentError, "notification hash should contain :aps key" unless notification[:aps]
      
      return notification if !notification[:aps][:alert] || notification[:aps][:alert] == ""
      
      # cleans up whitespace
      notification[:aps][:alert].gsub!(/([\s])+/, " ") if clean_whitespace
                
      # wd: trims the notification payload to fit in 255 bytes
      if ApnsJSON.apns_json_size(notification) > NOTIFICATION_MAX_BYTE_SIZE

        oversize_by = ApnsJSON.apns_json_size(notification) - NOTIFICATION_MAX_BYTE_SIZE
        message_target_byte_size = ApnsJSON.apns_json_size(notification[:aps][:alert]) - oversize_by

        if message_target_byte_size < 0
          raise TrucateException, "notification does not fit within 256 byte limit even by if the message was completely truncated"
        end
        if message_target_byte_size == 0
          raise TrucateException, "notification would only fit within 256 byte limit by completely truncating the message which changes the presentation in iOS"
        end

        notification[:aps][:alert] = truncate_string(notification[:aps][:alert], message_target_byte_size, truncate_mode, truncate_soft_max_chopped, ellipsis)
      end
      
      return notification
    end
    
    # truncates a string to a given byte size
    def self.truncate_string(input_string, target_byte_size, truncate_mode = TRUNCATE_METHOD_SOFT, truncate_soft_max_chopped = 10, ellipsis = "\u2026", truncate_soft_regex = /\s/)

      raise ArgumentError, "Cannot truncate string to a negative number" if target_byte_size < 0 
      
      return input_string if ApnsJSON.apns_json_size(input_string) <= target_byte_size
      
      # if the target size is below the size of the ellipsis, reverts to a hard-truncate with no ellipsis
      if target_byte_size < ApnsJSON.apns_json_size(ellipsis)
        truncate_mode = TRUNCATE_METHOD_HARD
        ellipsis = ''
      end

      # reduces target-size by the ellipsis size
      target_byte_size -= ApnsJSON.apns_json_size(ellipsis)

      # starts with a string length equal to the target number bytes (which for an ASCII-only string is the final string)
      string = input_string[0,target_byte_size]
      
      # chops off characters one at a time until the byte-size is within our target size, to handle variable-byte char strings
      while ApnsJSON.apns_json_size(string) > target_byte_size
        string = string[0,string.length-1]
      end
      
      # further truncates string on whitespace boundaries
      if truncate_mode == TRUNCATE_METHOD_SOFT
      
        string = input_string[0, string.length+1] # elongates string by 1 character in case it happens to be whitespace
        trim_to_index = string.rindex(/\s/) # sets trim index to be last whitespace character
        if !trim_to_index || (string.length - trim_to_index) > truncate_soft_max_chopped
          trim_to_index = string.length-1 # cancels soft-truncate if no whitespace, or too much would be chopped
        end
        
        string = string[0,trim_to_index]
      end

      string = '' if string.nil?  # if string is nil, it was entirely truncated
      
      return string + ellipsis
    end
    
  end

end