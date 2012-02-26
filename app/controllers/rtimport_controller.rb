class RtimportController < ApplicationController
  unloadable

  require 'csv'
  require 'rexml/document'

  def index
  end

  def setup

    upload = params[:uploaded_file]

    @prefix = params[:prefix]
    @local_path = upload.local_path
    @original_path = upload.original_path

    @project_fields = Project.column_names

  end

  def import

    upload = params[:uploaded_file]
    prefix = params[:prefix]
    local_path = upload.local_path
    original_path = upload.original_path

#    local_path = params[:local_path]
#    original_path = params[:original_path]
#    prefix = params[:prefix]

#    if upload.original_path.index('csv').nil?
    if original_path.index('csv').nil?
      #logger.info "upload: #{upload.class.name}: #{upload.inspect} : #{upload.original_path}"

      content = File.read(local_path)

      #logger.info content

      doc = REXML::Document.new(content)

      root = doc.root

      doc.elements.each('Project') do |ele|

	@project = Project.find_by_identifier(prefix)
        if @project.nil?
	  @project = Project.new
	  @project.name = ele.elements["Name"].text #'XML import project'
          @project.identifier = prefix 
          @project.description = "imported"
	  @project.save
	end

        ele.each_element('//Resource') {
	  |child|

	  if !child.elements["Name"].nil?	  
	    name_arr = child.elements["Name"].text.split(" ")
	    firstname = name_arr[0]
	    lastname = name_arr[1]
	    @user = User.find_by_firstname_and_lastname(firstname, lastname)
	    if @user.nil?
	      @user = User.new
	      @user.login = name_arr.join(".").downcase!
	      @user.hashed_password = "55bffeb62c16ddd8c18debaf30573c6780ec836c"
	      @user.firstname = firstname
	      @user.lastname = lastname
	      @user.mail = " "
	      @user.mail_notification = "0"
	    end

            @user.rt_uid = child.elements["UID"].text
	    @user.save
	  end
	}

        ele.each_element('//Task') {
	  |child|

	  if child.elements["Summary"].text == "1"
  	    @subproject = Project.find_by_identifier(prefix + child.elements["UID"].text)
            if @subproject.nil?
	      @subproject = Project.new
	    end

            if child.elements["Name"].nil?
              @subproject.name = 'XML import subproject' + child.elements["UID"].text
	    else
	      @subproject.name = child.elements["Name"].text
	    end
            @subproject.identifier = prefix + child.elements["UID"].text
	    @subproject.rt_wbs = prefix + child.elements["WBS"].text
            @subproject.description = "imported"
	    @subproject.save

	    if child.elements["WBS"].text.size > 1
	      wbs_arr = child.elements["WBS"].text.split(".")
	      wbs_arr.pop
	      prev_wbs = wbs_arr.join(".")
 	      @rel_project = Project.find_by_rt_wbs(prefix + prev_wbs)
	      @subproject.set_allowed_parent!(@rel_project.id) if !@rel_project.nil?
	    else
	      @subproject.set_allowed_parent!(@project.id) if !@project.nil?  
	    end


# TODO: resources. if task has two, split the task

	  else # this is issue, but another else should be here for milestones which will become versions (child.elements["Milestone"].text == "1")

       	    @issue = Issue.find_by_rt_identifier(prefix + child.elements["UID"].text)
 	    if @issue.nil?

	      logger.info "creating new issue"
              @issue = Issue.new

            end

            @issue.subject = child.elements["Name"].text
            @issue.status_id = 1

	    priority = child.elements["Priority"].text
	    if priority == "500"
	      @issue.priority_id = 4
	    elsif priority < "500"
   	      @issue.priority_id = 3
	    elsif priority < "750"
	      @issue.priority_id = 5
  	    elsif priority < "1000"
	      @issue.priority_id = 6
	    else
   	      @issue.priority_id = 7
	    end

	    @issue.is_private = 0
	    @issue.tracker_id = 4
	    @issue.author_id = 1
	    @issue.done_ratio = child.elements["PercentComplete"].text
	    @issue.rt_wbs = prefix + child.elements["WBS"].text
	    #put a relation based on WBS
	    wbs_arr = child.elements["WBS"].text.split(".")
	    wbs_arr.pop
	    prev_wbs = wbs_arr.join(".")
	    @rel_project = Project.find_by_rt_wbs(prefix + prev_wbs)
	    if !@rel_project.nil?
	      @issue.project_id = @rel_project.id
	    end

	    @rel_issue = Issue.find_by_rt_wbs(prefix + prev_wbs)
	    if !@rel_issue.nil?
	      @issue.parent_issue_id = @rel_issue.id
	    end
	    
	    @issue.start_date = child.elements["Start"].text[0..10]
	    @issue.due_date = child.elements["Finish"].text[0..10]

	    duration_arr = child.elements["Duration"].text.split("H")
	    duration = duration_arr[0][2..duration_arr[0].size-1]
	    @issue.estimated_hours = duration
	
	    @issue.lock_version = 0
            @issue.rt_identifier = prefix + child.elements["UID"].text
            @issue.description = ""

            @issue.save

	  end
        }


	#@project.save
	#@parent_project = Project.find_by_identifier(prefix + ele.attributes["parent_id"]) if 
