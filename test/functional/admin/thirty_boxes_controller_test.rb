require File.dirname(__FILE__) + '/../../test_helper'

# Re-raise errors caught by the controller.
Admin::ThirtyBoxesController.class_eval { def rescue_action(e) raise e end }

class Admin::ThirtyBoxesControllerTest < Test::Unit::TestCase
  def setup
    @controller = Admin::ThirtyBoxesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
