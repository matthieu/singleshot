class TaskPresenter < Presenter::Base

  def authenticated
    controller.send(:authenticated)
  end

  def to_hash
    super do |hash|
      hash['links'] = [ link_to('self', href) ]
      hash['actions'] = []
      hash['actions'] << action('claim', url_for(:id=>task, :owner=>'assaf')) if authenticated.can_claim?(task)
      hash['actions'] << action('complete', url_for(:id=>task, :status=>'completed')) if authenticated.can_complete?(task)
      hash['actions'] << action('cancel', url_for(:id=>task, :status=>'cancelled')) if authenticated.can_cancel?(task)
    end
  end

end
