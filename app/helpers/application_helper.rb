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

  # Returns a link to a person using their full name as the link text and site URL
  # (or profile, if unspecified) as the reference.
  def link_to_person(person, options = {})
    options[:class] = "#{options[:class]} fn url"
    person.url ? link_to(h(person.fullname), person.url, options.merge(:title=>"See #{person.fullname}'s profile")) :
      content_tag('span', fullname, options)
  end

  # Returns Person object for currently authenticated user.
  attr_reader :authenticated

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

  def age(time, ago = true)
    text = case age = Time.current - time
    when 0...2.minute
      '1 minute'
    when 2.minute...1.hour
      '%d minutes' % (age / 1.minute)
    when 1.hour...2.hour
      '1 hour'
    when 2.hour...1.day
      '%d hours' % (age / 1.hour)
    when 1.day...2.day
      '1 day'
    when 2.day...1.month
      '%d days' % (age / 1.day)
    when 1.month...2.month
      '1 month'
    else
      '%d months' % (age / 1.month) if age > 0
    end
    text && ago ? "#{text} ago" : text
  end

  def relative_time(time)
    case age = Time.current - time
    when 0...2.minute
      'this minute'
    when 2.minute...1.hour
      '%d minutes ago' % (age / 1.minute)
    when 1.hour...2.hour
      'this hour'
    when 2.hour...1.day
      '%d hours ago' % (age / 1.hour)
    when 1.day...2.day
      'yesterday'
    when 2.day...1.month
      '%d days ago' % (age / 1.day)
    when 1.month...2.month
      'about 1 month'
    else
      '%d months ago' % (age / 1.month) if age > 0
    end
  end

  def abbr_date(date, text, options = {})
    content_tag 'abbr', text, options.merge(:title=>date.to_date.strftime('%Y-%m-%d'))
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
