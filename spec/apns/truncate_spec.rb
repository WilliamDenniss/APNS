# encoding: UTF-8

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

require 'spec_helper'

include APNS

describe APNS::Truncate do
  
  STRING_1TO9 = "123456789"
  STRING_QBF = "the quick brown fox jumps over the lazy dog"
  STRING_CHINESE = "中国上海北京南京西安东京水茶可乐咖啡"
  ELLIPSIS = "\u2026"
  LONG_MESSAGE_QBF = "#{STRING_QBF}#{STRING_QBF}#{STRING_QBF}#{STRING_QBF}#{STRING_QBF}#{STRING_QBF}#{STRING_QBF}#{STRING_QBF}#{STRING_QBF}"
  LONG_MESSAGE_CHINESE = "#{STRING_CHINESE}#{STRING_CHINESE}#{STRING_CHINESE}#{STRING_CHINESE}"
  
  describe '#json_byte_length' do
    it "should return the correct ascii-json byte size" do
      # string sizes
      ApnsJSON.apns_json_size("1").should == 1
      ApnsJSON.apns_json_size("12").should == 2
      ApnsJSON.apns_json_size("\u2026").should == 6
      ApnsJSON.apns_json_size("\u{1F511}").should == 12

      # object sizes
      ApnsJSON.apns_json_size(["1"]).should == 1+4
      ApnsJSON.apns_json_size(["12"]).should == 2+4
      ApnsJSON.apns_json_size(["\u2026"]).should == 6+4
      ApnsJSON.apns_json_size(["\u{1F511}"]).should == 12+4
    end
  end
  
  describe '#truncate_string' do

    it "should handle byte-sizes smaller than the ellipsis size" do
      s = Truncate.truncate_string(STRING_1TO9, 4)
      s.should == "1234"
    end

    it "should handle byte-sizes equal to the ellipsis size" do
      s = Truncate.truncate_string(STRING_1TO9, ApnsJSON.apns_json_size(ELLIPSIS))
      s.should == ELLIPSIS
      
      s = Truncate.truncate_string(STRING_CHINESE, ApnsJSON.apns_json_size(ELLIPSIS))
      s.should == ELLIPSIS
    end

    it "should handle byte-sizes euqal to the ellipsis size+1" do
      s = Truncate.truncate_string(STRING_1TO9, ApnsJSON.apns_json_size(ELLIPSIS)+1)
      s.should == "1#{ELLIPSIS}"

      s = Truncate.truncate_string(STRING_CHINESE, ApnsJSON.apns_json_size(ELLIPSIS)+1)
      s.should == ELLIPSIS
    end

    it "should soft truncate stirngs to equal or below requested size #2" do
    
      s = Truncate.truncate_string(STRING_QBF, 8)
      s.length.should <= 8

      s = Truncate.truncate_string(STRING_CHINESE, 8)
      s.length.should <= 8

      s = Truncate.truncate_string(STRING_QBF, 35)
      s.length.should <= 35

      s = Truncate.truncate_string(STRING_CHINESE, 35)
      s.length.should <= 35
    end
    
    it "should hard-truncate to the exact str length" do
      s = Truncate.truncate_string(STRING_QBF, 8, Truncate::TRUNCATE_METHOD_HARD, 0, '.')
      s.length.should == 8
    end

    it "should soft-truncate on word boundaries" do
      s = Truncate.truncate_string(STRING_QBF, 9, Truncate::TRUNCATE_METHOD_SOFT, 10, '.')
      s.should == "the."
    end

    it "shouldn't soft-truncate any more than needed (even if the space lies on the boundary)" do
      s = Truncate.truncate_string(STRING_QBF, 10, Truncate::TRUNCATE_METHOD_SOFT, 10, '.')
      s.should == "the quick."
    end

    it "soft truncate should handle strings with no spaces by reverting to hard-truncate" do
      s = Truncate.truncate_string(STRING_1TO9, 8, Truncate::TRUNCATE_METHOD_SOFT, 10, '.')
      s.length.should == 8
    end

    it "soft truncate should handle unicode strings" do
      s = Truncate.truncate_string(STRING_CHINESE, 20)
      s.should_not == nil
    end

    it "should handle scripts that don't use whitespace and not soft-truncate more than needed" do
      # soft truncate relies on spaces. Some scripts have no spaces and shouldn't be aversely truncated
      soft = Truncate.truncate_string(STRING_CHINESE, 40, Truncate::TRUNCATE_METHOD_SOFT)
      hard = Truncate.truncate_string(STRING_CHINESE, 40, Truncate::TRUNCATE_METHOD_HARD)
      soft.should == hard
    end
  
    it "shouldn't truncate stirngs it doesn't need to" do
      s = APNS::Truncate.truncate_string("123456789", 20)
      s.should == "123456789"

      s = APNS::Truncate.truncate_string("123456789", 9)
      s.should == "123456789"
      
      s = APNS::Truncate.truncate_string(STRING_CHINESE, 200)
      s.should == STRING_CHINESE
    end
    
  end
  
  describe '#truncate_notification' do
    
    it "should truncate notification to size" do
      notification = {:aps => {:alert => LONG_MESSAGE_QBF, :badge => '1', :sound => 'default'}, :server_info => {:type => 'example', :data => 12345, :something => 'blar'}}
      Truncate.truncate_notification(notification)
      ApnsJSON.apns_json(notification).length.should <= 256

      notification = {:aps => {:alert => LONG_MESSAGE_CHINESE, :badge => '1', :sound => 'default'}, :server_info => {:type => 'example', :data => 12345, :something => 'blar'}}
      Truncate.truncate_notification(notification)
      ApnsJSON.apns_json(notification).length.should <= 256
     
      notification = {:aps => {:alert => LONG_MESSAGE_QBF, :badge => '1', :sound => 'default'}, :server_info => {:type => 'example', :data => 12345, :something => 'blar'}}
      Truncate.truncate_notification(notification, true, truncate_mode = Truncate::TRUNCATE_METHOD_HARD)
      ApnsJSON.apns_json(notification).length.should == 256
    end
    
    it "should throw exception if the notification cannot be truncated" do
    
      notification = {:aps => {:alert => LONG_MESSAGE_QBF, :badge => '1', :sound => 'default'}, :server_info => {:type => 'example', :data => 12345, :something => LONG_MESSAGE_QBF, :again => LONG_MESSAGE_QBF}}
      expect { Truncate.truncate_notification(notification) }.to raise_error
    end

    it "should throw exception if the notification structure is invalid" do
    
      notification = {:alert => LONG_MESSAGE_QBF, :badge => '1', :sound => 'default'}
      expect { Truncate.truncate_notification(notification) }.to raise_error (ArgumentError)
      
      notification = [1,2,3]
      expect { Truncate.truncate_notification(notification) }.to raise_error (ArgumentError)

      
    end


    it "shouldn't truncate notification unless needed" do
      notification = {:aps => {:alert => STRING_QBF, :badge => '1', :sound => 'default'}, :server_info => {:type => 'example', :data => 12345, :something => 'blar'}}
      Truncate.truncate_notification(notification)
      notification[:aps][:alert].should == STRING_QBF
    end

  end
  
end