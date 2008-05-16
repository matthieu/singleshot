require File.dirname(__FILE__) + '/../../spec_helper'

describe '/sessions' do

  it 'should render login form' do
    render '/sessions/show'
    response.should have_tag('form.login') do
      with_tag 'form[method=post][action=?]', session_url do
        with_tag 'fieldset' do
          with_tag 'input[name=login][type=text]'
          with_tag 'input[name=password][type=password]'
          with_tag 'button', 'Login'
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
