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


class ActivitiesController < ApplicationController #:nodoc:

  respond_to :html, :json, :xml, :atom, :ics

  def index
    @title = t('activity.index.title')
    @subtitle = t('activity.index.subtitle')
    @activities = Activity.visible_to(authenticated).paginate(:page=>params['page'], :per_page=>50)
    @datapoints = lambda { Activity.visible_to(authenticated).since(Date.today - 1.month).datapoints.map(&:last) }
    respond_with presenting(:activities, @activities)
  end

end
