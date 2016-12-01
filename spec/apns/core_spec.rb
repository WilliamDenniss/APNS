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

describe APNS do

  APNS.logging = false
  APNS.byte_limit = 256

  it "should encode unicode to ascii-only json" do
    string = "\u2601"
    json = ApnsJSON.apns_json([string])
    json.should == "[\"\u2601\"]"
  end

  it "should encode 5-byte unicode to JSON in an apple safe manner" do
    string = "\u{1F511}"
    json = ApnsJSON.apns_json([string])
    json.should == "[\"\u{1F511}\"]"
  end
  
  it "should return JSON escaped" do
    n = {:aps => {:alert => "\u2601Hello iPhone", :badge => 3, :sound => 'awesome.caf'}}
    json = ApnsJSON.apns_json(n)
    json.should  == "{\"aps\":{\"alert\":\"\u2601Hello iPhone\",\"badge\":3,\"sound\":\"awesome.caf\"}}"
  end
  
  it "should throw exception if payload is too big" do
    # too big with alert
    notification = {:aps => {:alert => "#{LONG_MESSAGE_QBF}#{LONG_MESSAGE_QBF}", :badge => '1', :sound => 'default'}, :server_info => {:type => 'example', :data => 12345, :something => LONG_MESSAGE_QBF, :again => LONG_MESSAGE_QBF}}
    expect { APNS.packaged_notification("12345678901234567890123456789012",  notification, 1, Time.now + 14400) }.to raise_error(APNSException)
  
    # too big without alert
    notification = notification = {:aps => {:badge => '1', :sound => 'default'}, :server_info => {:type => 'example', :data => 12345, :something => LONG_MESSAGE_QBF, :again => LONG_MESSAGE_QBF}}
    expect { APNS.packaged_notification("12345678901234567890123456789012",  notification, 1, Time.now + 14400) }.to raise_error(APNSException)
  end
  
  describe '#packaged_message' do

    it "should return JSON with notification information" do
      n = APNS.packaged_message({:aps => {:alert => 'Hello iPhone', :badge => 3, :sound => 'awesome.caf'}})
      n.should  == "{\"aps\":{\"alert\":\"Hello iPhone\",\"badge\":3,\"sound\":\"awesome.caf\"}}"
    end

    it "should not include keys that are empty in the JSON" do
      n = APNS.packaged_message({:aps => {:badge => 3}})
      n.should == "{\"aps\":{\"badge\":3}}"
    end

  end

  describe '#packaged_token' do
    it "should package the token" do
      n = APNS.packaged_token('<5b51030d d5bad758 fbad5004 bad35c31 e4e0f550 f77f20d4 f737bf8d 3d5524c6>')
      Base64.encode64(n).should == "W1EDDdW611j7rVAEutNcMeTg9VD3fyDU9ze/jT1VJMY=\n"
    end
  end

  describe '#packaged_notification' do
    it "should package the notification" do
      n = APNS.packaged_notification('device_token', {:aps => {:alert => 'Hello iPhone', :badge => 3, :sound => 'awesome.caf'}}, 1, 1367064263)
      Base64.encode64(n).should == "AQAAAAFRe77HACDe8s79hOcAQHsiYXBzIjp7ImFsZXJ0IjoiSGVsbG8gaVBo\nb25lIiwiYmFkZ2UiOjMsInNvdW5kIjoiYXdlc29tZS5jYWYifX0=\n"
    end
  end
   
end