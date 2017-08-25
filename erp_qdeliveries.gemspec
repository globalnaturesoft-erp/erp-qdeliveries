$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "erp/qdeliveries/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "erp_qdeliveries"
  s.version     = Erp::Qdeliveries::VERSION
  s.authors     = ["Luan Pham",
                  "Son Nguyen",
                  "Hung Nguyen"]
  s.email       = ["luanpm@hoangkhang.com.vn",
                  "sonnn@hoangkhang.com.vn",
                  "hungnt@hoangkhang.com.vn"]
  s.homepage    = "http://globalnaturesoft.com/"
  s.summary     = "Quick Deliveries features of Erp System."
  s.description = "Quick Deliveries features of Erp System."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 5.1.2"
  s.add_dependency "erp_core"
  s.add_dependency "deface"
end
