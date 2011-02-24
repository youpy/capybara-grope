require 'grope'

class Capybara::Driver::Grope < Capybara::Driver::Base
  class Node < Capybara::Driver::Node
    def text
      native.textContent
    end

    def [](name)
      native.getAttribute(name.to_s)
    end

    def value
      if tag_name == "select" and native.multiple?
        native.selected_options
      else
        native.value
      end
    end

    def set(value)
      native.value = value
    end

    def select(option)
      native.options.find do |o|
        o.value == option.value
      end.selected = 1
    rescue
      options = native.options.map { |o| "'#{o.textContent}'" }.join(', ')
      raise Capybara::OptionNotFound, "No such option '#{option}' in this select box. Available options: #{options}"
    end

    def unselect(option)
      if native.multiple.zero?
        raise Capybara::UnselectNotAllowed, "Cannot unselect option '#{option}' from single select box."
      end

      native.options.find do |o|
        o.value == option.value
      end.selected = 0
    rescue
      options = native.options.map { |o| "'#{o.textContent}'" }.join(', ')
      raise Capybara::OptionNotFound, "No such option '#{option}' in this select box. Available options: #{options}"
    end

    def click
      js.click(native)
    end

    def drag_to(element)
      js._dispatchMouseEvent(native, 'mousedown', native);
      js._dispatchMouseEvent(native, 'mousemove', element.native);
      js._dispatchMouseEvent(native, 'mouseup', element.native);
    end

    def tag_name
      native.nodeName.downcase
    end

    def visible?
      (driver.grope.document.defaultView.getComputedStyle(native, '').visibility == 'visible') &&
        !(native.offsetWidth == 0 && native.offsetHeight == 0)
    end

    def checked?
      native.getAttribute('checked') == "checked"
    end

    def selected?
      native.getAttribute('selected') == "selected"
    end

    def path
      # TODO
    end

    def trigger(event)
      js._dispatchMouseEvent(native, event.to_s)
    end

    def find(xpath)
      self.class.new(driver, driver.grope.find(xpath, native))
    end

    def all(xpath)
      driver.grope.all(xpath, native).map { |n| self.class.new(driver, n) }
    end

    def js
      @js ||= driver.grope.eval('return Grope')
    end
  end

  attr_reader :app, :grope, :rack_server

  def initialize(app)
    @app = app
    @rack_server = Capybara::Server.new(@app)
    @rack_server.boot if Capybara.run_server

    init_grope
  end

  def visit(path)
    @grope.load(url(path))
    @grope.wait
  end

  def current_url
    @grope.document.URL
  end

  def source
    @grope.document.documentElement.outerHTML
  end

  def body
    @grope.document.body.outerHTML
  end

  def response_headers
    response.headers
  end

  def status_code
    raise Capybara::NotSupportedByDriverError
  end

  def find(selector)
    @grope.all(selector).map { |node| Node.new(self, node) }
  end

  def wait?; true; end

  def reset!
    init_grope
  end

  def evaluate_script(script)
    @grope.eval('return %s' % script)
  end

  private

  def url(path)
    rack_server.url(path)
  end

  def init_grope
    @grope = Grope::Env.new
  end
end

Capybara.register_driver :grope do |app|
  Capybara::Driver::Grope.new(app)
end

