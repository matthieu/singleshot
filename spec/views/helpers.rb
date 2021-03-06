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


require File.dirname(__FILE__) + '/../spec_helper'


module Spec::Helpers #:nodoc:
  # These helper methods and matchers are available only when speccing views.
  module Views
  end
end

module HTML
  class Text
    alias :text :to_s
  end
  class Tag
    def text
      children.map(&:text).join
    end
  end
end

Spec::Runner.configure { |config| config.include Spec::Helpers::Views, :type=>:view }
