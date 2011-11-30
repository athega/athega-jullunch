guard 'shell' do
  watch(/\/*\.rb/) { `touch tmp/restart.txt` }
  watch(/\/views\/*/) { `touch tmp/restart.txt` }
end

guard 'livereload' do
  watch(%r{public/.+\.(css|js)})
  watch(%r{views/.+\.haml})
  watch(%r{.+\.rb})
end

guard 'sass', :input => 'sass', :output => 'public/stylesheets', :style => :compressed
