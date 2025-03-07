# frozen_string_literal: true

# A Space is a collection of infrastructure resources
# for collaboration
class Space < ApplicationRecord
  THEME_OPTIONS = %w[purple_mountains desert_dunes].freeze

  # Which client owns the space
  belongs_to :client

  accepts_nested_attributes_for :client

  # The fully-qualified domain to enter the space.
  # Spaces without a branded_domain are still accessible via their slug.
  # The branded_domain must be unique to ensure we don't accidentally place
  # a visitor into the wrong space.
  attribute :branded_domain, :string
  validates :branded_domain, uniqueness: true, allow_nil: true

  # The human-friendly name for the space
  attribute :name, :string
  validates :name, presence: true, uniqueness: true

  # The URI-friendly name for the space
  attribute :slug, :string
  validates :slug, uniqueness: true

  validates :theme, inclusion: { in: THEME_OPTIONS }, if: ->(s) { s.theme.present? }

  # FriendlyId's does the legwork to make the slug uri-friendly
  extend FriendlyId

  friendly_id :name, use: :slugged

  # Joins People to spaces for permissioning and
  # other purposes
  has_many :memberships, inverse_of: :space, dependent: :destroy_async

  # The People with permissions for the Space
  has_many :members, through: :memberships

  # Inviting new members
  has_many :invitations, inverse_of: :space, dependent: :destroy_async

  # The Rooms within this Space
  has_many :rooms, inverse_of: :space, dependent: :destroy_async

  # All the items held within the space
  has_many :items, inverse_of: :space, dependent: :destroy_async

  belongs_to :entrance, class_name: 'Room', optional: true

  scope :default, -> { friendly.find(Neighborhood.config.default_space_slug) }

  # @see {Utilities}
  # @see {UtilityHookup}
  # @returns {ActiveRecord::Relation<UtilityHookups>}
  has_many :utility_hookups, dependent: :destroy_async

  def jitsi_meet_domain
    jitsi_hookup = utility_hookups.find_by(utility_slug: :jitsi)
    return if jitsi_hookup.blank?

    Utilities.from_utility_hookup(jitsi_hookup).meet_domain
  end
end
