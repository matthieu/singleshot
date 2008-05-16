module ActionView
  class ICalBuilder

    class Component

      def initialize(request, record = nil)
        @properties = {}
        if record
          uid "#{request.host}:#{record.class}/#{record.id}"
          dtstamp record.created_at.utc.strftime('%Y%m%dT%H%M%SZ') if record.respond_to?(:created_at)
          last_modified record.updated_at.utc.strftime('%Y%m%dT%H%M%SZ') if record.respond_to?(:updated_at)
          sequence record.send(record.class.locking_column) if record.locking_enabled?
        end
      end

      attr_accessor :properties

      def to_ical
        # TODO: escaping for values
        # TODO: break up long lines
        # TODO: all other conformance requirements
        properties = @properties.map { |name, value| property(name, value) }
        "BEGIN:#{self.class.const_get :NAME}\n#{properties.join("\n")}\nEND:#{self.class.const_get :NAME}"
      end

    private

      def property(name, value)
        value = { :value=>value } unless Hash === value
        name.to_s.underscore.upcase +
          value.except(:value).map { |name, value| ";#{name.to_s.underscore}=#{stringify(value)}" }.join +
          ":#{stringify(value[:value])}"
      end

      def stringify(value)
        case value
        when String then value
        when Date then value.strftime('%Y%m%d')
        when Time then value.strftime(value.utc? ? '%Y%m%dT%H%M%SZ' : '%Y%m%dT%H%M%S')
        else value.to_s
        end
      end

      def method_missing(name, *args)
        options = args.extract_options!
        options[:value] = args.first
        @properties[name] = options
      end

    end

    class Event < Component

      NAME = 'VEVENT'

    end


    class Todo < Component

      NAME = 'VTODO'

    end

    def initialize(request)
      @request =request
      @components = []
    end

    attr_accessor :prodid
    attr_reader :components

    def event(record = nil)
      returning Event.new(@request, record) do |event|
        yield event if block_given?
        @components << event
      end
    end

    def todo(record = nil)
      returning Todo.new(@request, record) do |todo|
        yield todo if block_given?
        @components << todo
      end
    end

    def to_ical
      # TODO: user's timezone
      "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:#{prodid}\n#{@components.map(&:to_ical).join("\n")}\nEND:VCALENDAR\n"
    end
  end


  module TemplateHandlers
    class ICalTemplate < TemplateHandler
      include Compilable

      def self.line_offset
        2
      end

      def compile(template)
        content_type_handler = (@view.send!(:controller).respond_to?(:response) ? "controller.response" : "controller")
        "#{content_type_handler}.content_type ||= Mime::ICS\n" +
        "calendar = ::ActionView::ICalBuilder.new(request)\n" +
        template.source +
        "\ncalendar.to_ical\n"
      end

      def cache_fragment(block, name = {}, options = nil)
        @view.fragment_for(block, name, options) do
          eval('calendar.to_ical', block.binding)
        end
      end
    end
  end
end
