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


Given /^the template$/ do |yaml|
  args = YAML.load(yaml)
  form = args.delete('form')
  webhooks = args.delete('webhooks')
  Template.create! args do |record|
    record.build_form form if form
    webhooks.each do |webhook|
      record.webhooks.build webhook
    end if webhooks
  end
end

Given /^(\S*) (\S*) the template "([^\"]*)"$/ do |name, change, title|
  template = Person.identify(name).templates.find(:first, :conditions=>{'title'=>title}).reload
  case change
  when 'enables'
    template.update_attributes! :status=>'enabled'
  when 'disables'
    template.update_attributes! :status=>'disabled'
  when 'changes'
    template.update_attributes! :priority=>1
  when 'deletes'
    template.destroy
  else fail "Dont know what to do with #{change}"
  end
end
