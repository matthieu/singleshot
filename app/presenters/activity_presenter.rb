class ActivityPresenter < Presenter::Base
  
  def to_html
    grouped = activities.group_by { |activity| [activity.task, activity.person, activity.created_at] }
    list = grouped.map { |(task, person, published), related|
      %{<li id="#{id_for(related.first)}" class="activity hentry">
          <abbr class="published" title="#{published.iso8601}">#{I18n.l(published, :format=>'%I:%M%p')}</abbr>
          <span class="entry-title">#{presenting(related).single_entry(:html)}</span>
        </li>}
    }.join
    %{<ol class="activities">#{list}</ol>}
  end
  
  def single_entry(format = :text)
    first = activities.first
    names = activities.map { |activity| I18n.t("activity.name.#{activity.name}") }
    if format == :text
      person, task = first.person.fullname, first.task.title
    else
      person = %{<a href="#{first.person.url}" rel="author">#{h(first.person.fullname)}</a>}
      task = %{<a href="#{task_url(first.task)}" rel="task">#{h(first.task.title)}</a>}
    end
    I18n.t("activity.entry.#{format}", :person=>person, :task=>task, :names=>names)
  end
  
  def hash_for(activity)
    task, person = activity.task, activity.person
    { :id=>id_for(activity), :name=>activity.name, :published=>activity.created_at,
      :task=>{ :id=>id_for(task), :url=>task_url(task), :title=>task.title },
      :person=>{ :id=>person.identity, :url=>person.url, :name=>person.fullname }
    }
  end
        
end