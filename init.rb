require 'redmine'

Redmine::Plugin.register :redmine_rt_import do
  name 'Redmine Ft Import plugin'
  author 'Stevan'
  description 'This is a project import plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  menu :admin_menu, :rtimport, { :controller => 'rtimport', :action => 'index' }, :caption => 'RT Import'
end
