module Templates #:nodoc:
  # iCal VCALENDAR object buildr.
  class IcalBuilder < BlankSlate
    def initialize(request, output = nil)
      @request = request
      @output = output || StringIO.new
      write 'BEGIN', 'VCALENDAR'
      write 'VERSION', '2.0'
      yield self
      write 'END', 'VCALENDAR'
    end

    def event(record, &block)
      component 'vevent', record, &block
    end

    def todo(record, &block)
      component 'vtodo', record, &block
    end

    def journal(record, &block)
      component 'vjournal', record, &block
    end

    def to_s
      @output.respond_to?(:string) ? @output.string : @output.to_s
    end

  private

    def component(type, record)
      write 'BEGIN', type.upcase
      if record
        uid           MD5.hexdigest([@request.host, record.class, record.id, record.created_at].join(':'))
        dtstamp       record.created_at.utc.strftime('%Y%m%dT%H%M%SZ') if record.respond_to?(:created_at)
        last_modified record.updated_at.utc.strftime('%Y%m%dT%H%M%SZ') if record.respond_to?(:updated_at)
        sequence      record.send(record.class.locking_column) if record.locking_enabled?
      end
      yield self
      write 'END', type.upcase
    end

    def method_missing(name, *args)
      params = args.extract_options!
      write name, args, params
    end

    # Write a content line the specified name, value and parameters.
    # Names are automatically converted to upper case with dash separators.
    def write(name, value, params = {})
      write_line name.to_s.underscore.upcase +
        params.map { |name, value| ";#{name.to_s.underscore.upcase}=#{stringify(value)}" }.join +
        ":#{stringify(value)}"
    end

    # Write a content line, observing the 75 character limit and unfolding rules.
    def write_line(line)
      if line.size <= 75
        @output << "#{line}\r\n"
      else
        @output << "#{line[0...75]}\r\n"
        write_line " #{line[75..-1]}"
      end
    end

    # Convert Ruby value into most appropriate iCal representation.
    def stringify(value)
      case value
      when Array then value.map { |item| stringify(item) }.join(',')
      when Date then value.strftime('%Y%m%d')
      when Time then value.strftime(value.utc? ? '%Y%m%dT%H%M%SZ' : '%Y%m%dT%H%M%S')
      else value.to_s
      end
    end

  end

  class Ical < ActionView::TemplateHandler #:nodoc:
    include ActionView::TemplateHandlers::Compilable

    def self.line_offset
      2
    end

    def compile(template)
      <<-RUBY
      set_controller_content_type("#{Mime::ICS};method=PUBLISH");
      ical = ActionView::ICalBuilder.new controller.request do |calendar|
        #{template.source}
      end
      ical.to_s
      RUBY
    end

    def cache_fragment(block, name = {}, options = nil)
      @view.fragment_for(block, name, options) do
        eval('calendar.to_ical', block.binding)
      end
    end
  end
end
