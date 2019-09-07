class HomepageController < ApplicationController

  def index

  end

  def about
    @errors=[]
    @reveal_email = false
    if request.post?
      unless verify_recaptcha(action: 'contact', minimum_score: 0.45, secret_key: Settings.recaptcha_secret_key_v3)
        if verify_recaptcha
          @show_captcha_v2 = false
        else
          @show_captcha_v2 = true
          @errors << 'Background recaptcha failed. Please fill out the below checkbox captcha and try clicking "[Reveal Email]" again.'
        end
      end

      @reveal_emails = @errors.empty?
    end
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
    unless verify_recaptcha(action: 'contact', minimum_score: 0.4, secret_key: Settings.recaptcha_secret_key_v3)
      if verify_recaptcha
        @show_captcha_v2 = false
      else
        @show_captcha_v2 = true
        @errors << 'Background recaptcha failed. Please try submitting your message again with the added checkbox captcha.'
      end

    end
    @errors.empty?
  end


end