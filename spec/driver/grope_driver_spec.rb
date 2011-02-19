require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe Capybara::Driver::Grope do
  before do
    @driver = Capybara::Driver::Grope.new(TestApp)
  end

  it_should_behave_like "driver"
  it_should_behave_like "driver with javascript support"
  it_should_behave_like "driver with cookies support"
end
