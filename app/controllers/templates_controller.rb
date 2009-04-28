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


class TemplatesController < ApplicationController #:nodoc:

  respond_to :html, :json, :xml

  def show
    respond_to do |wants|
      wants.html do
        if instance.form && !instance.form.url.blank?
          @iframe_url = instance.form.url
        elsif instance.form && !instance.form.html.blank?
          @iframe_url = form_url(instance)
        end
        render :layout=>'single'
      end
    end
  end

  def create
    @instance = authenticated.templates.new
    presenter.update! params['template']
    respond_to do |wants|
      wants.html { redirect_to templates_url, :status=>:see_other }
      wants.any  { respond_with presenter, :status=>:created, :location=>instance }
    end
  end
  
  def update
    if instance.can_update?(authenticated)
      presenter.update! params['template']
      respond_to do |wants|
        wants.html { redirect_to template_url(instance) }
        wants.any  { respond_with presenter }
      end 
    else
      render :text=>'You are not authorized to change this task', :status=>:unauthorized
    end
  end

  def destroy
    if instance.can_destroy?(authenticated)
      instance.destroy
      respond_to do |wants|
        wants.html { redirect_to templates_url }
        wants.any  { head :ok }
      end 
    else
      render :text=>'You are not authorized to change this task', :status=>:unauthorized
    end
  end

protected

  helper_method :instance
  def instance
    @instance ||= authenticated.templates.find(params['id'])
  end

  def presenter
    @presenter ||= presenting(instance)
  end
end
