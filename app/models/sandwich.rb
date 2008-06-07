class Sandwich

  def self.human_attribute_name(name)
    name.titleize
  end

  def initialize(attributes = {})
    if attributes
      ['bread', 'spread', 'toppings'].each do |name|
        send "#{name}=", attributes[name]
      end
    end
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

  def save(url, completed = false)
    validate
    errors.empty?
    data = ['bread', 'spread', 'toppings'].inject({}) { |hash, name| hash.update(name=>send(name)) }
    task = { 'data'=>data }
    task.update 'status'=>'completed' if completed
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    post = Net::HTTP::Put.new(uri.path)
    post.basic_auth uri.user, uri.password
    post.content_type = Mime::XML.to_s
    http.request(post, task.to_xml(:root=>'task'))
  end

  private

  def validate
    errors.add :bread, 'Spread without a bread?' if !spread.empty? && bread.empty?
    errors.add :toppings, 'Your sandwich is short on toppings!' if toppings.size < 1
  end

end
