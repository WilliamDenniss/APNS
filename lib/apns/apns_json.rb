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
  require 'json'

    class ApnsJSON
    
      # generates JSON in a format acceptable to the APNS service (which is a subset of the JSON standard)
      def self.apns_json(object)

        JSON.generate(object, :ascii_only => true)
      end

      # calculates the byte-length of an object when encoded with APNS friendly JSON encoding
      # if a string is passed, the byte-size is calculated as if it were in an object structure
      def self.apns_json_size(object)

        if object.is_a?(Hash) || object.is_a?(Array)
          return apns_json(object).length
        else object.is_a?(String)
          # wraps string in an array but discounts the extra chars
          return apns_json([object]).length - 4
        end
      end
    end
end
