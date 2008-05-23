# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # Returns a link to a person using their full name as the link text and site URL
  # (or profile, if unspecified) as the reference.
  def link_to_person(person, *args)
    options = args.extract_options!
    fullname = person == authenticated ? 'you' : h(person.fullname)
    if person.url
      options.update :rel=>args.first if args.first
      link_to(fullname, person.url, options.merge(:title=>"See #{fullname}'s profile"))
    else
      content_tag('span', fullname)
    end
  end

  # Returns Person object for currently authenticated user.
  attr_reader :authenticated

  def relative_date(date)
    date = date.to_date
    today = Date.today
    if date == today
      'today'
    elsif date == today - 1.day
      'yesterday'
    elsif date > today && date < today.next_week
      date.strftime('%A')
    elsif date.year == today.year
      date.strftime('%B %d')
    else
      date.strftime('%B %d, %Y')
    end
  end

  def relative_time(time)
    diff = Time.now - time
    if diff < 1.minute
      'this minute'
    elsif diff < 1.hour
      "#{(diff / 1.minute).round} minutes ago"
    elsif diff < 1.day
      "#{(diff / 1.hour).round} hours ago"
    elsif diff < 1.month
      "#{(diff / 1.day).round} days ago"
    end
  end

  def relative_date_abbr(date, options = {})
    content_tag 'abbr', relative_date(date), options.merge(:title=>date.to_date.to_s)
  end

end
