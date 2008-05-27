class Sandwich

  def self.human_attribute_name(name)
    name.titleize
  end

  def initialize(other = nil)
    ['bread', 'spread', 'toppings'].each do |name|
      send "#{name}=", other.send(name)
    end if other
  end

  attr_accessor :bread, :spread, :toppings

  def errors
    @errors ||= ActiveRecord::Errors.new(self)
  end

  def toppings
    @toppings = (@toppings || []).reject(&:empty?).uniq
  end

  def update_attributes(attributes)
    ['bread', 'spread', 'toppings'].each do |name|
      send "#{name}=", attributes[name]
    end
  end

  def save
    validate
    errors.empty?
  end

  private

  def validate
    errors.add :bread, 'Spread without a bread?' if !spread.empty? && bread.empty?
    errors.add :toppings, 'Your sandwich is short on toppings!' if toppings.size < 1
  end

end
