require 'rubygems'
require 'rake'
require 'rubygems/package_task'

$:.push File.expand_path('../lib', __FILE__)
require 'nested_sortable_tree/rails/version'

gemspec = eval(File.read('nestedsortabletree-rails.gemspec'))
Gem::PackageTask.new(gemspec) do |pkg|
  pkg.gem_spec = gemspec
end

desc 'build the gem and release it to rubygems.org'
task :release => :gem do
  sh "gem push pkg/nestedsortabletree-rails-#{NestedSortableTree::Rails::VERSION}.gem"
end
