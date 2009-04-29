class TaskPresenter < Presenter::Base

  # Returns authenticated user. Use this to determine which attributes to update/show.
  def authenticated
    controller.send(:authenticated)
  end

  def update!(attrs)
    task.singular_roles.each do |role|
      attrs[role] = Person.identify(attrs[role]) if attrs[role]
    end
    if webhooks = attrs.delete('webhooks')
      webhooks = [webhooks.first] unless Array === webhooks
      attrs['webhooks'] = webhooks.map { |attr| Webhook.new attr }
    end
    task.modified_by = authenticated
    task.update_attributes! attrs
  end

  def to_hash
    super do |hash|
      task.singular_roles.each do |role|
        if person = task.send(role)
          hash[role] = person.to_param
        end
      end
      task.plural_roles.each do |role|
        role = role.pluralize
        if people = task.send(role)
          hash[role] = people.map { |person| { role=>person.to_param } }
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
