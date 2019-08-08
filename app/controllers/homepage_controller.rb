class HomepageController < ApplicationController

  def index

  end

  def about

  end

  def contact
    @errors=[]
    if request.post?
      if validate_email
        Notifier.feedback(params).deliver_now
        redirect_to feedback_complete_path
      end
    end
  end

  def feedback_complete
    @errors=[]
  end

  # validates the incoming params
  # returns either an empty array or an array with error messages
  def validate_email
    unless params[:name] =~ /\w+/
      @errors << "Please enter your name."
    end
    unless params[:email] =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
      @errors << "Please enter a valid email address."
    end
    unless params[:message] =~ /\w+/
      @errors << "Please enter a message."
    end
    #unless simple_captcha_valid?
    #  @errors << 'Captcha did not match'
    #end
    @errors.empty?
  end


end