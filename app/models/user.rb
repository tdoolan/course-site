class User < ActiveRecord::Base
	
	attr_accessible :avatar, :mail, :name, :uvanetid
	attr_accessible :term, :status, :schedule_id, :schedule_span_id, :active
	
	belongs_to :group

	has_many :logins
	has_many :submits
	has_many :grades, through: :submits
	has_many :psets, through: :submits
	# has_many :registrations
	
	has_one :ping

	def submit(pset)
		submits.where(:pset_id => pset.id).first
	end
	
	def activate
		update_attribute :active, true
	end
	
	scope :admin,     -> { joins(:logins).where("logins.login in (?)", (Settings['admins'] or []) + (Settings['assistants'] or [])) }
	scope :not_admin, -> { joins(:logins).where("logins.login not in (?)", (Settings['admins'] or []) + (Settings['assistants'] or [])) }
	scope :active,    -> { where(active: true) }
	scope :inactive,  -> { where(active: false) }
	scope :no_group,  -> { where(group_id: nil) }
	scope :but_not,   -> users { where("users.id not in (?)", users) }
	scope :with_login, -> login { joins(:logins).where("logins.login = ?", login)}
	
	scope :from_term, -> term  { where("term" => term) if not (term.nil? or term.empty?) }
	scope :having_status, -> status  { where("status" => status) if not (status.nil? or status.empty?) }
	
	belongs_to :schedule
	belongs_to :schedule_span

	# ensure that if a schedule is selected, a valid schedule_span is also present
	before_save do |r|
		if r.schedule.present?
			logger.debug "SCHED PRES"
			if r.schedule_span.present?
				logger.debug "SPAN PRES"
				r.schedule_span = r.schedule.schedule_spans.first if not r.schedule.schedule_spans.include?(r.schedule_span)
			else
				logger.debug "SPAN NOT PRES"
				r.schedule_span = r.schedule.schedule_spans.first
			end
		else
			logger.debug "nuttin PRES"
			
			r.schedule_span = nil
		end
	end
	
	def valid_profile?
		return !self.name.blank?
	end
	
	def can_submit?
		return self.valid_profile?
	end
	
	def is_admin?
		admins = Settings['admins']
		return admins && (admins & self.logins.pluck(:login))
	end
	
	def is_assistant?
		assistants = Settings['assistants']
		return assistants && (assistants & self.logins.pluck(:login))
	end
	
	def final_grade
		'N/A'
	end
	
	def assign_final_grade
		# generate hash of psewt_name => submit_object
		subs = self.grades.group_by { |i| i.submit.pset.name }.each_with_object({}) { |(k,v),o| o[k] = v[0] }
		
		# calc grade from hash
		grade = GradeTools.new.calc_final_grade(subs)
		
		# save
		if grade > 0
			final = self.submits.where(pset:Pset.where(name:'final').first).first_or_create
			final.create_grade if !final.grade
			final.grade.update_attribute(:grade, grade)
		end
	end
	
	def generate_token!
		self.token = SecureRandom.hex(16)
		self.save
	end
	
	def generate_pairing_code!
		self.token = SecureRandom.random_number(10000)
		self.save
	end
	
end
