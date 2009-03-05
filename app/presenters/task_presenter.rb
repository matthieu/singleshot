class TaskPresenter < Presenter::Base

  # Returns authenticated user. Use this to determine which attributes to update/show.
  def authenticated
    controller.send(:authenticated)
  end

  def update!(attrs)
    if stakeholders = attrs.delete('stakeholders')
      attrs['stakeholders'] = Array(stakeholders).map { |sh| Stakeholder.new :role=>sh['role'], :person=>Person.identify(sh['person']) }
    end
    task.modified_by = authenticated
    task.update_attributes! attrs
  end

  def to_hash
    super do |hash|
      hash['links'] = [ link_to('self', href) ]
      hash['actions'] = []
      hash['actions'] << action('claim', url_for(:id=>task, :owner=>authenticated)) if authenticated.can_claim?(task)
      hash['actions'] << action('complete', url_for(:id=>task, :status=>'completed')) if authenticated.can_complete?(task)
      hash['actions'] << action('cancel', url_for(:id=>task, :status=>'cancelled')) if authenticated.can_cancel?(task)
    end
  end

end
