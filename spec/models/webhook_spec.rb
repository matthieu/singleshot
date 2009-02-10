# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.


require File.dirname(__FILE__) + '/helpers'


# == Schema Information
# Schema version: 20090206215123
#
# Table name: webhooks
#
#  id         :integer         not null, primary key
#  task_id    :integer         not null
#  event      :string(255)     not null
#  url        :string(255)     not null
#  method     :string(255)     default("post"), not null
#  enctype    :string(255)
#  secret     :string(255)
#  created_at :datetime
#  updated_at :datetime
#


describe Webhook do
  subject { Webhook.make }

  it { should belong_to(:task, Task) }

  it { should have_attribute(:event, :string, :null=>false) }
  it { should validate_presence_of(:event) }

  it { should have_attribute(:url, :string, :null=>false) }
  it { should validate_presence_of(:url) }

  it { should have_attribute(:method, :string, :null=>false) }
  it { should validate_presence_of(:method) }
  it('should have method=post by default') { subject.method.should == 'post' }

  it { should have_attribute(:enctype, :string, :null=>false) }
  it { should validate_presence_of(:enctype) }
  it('should have enctype=url-encoded by default') { subject.enctype.should == Mime::URL_ENCODED_FORM.to_s }

  it { should have_attribute(:hmac_key, :string) }
  it { should_not validate_presence_of(:hmac_key) }

end
