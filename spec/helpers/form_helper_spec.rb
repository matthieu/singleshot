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


require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FormHelper do
  include FormHelper

  describe 'form' do

    describe '(with active task)' do
      before  { stub!(:authenticated).and_return { Person.owner } }
      subject { form Task.make(:id=>58, :owner=>Person.owner) }

      it('should be form to update existing task') do
        subject.should have_tag('form#task.enabled[method=post][action=?]', form_url(58)) do
          with_tag 'input[name=_method][value=put]'
        end
      end
    end

    describe '(with view-only task)' do
      before {  stub!(:authenticated).and_return { Person.supervisor } }
      subject { form Task.make(:id=>58) }

      it('should be form to update existing task') do
        subject.should have_tag('form#task.disabled[method=post][action=?]', form_url(58)) do
          with_tag 'input[name=_method][value=put]'
        end
      end
    end
    describe '(with template)' do
      subject { form Template.make(:id=>56) }

      it('should be form to create new task') do
        subject.should have_tag('form#task.enabled[method=post][action=?]', forms_url(:id=>56)) do
          with_tag 'input', 0
        end
      end
    end
  end

end
