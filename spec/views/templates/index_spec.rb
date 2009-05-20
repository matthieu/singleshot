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


require File.dirname(__FILE__) + '/../helpers'

describe '/templates/index' do

  describe '(regular)' do
    before do
      @templates = Array.new(5) { |i| Template.make :id=>i + 1, :title=>"Template #{i}", :description=>"Used for #{i} and stuff",
                                                    :creator=>Person.creator, :created_at=>Time.parse('2009-04-28 09:30Z') }
      template.assigns[:templates] = @templates
      render 'templates/index'
    end

    it('should show list of templates')             { should have_tag('ol.templates>li.template', 5) }
    it('should show title of each template')        { @templates.each { |t| should have_tag("li#template_#{t.id}>h2.title", t.title) } }
    it('should link to template')                   { @templates.each { |t| should have_tag("li#template_#{t.id}>.title>a[href]" ) } }
    it('should show description of each template')  { @templates.each { |t| should have_tag("li#template_#{t.id}>div.description", t.description) } }
    it('should show template creation date/time')   { should have_tag('li.template>p.meta>span.published', 'April 28, 2009 09:30') }
    it('should link to template creator')           { should have_tag('li.template>p.meta>a', 'Creator') }
  end

  describe '(without creator)' do
    before do
      @templates = Array.new(5) { |i| Template.make :creator=>nil, :created_at=>Time.parse('2009-04-28 09:30Z') }
      template.assigns[:templates] = @templates
      render 'templates/index'
    end

    it('should show template creation date/time')   { should have_tag('li.template>p.meta>.published', 'April 28, 2009 09:30') }
    it('should not link to anyone')                 { should_not have_tag('li.template .meta a') }
  end
end
