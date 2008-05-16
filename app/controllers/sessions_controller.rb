class SessionsController < ApplicationController
  skip_before_filter :authenticate

  def show
    flash.keep(:return_to)
  end

  def create
    login, password = params.values_at(:login, :password)
    if person = Person.authenticate(login, password)
      session[:person_id] = person.id
      redirect_to flash[:return_to] || root_url, :status=>:see_other 
    else
      flash.keep(:return_to)
      flash[:error] = 'No account with this login and password.' unless login.blank?
      redirect_to session_url, :status=>:see_other
    end
  end

  def destroy
    reset_session
    redirect_to root_url, :status=>:see_other
  end

end
