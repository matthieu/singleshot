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


require 'faker'

namespace 'db' do
  desc 'Populate the database with mock values'
  task 'populate'=>['environment', 'create', 'migrate'] do
    require Rails.root + 'db/populate'
    Populate.down
    Populate.up
  end

  task 'annotate'=>['environment'] do
    require 'annotate/annotate_models'
    AnnotateModels.do_annotations :position=>:before
  end
end

namespace 'routes' do
  task 'annotate' do
    require 'annotate/annotate_routes'
    AnnotateRoutes.do_annotate
  end
end
