require 'test_helper'

class YaffleTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Yaffle
    assert_equal "squawk! Hello World", "Hello World".to_squawk
  end
end
