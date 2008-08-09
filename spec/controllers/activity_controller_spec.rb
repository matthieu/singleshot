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


require File.dirname(__FILE__) + '/../spec_helper'


describe ActivityController do

  describe 'index' do

    it 'should map to /activity' do
      route_for(:controller=>'activity', :action=>'index').should eql('/activity')
    end

    it 'should require authentication' do
      get 'index'
      response.should redirect_to(session_url)
    end

    it 'should return root element activities' do
      authenticate do
        get 'index', :format=>Mime::XML
        p response.body
      end
    end

  end

end
