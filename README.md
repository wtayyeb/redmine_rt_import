Redmine RT Import
=================

This plugin will import XML files exported from Microsoft Project and create users, parent project, subprojects and issues in Redmine. It can also be used to update the previously imported project (by entering existing prefix field).
One project per MS project is created. Tasks that are containers in MS are created as subprojects.
Users in redmine are created from 'Resources' in MS. Existing users are recognised by name.
Issues are created or updated as well from the MS Project fields.
Since redmine supports only one user assigned to the issue, and in MS Project there can be many, issues are duplicated for each additional resource working on them.

this project forked from http://www.redmine.org/plugins/rt_import/  and the main Author was Stevan R


Installation notes
------------------

Like other plugins as easy as drink a glass of water.  

1. go to `{REDMINE_ROOT}/vendor/plugin` directory.
2. `git clone git://github.com/wtayyeb/redmine_rt_import.git`
2. `rake db:migrate_plugins RAILS_ENV=production`
3. Restart the redmine service.
4. enjoy!

