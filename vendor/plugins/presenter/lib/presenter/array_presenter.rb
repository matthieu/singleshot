class ArrayPresenter < Presenter::Base
  def to_hash
    object.map { |item| presenting(item).to_hash }
  end

end
