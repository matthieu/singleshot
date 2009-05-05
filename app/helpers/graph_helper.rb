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
module GraphHelper

  def graph(data)
    max = data.map { |x, y| y }.max.to_f
    list = data.map { |x, y, title|
      title ||= "#{x}: #{y}"
      bar = content_tag('span', content_tag('span', y, :class=>'value'), :class=>'bar', :style=>"height:#{(y / max) * 100}%")
      legend = content_tag('span', x, :class=>'legend')
      content_tag 'li', bar + legend, :title=>title
    }
    content_tag 'ol', list, :class=>'bar-graph'
  end

end
