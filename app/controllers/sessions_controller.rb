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


class SessionsController < ApplicationController #:nodoc:

  skip_before_filter :authenticate

  def show
  end

  def create
    username, password = params.values_at(:username, :password)
    if person = Person.authenticate(username, password)
      redirect = session[:return_url] || root_url
      reset_session # prevent session fixation
      session[:authenticated] = person.id
      redirect_to redirect, :status=>:see_other 
    else
      flash[:error] = t('sessions.errors.nomatch')  unless username.blank?
      redirect_to session_url, :status=>:see_other
    end
  end

  def destroy
    reset_session
    redirect_to root_url, :status=>:see_other
  end

end
