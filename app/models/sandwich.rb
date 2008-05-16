class Sandwich < Singleshot::Task

  data_fields :bread, :spread, :toppings

  def toppings
    (data && data['toppings']) || ''
  end

  validates_presence_of :bread, :on=>:complete, :message=>'Spread without a bread?', :if=>:spread
  validates_length_of   :toppings, :on=>:complete, :minimum=>1, :message=>'Your sandwich is short on toppings!'

end
