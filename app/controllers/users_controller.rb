class UsersController < ApplicationController
	layout "user"
		
	before_action :store_return_to
	before_action :confirm_logged_in_as_admin, :only =>[:approve_users]
	before_action :confirm_logged_in, :only =>[:follow_user, :unfollow_user,:edit, :update, :password,:change_password]
	before_action :user_login?, :only =>[:new,:create]
	before_action :find_login_user_data_verification,:only =>[:edit,:update,:password,:change_password]

	def home
		@user=User.new()
	end

	def index		
		@users=User.all().order('first_name ASC')
	end	

	def show		
		@user = User.find(params[:id])
		@country = @user.country
		@state = @user.state
		@follow=Follow.new()
		@followers = Follow.where(:follower_id =>@user.id).pluck(:user_id)
		@posts=Post.where(:user_id => @followers)		
	end

	def new
		@user=User.new()		
		if (params[:state_id])
			@user_state_id = params[:state_id]			
		end		
	end

	def create		 
		@user=User.new(user_create_params)
		if @user.save
			flash[:notice]= "User registration successfully."
			redirect_to user_login_path 
		else
			@state_js = params[:user][:state_id]
			render :new
		end 
	end

	def edit		
		if (params[:state_id])
			@user_state_id = params[:state_id]			
		end		
	end

	def update		
		if (params[:state_id])
			@user_state_id = params[:state_id]			
		end	
		if @user.update_attributes(user_update_params)
			flash[:notice]= "User details updated successfully."
			redirect_to user_path(session[:current_user_id])			
		else
			flash[:notice] = "something wrong."
			render 'edit'
		end 		
	end


	def password		
	end

	def change_password		
		if ((user_password_params[:password].eql? user_password_params[:password_confirmation]) && (user_password_params[:password].length > 6 && user_password_params[:password].length < 16)) 
			if @user.update_attributes(user_password_params)
				flash[:notice]= "User password updated successfully."			
				redirect_to  access_logout_path
			end
		else			
			if(!(user_password_params[:password].eql?user_password_params[:password_confirmation]))
				flash[:notice] = "Password does not match the confirm password."
			end

			if(user_password_params[:password].length == 0 )				
				flash[:notice] = "Password can't be blank."				
			end

			if(user_password_params[:password].length < 6 || user_password_params[:password].length > 16)
				flash[:notice] = "Password must be of minimum 6 characters and maximum 16 characters length  ."
			end			
			redirect_to  password_user_path(@user)
		end		
	end

	def find_login_user_data_verification 
		@user = User.find(params[:id])
		cuser_id = session[:current_user_id]
		if (@user.id == cuser_id)
			true
		else
			flash[:notice]  = "You are not authorized to access other persons data ."
			redirect_to users_path
		end
	end

	def get_states
    	states = State.where('country_id = ?', params[:id]).order('state_name ASC')
    	result = {'res' => states, 'message' => 'All states.'}    
    	render json: result, status: 200
  	end

	def follow_user
		followee = params[:followee]
		followers= params[:followers]
		@follow=Follow.new()
		user = User.find_by(:id => followee)
		if(session[:current_user_id]!= nil)
			@follow.follower_id = followers
			@follow.user_id = followee
			if(user.follow_count)	
				user.update_attributes(:follow_count => user.follow_count + 1 )
			else 
				user.update_attributes(:follow_count => 1 )
			end

			if @follow.save
				flash[:notice]= " Thank you for follow the user."
				redirect_to users_path 
			else
				flash[:notice]= "something wrong"			
				redirect_to users_path
			end
		else 
			flash[:notice]= " Please log in first."
			redirect_to user_login_path
		end
	end

	def unfollow_user		
		followee = params[:followee]
		followers= params[:followers]
		if(session[:current_user_id]!=nil)
			user = User.find_by(:id => followee)
			@follow=Follow.where(:user_id => followee,:follower_id => followers).first
			
			if(user.follow_count)	
				user.update_attributes(:follow_count => (user.follow_count - 1) )
			end

			if @follow.destroy
				flash[:notice]= " you are no longer follow the user."
				redirect_to users_path 
			else
				flash[:notice]= "something wrong"			
				redirect_to users_path
			end
		else 
			flash[:notice]= " Please log in first."
			redirect_to users_path
		end
	end

	def approve_users
		@users_approve = User.where(:is_admin => false, :is_approve => true).order('email ASC')
		@users_disapprove = User.where(:is_admin => false, :is_approve => false).order('email ASC')
	end

	def make_approve
		user = User.find_by_id(params[:id])
		user.update_attributes(:is_approve => true )
		redirect_to approve_users_users_path		
	end

	def make_disapprove
		user = User.find_by_id(params[:id])
		user.update_attributes(:is_approve => false )
		redirect_to approve_users_users_path
	end

	def follow_details
		@user = User.find(params[:id])
		loged_in_user =session[:current_user_id]
		follow=Follow.where(:follower_id =>loged_in_user,:user_id =>@user.id ).first
	end
	helper_method :follow_details

	def api_log_in    
	    if session[:current_user_id]
	      result = {'res' => session[:current_user_id], 'message' => 'Log in state.'} 
	    else
	      result = {'res' => nil, 'message' => 'Log in state.'}
	    end
	    render json: result, status: 200        
  	end

  	def convert_array(p)
  		i=0
  		a = ""  		
		p.each do |t|
  			if(i>0)
  				a = a.to_s + ","
  			end
  			i=i+1

  			case t
  			when "1"
  				a = a.to_s + ' Acting'	  			
  			when "2"
  				a = a.to_s + ' Cooking'	  			
  			when "3"
  				a = a.to_s + ' Dance'	  			
  			when "4"
  				a = a.to_s + ' Fashion'	  			
  			when "5"
  				a = a.to_s + ' Pet'	  			
  			else 
  				a = a.to_s + ' Puzzles'
  			end	 	
		end
		return a

	end
  	helper_method :convert_array

  	def is_admin?(user)
		user = User.find_by_id(user)
		if(user!= nil)
			user.is_admin
		else
			false
		end
	end
	helper_method :is_admin?

	def get_interest
		@user=User.find(session[:current_user_id])
		result = {'res' => @user.interest, 'message' => 'User interests.'}	    
	    render json: result, status: 200  

	end

	private
	def user_login?
		unless !session[:current_user_id]
      		redirect_to root_path      		
      		return false 
    	else
      		return true
    	end
	end

	def user_password_params	
		params.require(:user).permit(:password,:password_confirmation)
	end

	def user_create_params			
		params[:user][:interest]=(params[:user][:interest]).to_json		
		params.require(:user).permit(:first_name, :last_name, :gender, :country_id, :state_id, :interest, :address, :email, :password, :profile_image,:password_confirmation, :is_approve)
	end
	

	def user_update_params		
		params[:user][:interest]=(params[:user][:interest]).to_json		
		params.require(:user).permit(:first_name, :last_name, :gender, :country_id, :state_id, :interest, :address, :email, :profile_image, :is_approve)
	end
end
