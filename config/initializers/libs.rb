require 'rest-open-uri'
require 'acts_as_ferret'
require File.join(Rails.root, 'lib/patches')
require File.join(Rails.root, 'lib/extensions')
require File.join(Rails.root, 'lib/singleshot')

require 'sparklines'
module ApplicationHelper
  include SparklinesHelper
end
