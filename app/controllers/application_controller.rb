class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_locale
  before_action :sign_out_if_inactive, if: -> { current_user.present? && !current_user.active }

  rescue_from ActionController::RoutingError, :with => :not_found
  respond_to :json, :xml, :html

  def index
    decorate_user_if_present
    programs = Program.featured

    @data = {
        :currentUser => @user,
        :programs => programs
    }

    render :index
  end

  def about_page
    decorate_user_if_present

    about_page_content = AboutPages.last
    about_page_content = {
        :en => about_page_content[:description],
        :es => about_page_content[:spanish_description]
    }

    @data = {
        :currentUser => @user,
        :about_page_content => about_page_content
    }

    render :about_page
  end

  def t_and_c
    decorate_user_if_present

    terms_and_conditions = TermsAndConditions.last
    terms_and_conditions = terms_and_conditions[:description]

    @data = {
        :currentUser => @user,
        :terms_and_conditions => terms_and_conditions
    }

    render :t_and_c
  end

  def not_found
    decorate_user_if_present

    @data = {
        :currentUser => @user
    }
  end

  def set_locale
    params.permit(:locale)
    I18n.locale = params[:locale] || I18n.default_locale
  end

  protected

  def authenticate_admin_user!
    unless user_signed_in? || request.referer != new_user_session_path
      user = User.find_by_email!(params[:user][:email])

      if user.admin?
        authenticate_user!
      else
        redirect_to root_path and return
      end
    end
  end

  def after_sign_in_path_for(resource)
    session["user_return_to"] || root_url
  end

  def access_denied(exception)
    redirect_to root_path, alert: exception.message
  end

  def configure_permitted_parameters
    attributes = [ :thumbnail_image ]
    devise_parameter_sanitizer.permit(:sign_in, keys: attributes)
    devise_parameter_sanitizer.permit(:sign_up, keys: attributes)
    devise_parameter_sanitizer.permit(:account_update, keys: attributes)
  end

  private

  def decorate_user_if_present
    if current_user
      user = UserDecorator.new(current_user)
      @user = user.simple_decorate
    else
      @user = { }
    end
  end

  def sign_out_if_inactive
    sign_out
  end
end
