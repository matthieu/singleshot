# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.


class SessionsController < ApplicationController #:nodoc:

  skip_before_filter :authenticate

  def show
  end

  def create
    login, password = params.values_at(:login, :password)
    if person = Person.authenticate(login, password)
      session[:person_id] = person.id
      redirect_to session.delete(:return_url) || root_url, :status=>:see_other 
    else
      flash[:error] = 'No account with this login and password.' unless login.blank?
      redirect_to session_url, :status=>:see_other
    end
  end

  def destroy
    reset_session
    redirect_to root_url, :status=>:see_other
  end

end
