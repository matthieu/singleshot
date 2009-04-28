class TemplatePresenter < Presenter::Base
  
  # Returns authenticated user. Use this to determine which attributes to update/show.
  def authenticated
    controller.send(:authenticated)
  end

  def update!(attrs)
    if webhooks = attrs.delete('webhooks')
      webhooks = [webhooks.first] unless Array === webhooks
      attrs['webhooks'] = webhooks.map { |attr| Webhook.new attr }
    end
    template.modified_by = authenticated
    template.update_attributes! attrs
  end

end
