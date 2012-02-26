require 'redmine'

Redmine::Plugin.register :redmine_rt_import do
  name 'Redmine Task Import plugin'
  author 'wTayyeb'
  description 'MS Project importer plugin for Redmine'
  version '0.6.1'
  url 'https://github.com/wtayyeb/redmine_rt_import/'
  author_url 'https://github.com/wtayyeb/'

  menu :admin_menu, :rtimport, { :controller => 'rtimport', :action => 'index' }, :caption => 'msProject Task Importer'
end
