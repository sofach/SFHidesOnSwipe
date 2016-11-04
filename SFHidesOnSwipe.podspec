
Pod::Spec.new do |s|

s.name         = "SFHidesOnSwipe"
s.version      = "1.0.2"
s.summary      = "add hidesOnSwipe to view"

s.description  = <<-DESC
add hidesOnSwipe to view, like navigationBar
DESC

s.homepage     = "https://github.com/sofach/SFHidesOnSwipe"

s.license      = "MIT"

s.author       = { "sofach" => "sofach@126.com" }

s.platform     = :ios
s.platform     = :ios, "5.0"

s.source       = { :git => "https://github.com/sofach/SFHidesOnSwipe.git", :tag => "1.0.2" }

s.source_files  = "SFHidesOnSwipe/lib/**/*.{h,m}"
s.requires_arc = true

end
