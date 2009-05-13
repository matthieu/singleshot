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


# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # Returns Person object for currently authenticated user.
  attr_reader :authenticated

  # Used for populating the sidebar template.
  Sidebar = Struct.new(:activities, :templates)

  # Renders bar sparkline. First argument are data points, second argument are options:
  # * title -- Title to show when hovering over element
  def bar_sparkline(datum, options = {})
    content_tag('div', content_tag('span', datum.join(','), :title=>options[:title]),
                :class=>'sparkline bar right-shifted', :style=>'display:none')
  end

  # Returns a link to a person using their full name as the link text and site URL
  # (or profile, if unspecified) as the reference.
  def link_to_person(person, options = {})
    options[:class] = "#{options[:class]} fn url"
    person.url ? link_to(h(person.fullname), person.url, options.merge(:title=>t('person.link.title', :fullname=>person.fullname))) :
      content_tag('span', fullname, options)
  end

  def rich_text(content)
    auto_link(sanitize(simple_format(content)))
  end


  def relative_date(date)
    date = date.to_date
    today = Date.current
    if date == today
      'today'
    elsif date == today - 1.day
      'yesterday'
    elsif date > today && date < today.next_week
      date.strftime('%A')
    elsif date.year == today.year
      date.strftime('%B %d')
    else
      date.strftime('%B %d, %Y')
    end
  end

  def abbr_time(time, text, options = {})
    content_tag 'abbr', text, options.merge(:title=>time.iso8601)
  end

  def group_by_dates(activities, attr = :updated_at)
    activities.inject([]) do |groups, activity|
      date, today = activity.send(attr).to_date, Date.current
      group = if date == today
        'today'
      elsif date == today.yesterday
        'yesterday'
      elsif date.cweek == today.cweek
        date.strftime('%A')
      elsif date.year == today.year
        date.strftime('%b %d')
      else
        date.strftime('%b %d, %Y')
      end
      previous = groups.last
      if previous && previous.first == group
        previous.last << activity
        groups
      else
        groups.push([group, [activity]])
      end
    end
  end

end
