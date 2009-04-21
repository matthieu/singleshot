class TaskPresenter < Presenter::Base

  # Returns authenticated user. Use this to determine which attributes to update/show.
  def authenticated
    controller.send(:authenticated)
  end

  def update!(attrs)
    if webhooks = attrs.delete('webhooks')
      webhooks = [webhooks.first] unless Array === webhooks
      attrs['webhooks'] = webhooks.map { |attr| Webhook.new attr }
    end
    # TODO: should take over access control validation, no?
    task.modified_by = authenticated
    task.update_attributes! attrs
  end

  def to_hash
    super do |hash|
      Stakeholder::SINGULAR_ROLES.each do |role|
        if person = hash[role]
          hash[role] = person['identity']
        end
      end
      Stakeholder::PLURAL_ROLES.each do |role|
        role = role.pluralize
        if people = hash[role]
          hash[role] = people.map { |person| person['identity'] }
        end
      end
      hash['links'] = [ link_to('self', href) ]
      hash['actions'] = []
      hash['actions'] << action('claim', url_for(:id=>task, 'task[owner]'=>authenticated)) if authenticated.can_claim?(task)
      hash['actions'] << action('complete', url_for(:id=>task, 'task[status]'=>'completed')) if authenticated.can_complete?(task)
      hash['actions'] << action('cancel', url_for(:id=>task, 'task[status]'=>'cancelled')) if authenticated.can_cancel?(task)
    end
  end

end
