# Singleshot  Copyright (C) 2008-2009  Intalio, Inc
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


require File.dirname(__FILE__) + '/helpers'


# == Schema Information
# Schema version: 20090206215123
#
# Table name: webhooks
#
#  id          :integer         not null, primary key
#  task_id     :integer         not null
#  event       :string(255)     not null
#  url         :string(255)     not null
#  http_method :string(255)     not null
#  enctype     :string(255)     not null
#  hmac_key    :string(255)
describe Webhook do
  subject { Webhook.make }

  should_belong_to :task

  should_have_attribute :event
  should_have_column :event, :type=>:string
  should_validate_presence_of :event

  should_have_attribute :url
  should_have_column :url, :type=>:string
  should_validate_presence_of :url
  should_validate_url

  should_have_attribute :http_method
  should_have_column :http_method, :type=>:string
  should_validate_presence_of :http_method
  it('should have http_method=post by default') { subject.http_method.should == 'post' }
  should_allow_mass_assignment_of :http_method

  should_have_attribute :enctype
  should_have_column :enctype, :type=>:string
  should_validate_presence_of :enctype
  it('should have enctype=url-encoded by default') { subject.enctype.should == Mime::URL_ENCODED_FORM.to_s }

  should_have_attribute :hmac_key
  should_have_column :hmac_key, :type=>:string
  should_not_validate_presence_of :hmac_key

  should_allow_mass_assignment_of :event, :url, :http_method, :enctype, :hmac_key

  describe '.send_notification' do
    before do
      @request = {}
      Net::HTTP.should_receive(:start).with('example.com', 80).and_yield(http = mock(Net::HTTP)).and_return do |host, port|
        @request[:url] = "http://#{host}:#{port}#{@request[:url]}" # and_yield => http.post => here
      end
      http.should_receive(:post) { |path, data, headers| @request.update(:url=>path, :body=>data).update(headers) }
      @task = Task.make :id=>78
      @webhook = Webhook.make :task=>@task
    end
    subject { @webhook.send_notification ; @request }

    it('should send notification to webhook URL')    { subject[:url].should == 'http://example.com:80/completed' }

    describe 'XML' do
      before { @webhook.update_attributes! :enctype=>Mime::XML }
      it('should use content type application/xml')  { subject['Content-Type'].should == 'application/xml' }
      it('should send XML representation')           { Hash.from_xml(subject[:body]).should include('task') }
    end

    describe 'JSON' do
      before { @webhook.update_attributes! :enctype=>Mime::JSON }
      it('should use content type application/json') { subject['Content-Type'].should == 'application/json'}
      it('should send JSON representation')          { ActiveSupport::JSON.decode(subject[:body]).should include('task') }
    end

    describe 'URL-encoded' do
      before { @webhook.update_attributes! :enctype=>Mime::URL_ENCODED_FORM }
      it('should use content type URL encoded')      { subject['Content-Type'].should == 'application/x-www-form-urlencoded' }
      it('should send ID and URL')                   { CGI::parse(subject[:body]).should == { 'id'=>[@task.id.to_s],
                                                                                              'url'=>['http://example.com/tasks/78'] } }
    end
  end
end
