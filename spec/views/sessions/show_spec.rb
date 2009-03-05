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

describe '/sessions/shows' do

  it 'should render login form' do
    render '/sessions/show'
    response.should have_tag('form.login') do
      with_tag 'form[method=post][action=?]', session_url do
        with_tag 'fieldset' do
          with_tag 'input[name=login][type=text]'
          with_tag 'input[name=password][type=password]'
          with_tag 'input[type=submit][value=Login]'
          without_tag('p.error')
        end
      end
    end
  end

  it 'should render flash[:error] inside login box' do
    flash[:error] = 'Error message'
    render '/sessions/show'
    response.should have_tag('form.login fieldset') do
      with_tag 'p.error', 'Error message'
    end
  end

  it 'should not render empty container without flash[:error]' do
    render '/sessions/show'
    response.should have_tag('form.login fieldset') do
      without_tag('p.error')
    end
  end

end
