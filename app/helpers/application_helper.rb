# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # Returns a link to a person using their full name as the link text and site URL
  # (or profile, if unspecified) as the reference.
  def link_to_person(person, *args)
    options = args.extract_options!
    if person == authenticated  
      content_tag('span', 'you')
    elsif person.url
      options.update :rel=>args.first if args.first
      link_to(h(person.fullname), person.url, options.merge(:title=>"See #{h(person.fullname)}'s profile"))
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
    case age = Time.now - time
    when 0...2.minute
      '1 minute'
    when 2.minute...1.hour
      '%d minutes' % (age / 1.minute)
    when 1.hour...2.hour
      '1 hour'
    when 2.hour...1.day
      '%d hours' % (age / 1.hour)
    when 1.day...2.day
      '1 day'
    when 2.day...1.month
      '%d days' % (age / 1.day)
    when 1.month...2.month
      'about 1 month'
    else
      '%d months' % (age / 1.month) if age > 0
    end
  end

  def abbr_date(date, text, options = {})
    content_tag 'abbr', text, options.merge(:title=>date.to_date.strftime('%Y%m%d'))
  end

  def abbr_time(time, text, options = {})
    content_tag 'abbr', text, options.merge(:title=>time.strftime('%Y%m%dT%H:%M:%S'))
  end

end
