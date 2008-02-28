# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class ThirtyBoxesExtension < Radiant::Extension
  version "1.0"
  description "Allows you to display events from a 30 Boxes account on your site."
  url ""
  
  define_routes do |map|
    map.resource :thirty_boxes, :controller => 'admin/thirty_boxes', :path_prefix => '/admin'
  end
  
  def activate
    admin.tabs.add "30 Boxes", "/admin/thirty_boxes", :after => "Layouts", :visibility => [:all]
  end
  
  def deactivate
    admin.tabs.remove "30 Boxes"
  end
end
