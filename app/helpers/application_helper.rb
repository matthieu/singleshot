# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # Returns a link to a person using their full name as the link text and site URL
  # (or profile, if unspecified) as the reference.
  def link_to_person(person, options = {})
    fullname = h(person.fullname)
    person.identity ? link_to(fullname, person.identity, options.reverse_merge(:title=>"See #{fullname}'s profile")) :
      content_tag('span', fullname, options)
  end

  # Returns Person object for currently authenticated user.
  attr_reader :authenticated

  def relative_date(date)
    date = date.to_date
    today = Date.today
    if date == today
      'Today'
    elsif date == today - 1.day
      'Yesterday'
    elsif date.cweek == today.cweek
      date.strftime('%A')
    elsif date.year == today.year
      date.strftime('%B %d')
    else
      date.strftime('%B %d, %Y')
    end
  end

  def relative_date_abbr(date, options = {})
    content_tag 'abbr', relative_date(date), options.merge(:title=>date.to_date.to_s)
  end

end
