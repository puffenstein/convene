# frozen_string_literal: true

# Default controller for new resources; ensures requests fulfill authentication
# and authorization requirements, as well as exposes common helper methods.
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  after_action :verify_authorized
  after_action :verify_policy_scoped
  before_action :prepend_theme_views

  rescue_from Pundit::NotAuthorizedError, with: :render_not_found
  prepend_view_path 'app/utilities'
  prepend_view_path 'app/furniture'

  protect_from_forgery with: :exception, unless: -> { api_request? }

  # Referenced in application layout to display page title
  # Override on a per-controller basis to display different title
  # @return [String]
  helper_method def page_title
    if current_space.present?
      "Convene - #{current_space.name}"
    else
      'Convene - Video Meeting Spaces'
    end
  end

  helper_method :current_person

  private

  OPERATOR_TOKEN = ENV['OPERATOR_API_KEY']
  # @return [Guest, Person, Operator] the authenticated user, or a Guest
  def current_person
    return @current_person if defined?(@current_person)

    if api_request?
      authenticate_or_request_with_http_token do |token, _options|
        ActiveSupport::SecurityUtils.secure_compare(token, OPERATOR_TOKEN)
      end

      @current_person = Operator.new
    else
      @current_person ||= Person.find_by(id: session[:person_id]) || Guest.new
    end
  end

  helper_method def editing?
    return true if params[:editing] == 'true'

    false
  end

  def default_url_options
    options = super

    return options unless editing?

    options.merge({ editing: params[:editing] })
  end

  def api_request?
    request.content_type == 'application/json'
  end

  def pundit_user
    current_person
  end

  # Retrieves the space based upon the requests domain or params
  # @return [nil, Space]
  helper_method def current_space
    @current_space ||=
      if params[:space_id]
        space_repository.friendly.find(params[:space_id])
      else
        BrandedDomainConstraint.new(space_repository).space_for_request(request) ||
          space_repository.friendly.find(params[:id])
      end.tap do |space|
        authorize(space, :show?)
      end
  rescue ActiveRecord::RecordNotFound
    begin
      @current_space ||= space_repository.default.tap { |space| authorize(space, :show?) }
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error("No default space exists!")
      @current_space = nil
    end
  end

  helper_method def current_membership
    @current_membership ||= if current_space.present? && current_person.present?
      current_space.memberships.find_by(member: current_person)
    end
  end

  def space_repository
    policy_scope(Space.includes(:rooms, entrance: [:furniture_placements]))
  end

  # Retrieves the room based upon the current_space and params
  # @return [nil, Room]
  helper_method def current_room
    @current_room ||=
      policy_scope(current_space.rooms).friendly.find(
        params[:room_id] || params[:id]
      )
                rescue ActiveRecord::RecordNotFound
                  nil
  end

  helper_method def current_access_code(room)
    session.dig(room.id, 'access_code')
  end

  def render_not_found
    render file: "#{Rails.root}/public/404.html", layout: false, status: 404
  end

  # Ensure the Theme views and partials are first in the View lookup path
  # This allows us to override Application and Furniture views in favor of
  # the theme specific ones.
  def prepend_theme_views
    return unless current_space&.theme.present?

    prepend_view_path "app/themes/#{current_space.theme}/"
  end
end
