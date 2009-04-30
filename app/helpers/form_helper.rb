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
module FormHelper

  # Wraps form_tag to work properly for either task or template.
  def form(task_or_template, &block)
    if task_or_template.type == 'Template'
      form_tag forms_url(:id=>task_or_template), :method=>:post, :id=>'task', :class=>'enabled', &block
    else
      form_tag form_url(task_or_template), :method=>:put, :id=>'task', :class=>authenticated.can_complete?(task_or_template) ? 'enabled' : 'disabled', &block
    end
  end

end
