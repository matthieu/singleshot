module ActionView
  class ICalBuilder

    module Properties
      attr_accessor :properties

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

    class Component

      include Properties

      def initialize(request, record = nil)
        @properties = {}
        if record
          uid "#{request.host}:#{record.class}/#{record.id}"
          dtstamp record.created_at.utc.strftime('%Y%m%dT%H%M%SZ') if record.respond_to?(:created_at)
          last_modified record.updated_at.utc.strftime('%Y%m%dT%H%M%SZ') if record.respond_to?(:updated_at)
          sequence record.send(record.class.locking_column) if record.locking_enabled?
        end
      end

      def to_ical
        # TODO: escaping for values
        # TODO: break up long lines
        # TODO: all other conformance requirements
        properties = @properties.map { |name, value| property(name, value) }
        ["BEGIN:#{self.class.const_get :NAME}", properties, "END:#{self.class.const_get :NAME}"].flatten.join("\n")
      end

    end

    class Event < Component

      NAME = 'VEVENT'

    end


    class Todo < Component

      NAME = 'VTODO'

    end

    include Properties

    def initialize(request)
      @request =request
      @properties = { :method=>'PUBLISH' }
      @components = []
    end

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
      properties = @properties.map { |name, value| property(name, value) }
      components = @components.map(&:to_ical)
      ['BEGIN:VCALENDAR', 'VERSION:2.0', properties, components, 'END:VCALENDAR'].flatten.join("\n")
    end

    def content_type
      "#{Mime::ICS};method=#{properties[:method]}"
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
        "calendar = ::ActionView::ICalBuilder.new(request)\n" +
        template.source +
        "#{content_type_handler}.content_type ||= calendar.content_type\n" +
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
