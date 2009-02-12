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


module ActivityHelper

  EXPANDED_ACTIVITY_NAMES = { 'owner'=>'is owner of' }

  def activity_as_text(person, activities, task)
    sentence = activities.map { |activity| EXPANDED_ACTIVITY_NAMES[activity.name] || activity.name }.to_sentence
    person ? "#{person.fullname} #{sentence} #{task.title}" : "#{sentence.capitalize} #{task.title}"
  end

  def activity_as_html(person, activities, task, options = {})
    sentence = activities.map { |activity| EXPANDED_ACTIVITY_NAMES[activity.name] || activity.name }.to_sentence
    title = link_to(task.title, task_url(task), options[:task])
    person ? "#{link_to_person person, :rel=>options[:person]} #{sentence} #{title}" : "#{sentence.capitalize} #{title}"
  end

end
