class TaskListPresenter < Presenter::Base

  alias :tasks :object

  def to_hash
    { 'tasks'=> tasks.map { |task| presenting(task).to_hash } }
  end

end

