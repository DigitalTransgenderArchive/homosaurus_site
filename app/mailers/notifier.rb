class Notifier < ActionMailer::Base
  extend ActiveSupport::Concern

  def self.local_config
    @local_config ||= YAML::load(File.open(config_path))[env]
                    .with_indifferent_access
  end

  def self.app_root
    return @app_root if @app_root
    @app_root = Rails.root if defined?(Rails) and defined?(Rails.root)
    @app_root ||= APP_ROOT if defined?(APP_ROOT)
    @app_root ||= '.'
  end

  def self.env
    return @env if @env
    #The following commented line always returns "test" in a rails c production console. Unsure of how to fix this yet...
    #@env = ENV["RAILS_ENV"] = "test" if ENV
    @env ||= Rails.env if defined?(Rails) and defined?(Rails.root)
    @env ||= 'development'
  end

  def self.config_path
    File.join(app_root, 'config', 'contact_emails.yml')
  end

  def support_bcc_emails
    @support_bcc_emails ||= Notifier.local_config[:support_bcc_emails]
  end

  def general_email
    @general_email ||= Notifier.local_config[:general_email]
  end

  def feedback(details)

    @message = details[:message]
    @topic = details[:topic]
    @email = details[:email]
    @name = details[:name]
    @recipient = route_email(details[:topic])

    if (details[:topic] == 'error' || details[:topic] == 'Broken link / site error') && support_bcc_emails.present?
      mail(:to => @recipient,
           :from => "Homosaurus" + ' <' + "homosaurusvocab@gmail.com" + '>',
           :subject => "Homosaurus: Contact Form: " + details[:topic].capitalize,
            :bcc => support_bcc_emails)
    else
      mail(:to => @recipient,
           :from => "Homosaurus" + ' <' + "homosaurusvocab@gmail.com" + '>',
           :subject => "Homosaurus: Contact Form: " + details[:topic].capitalize)
    end


  end

  private

  def route_email(topic)
    general_email
  end



end