!ele.attributes["parent_id"].nil?
	#@project.set_allowed_parent!(@parent_project.id) if !@parent_project.nil?


	#ele.each_child do |child|
	#  logger.info "#{child.name} => #{child.text}"	  
	#end

   	@user_issues = Hash.new

        ele.each_element('//Assignment') {
	  |child|

	  user_uid = Integer(child.elements["ResourceUID"].text)
	  issue_uid = Integer(child.elements["TaskUID"].text)
	  
	  if @user_issues[issue_uid].nil?
	    @user_issues[issue_uid] = Array.new
	  end
	  @user_issues[issue_uid].push(user_uid)
	}

	@user_issues.each_pair do |issue_uid, user_uids|

	  logger.info "issue UID: #{issue_uid}"

	  @issues = Issue.find_all_by_rt_identifier(prefix + String(issue_uid))
	  user_uids.each_with_index do |user_uid, index|
	    @user = User.find_by_rt_uid(user_uid)

	    if @issues[index].nil?
	      @new_issue = Issue.new

              @new_issue.subject = @issues[0].subject
              @new_issue.status_id = @issues[0].status_id

	      @new_issue.priority_id = @issues[0].priority_id

	      @new_issue.is_private = @issues[0].is_private
	      @new_issue.tracker_id = @issues[0].tracker_id
	      @new_issue.author_id = @issues[0].author_id
	      @new_issue.done_ratio = @issues[0].done_ratio
	      @new_issue.rt_wbs = @issues[0].rt_wbs

	      @new_issue.project_id = @issues[0].project_id
	      @new_issue.parent_issue_id = @issues[0].parent_issue_id

	      @new_issue.start_date = @issues[0].start_date
	      @new_issue.due_date = @issues[0].due_date

	      #TODO: fix
	      @issue.estimated_hours = 0
	
	      @new_issue.lock_version = 0
              @new_issue.rt_identifier = @issues[0].rt_identifier
              @new_issue.description = @issues[0].description

	      @new_issue.assigned_to_id = @user.id

              @new_issue.save

	    else  
	      @issues[index].assigned_to_id = @user.id
	      @issues[index].save
	    end
	  end
	end


      end

    else
    
#     logger.info "upload: #{upload.class.name}: #{upload.inspect} : #{upload.original_path}"
      create_issues = params[:create_issues]
 
      # create_issues is empty if checkbox is not checked, so use empty?

      #reader = CSV.open(upload.local_path, 'rb', encoding: "ISO-8859-7")
      #reader = CSV.open(upload.local_path, 'rb:ISO-8859-7')
      reader = CSV.open(local_path, 'r')
      #@parsed_file=CSV::Reader.parse(params[:uploaded_file], ';')
      n=0
      reader.each do |row_tmp|

        row = CSV.parse_line(row_tmp[0],';')
        logger.info row[0]
	
        if !create_issues.nil?
          is_parent = 0
	
	  reader2 = CSV.open(upload.local_path, 'r')
	  reader2.each do |row_tmp2|
	    row_2 = CSV.parse_line(row_tmp2[0],';')
	    if row[0] == row_2[1]
	      is_parent = 1
	    end
	  end
	  reader2.close
	  #if it's not anyones parent, create/update an issue
	  logger.info "row_name: #{row[2]}, is_parent: #{is_parent}" 

	  if is_parent == 0

	    @issue = Issue.find_by_rt_identifier(prefix + row[0])
	    if !@issue.nil?
              @issue.subject = row[2]
	      @issue.project_id = Project.find_by_identifier(prefix + row[1]).id if !row[1].nil?
              @issue.save
            else
	      logger.info "creating new issue"
              @issue = Issue.new
              @issue.subject = row[2]
              @issue.status_id = 1
	      @issue.priority_id = 3
	      @issue.is_private = 0
	      @issue.tracker_id = 1
	      @issue.author_id = 1
	      @issue.done_ratio = 0
	      @issue.lock_version = 0
              @issue.rt_identifier = prefix + row[0]
              @issue.description = "imported by RT tool"
              @issue.project_id = Project.find_by_identifier(prefix + row[1]).id if !row[1].nil?
              @issue.save
            end
 
	  else
	    logger.info "else branch"  	  #TODO: have to create projects as well for parents, double the code below prolly
            @project = Project.find_by_identifier(prefix + row[0])
       	    if !@project.nil?
              @project.name = row[2]
              @project.save
              @parent_project = Project.find_by_identifier(prefix + row[1]) if !row[1].nil?
              @project.set_allowed_parent!(@parent_project.id) if !@parent_project.nil?
            else
              @project = Project.new
              @project.name = row[2]
              @project.identifier = prefix + row[0]
              @project.description = "imported from forester"
              @project.save
              @parent_project = Project.find_by_identifier(prefix + row[1]) if !row[1].nil?
              @project.set_allowed_parent!(@parent_project.id) if !@parent_project.nil?
            end

	  end

        else
      	  @project = Project.find_by_identifier(prefix + row[0])
     	  if !@project.nil?
	    logger.info row[2]
	    @project.name = row[2]
	    @project.save
	    @parent_project = Project.find_by_identifier(prefix + row[1]) if !row[1].nil?
	    @project.set_allowed_parent!(@parent_project.id) if !@parent_project.nil?
          else 
	    @project = Project.new
	    @project.name = row[2]
	    @project.identifier = prefix + row[0]
	    @project.description = "imported from forester"
	    @project.save
	    @parent_project = Project.find_by_identifier(prefix + row[1]) if !row[1].nil?
            @project.set_allowed_parent!(@parent_project.id) if !@parent_project.nil?
          end

	end

      end

    end

  end

end
