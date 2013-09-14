class GradesController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant

	def create_submit
		@submit = Submit.create do |s|
			s.user_id = params[:user_id]
			s.pset_id = params[:pset_id]
		end
		redirect_to new_submit_grade_url(submit_id:@submit.id)
	end

	def users
		@groupless = User.where(active: true, done: false, group_id: nil).order('updated_at desc')
		@done = User.where(done: true).order('updated_at desc')
		@inactive = User.where(active: false).order('updated_at desc')
		@psets = Pset.order(:name)
		@title = "List users"
	end
	
	##
	# POST
	# ajax-only enable/disable of students
	#
	def enable
		reg = User.find(params[:id])
		reg.update_attribute(:active, params[:active])
		render :nothing => true
	end

	##
	# POST
	# ajax-only done/not done of students
	#
	def done
		reg = User.find(params[:id])
		reg.update_attribute(:done, params[:done])
		render :nothing => true
	end
		
	# GET /grades
	# GET /grades.json
	def index
		@grades = Grade.all

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @grades }
		end
	end

	# GET /grades/1
	# GET /grades/1.json
	def show
		@grade = Submit.find(params[:submit_id]).grade

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @grade }
		end
	end

	# GET /grades/new
	# GET /grades/new.json
	def new
		@grade = Submit.find(params[:submit_id]).build_grade do |e|
			e.grader = current_user.uvanetid
		end

		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @grade }
		end
	end

	# GET /grades/1/edit
	def edit
		@grade = Submit.find(params[:submit_id]).grade
		@grade.grader = current_user.uvanetid
		
		puts @grade.inspect
	end

	# POST /grades
	# POST /grades.json
	def create
		@grade = Grade.new(params[:grade])
		@grade.submit_id = params[:submit_id]

		respond_to do |format|
			if @grade.save
				format.html { redirect_to grades_users_url, notice: 'Grade was successfully created.' }
				format.json { render json: @grade, status: :created, location: @grade }
			else
				format.html { render action: "new" }
				format.json { render json: @grade.errors, status: :unprocessable_entity }
			end
		end
	end

	# PUT /grades/1
	# PUT /grades/1.json
	def update
		@grade = Submit.find(params[:submit_id]).grade

		respond_to do |format|
			if @grade.update_attributes(params[:grade])
				format.html { redirect_to grades_users_url, notice: 'Grade was successfully updated.' }
				format.json { head :no_content }
			else
				format.html { render action: "edit" }
				format.json { render json: @grade.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /grades/1
	# DELETE /grades/1.json
	def destroy
		@grade = Submit.find(params[:submit_id]).grade
		@grade.destroy

		respond_to do |format|
			format.html { redirect_to grades_url }
			format.json { head :no_content }
		end
	end

end