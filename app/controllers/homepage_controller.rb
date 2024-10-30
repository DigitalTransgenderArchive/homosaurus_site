class HomepageController < ApplicationController

  def index

  end

  def about
    @errors=[]
    @reveal_email = false
    if request.post?
      unless verify_recaptcha(action: 'about', minimum_score: 0.35, secret_key: Settings.recaptcha_secret_key_v3)
        if verify_recaptcha
          @show_captcha_v2 = false
        else
          @show_captcha_v2 = true
          @errors << 'Background recaptcha failed. Please fill out the captcha checkbox and try clicking "[Reveal Email]" again.'
        end
      end

      @reveal_emails = @errors.empty?
    end
  end

  def release

  end

  def contact
    @errors=[]
    if request.post?
      if validate_email
        Notifier.feedback(params).deliver_now
        logger.warn "EMAIL WAS SENT HERE: #{params[:name]} -- #{params[:email]} -- #{params[:message]}"
        redirect_to feedback_complete_path
      end
    end
  end

  def feedback_complete
    @errors=[]
  end

  def profile
    unless params[:user_id]
      redirect_to profile_for_path(current_user)
    end
    u = User.find_by(id: params[:user_id].to_i) || current_user
    @user = u
  end

  def update_profile
    @user  = User.find_by(id: params[:user_id].to_i)
    if @user.id == current_user.id and @user.update(params.require(:user).permit(:username, :fname, :lname, :bio))
      flash[:success] = "Updated successfully"
      redirect_to profile_for_path(@user)
    else
      flash[:error] = "Error updating profile"
      redirect_to profile_for_path(@user)
    end
  end

  def profile_discussion
    @homosaurus_obj = User.find_by(id: params[:user_id])
    @discussion_type = "User"
    @comments = @homosaurus_obj.profile_comments.where(replaces_comment_id: nil)
    render "vocabulary/discussion"
  end
  def profile_post_comment
    parent = nil
    if params["parent_type"] == "User"
      parent = User.find_by(id: params["parent"])
    else
      parent = Comment.find_by(id: params["parent"])
    end
    @c = Comment.create(user_id: params["user"],
                        subject: params["subject"] || nil,
                        commentable: parent,
                        content: params["content"],
                        is_vote: false,
                        language_id: params["language_id"])
    redirect_to profile_discussion_path(:anchor => "comment-#{@c.id}")
  end
  def profile_edit_comment
    comment = Comment.find_by(id: params['comment_id'])
    subject = params['subject']
    content = params['content']
    notice = "Comment succesfully edited"
    if comment.subject == subject and comment.content == content
      notice = "No changes made."
      @c = comment
    else
      @c = Comment.create(user_id: comment.user.id,
                          subject: subject,
                          commentable: comment.commentable,
                          content: content,
                          is_vote: false,
                          replaces_comment_id: comment.id,
                          language_id: comment.language_id)
      comment.updated_at = Time.now
      comment.save!
    end
    redirect_to profile_discussion_path(:anchor => "comment-#{@c.id}"), notice: notice
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
    unless verify_recaptcha(action: 'contact', minimum_score: 0.35, secret_key: Settings.recaptcha_secret_key_v3)
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
