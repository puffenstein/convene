# frozen_string_literal: true

# Assembles Spaces idempotently
class Blueprint
  attr_accessor :attributes

  def self.prepare_clients!
    CLIENTS.each do |client_attributes|
      Blueprint.new(client_attributes).find_or_create!
    end
  end

  def initialize(attributes)
    @attributes = attributes
  end

  def find_or_create!
    space.update!(space_attributes.except(:name, :rooms, :members, :entrance, :utility_hookups))

    set_rooms
    set_utility_hookups
    set_members
    set_entrance
    space
  end

  private

  def set_rooms
    space_attributes.fetch(:rooms, []).each do |room_attributes|
      room = space.rooms.find_or_initialize_by(name: room_attributes[:name])
      room.update!(merge_non_empty(room.attributes, room_attributes).except(:name, :furniture_placements))
      add_furniture(room, room_attributes)
    end
  end

  def add_furniture(room, room_attributes)
    furniture_placements = room_attributes.fetch(:furniture_placements, {})
    furniture_placements.each.with_index do |(furniture, settings), slot|
      furniture_placement = room.furniture_placements
                                .find_or_initialize_by(slot: slot)
      furniture_placement
        .update!(settings: merge_non_empty(settings, furniture_placement.settings),
                 furniture_kind: furniture)
    end
  end

  def set_utility_hookups
    space_attributes.fetch(:utility_hookups, []).each do |utility_hookup_attributes|
      utility_hookup = space.utility_hookups
                            .find_or_initialize_by(name: utility_hookup_attributes[:name])

      utility_hookup.update!(merge_non_empty(utility_hookup_attributes, utility_hookup.attributes))
    end
  end

  def set_entrance
    if space_attributes[:entrance]
      space.update!(entrance: space.rooms.find_by!(slug: space_attributes[:entrance]))
    end
  end

  def set_members
    space_attributes.fetch(:members, []).each do |member_attributes|
      person = if member_attributes.is_a?(Person)
                 member_attributes
               else
                 Person.find_or_create_by!(email: member_attributes[:email])
                       .tap { |record| record.update!(member_attributes) }
               end

      space.memberships.find_or_create_by(member: person)
    end
  end

  def space
    @space ||= attributes[:space] || client.spaces.find_or_create_by!(name: space_attributes[:name])
  end

  def client
    @client ||= Client.find_or_create_by!(name: client_attributes[:name])
  end

  def client_attributes
    attributes[:client]
  end

  def space_attributes
    client_attributes[:space]
  end

  # Normally, merge will clobber keys with values if there is a key with a nil
  # or empty value. However, we don't want to do that here.
  # @example
  #   new = {  a: "ah", b: { c: :d } }
  #   original = { "a" => nil, "b" => {} }
  #   merge_non_empty(new, original)
  #   # => { "a" => "ah", "b": { c: :d }}
  private def merge_non_empty(left, right)
    right.delete_if do |_key, value|
      value.blank?
    end

    left.with_indifferent_access.merge(right.with_indifferent_access)
  end

  BLUEPRINTS = {
    system_test: {

      entrance: 'entrance-hall',
      utility_hookups: [
        { utility_slug: :plaid, name: 'Plaid', configuration: { client_id: 'set-me', secret: 'and-me', environment: 'sandbox' } },
        { utility_slug: :jitsi, name: 'Jitsi', configuration:
          { meet_domain: 'convene-videobridge-zinc.zinc.coop' } }
      ],
      members: [{ email: 'space-owner@example.com' },
                { email: 'space-member@example.com' }],
      rooms: [
        {
          name: 'Listed Room 1',
          publicity_level: :listed,
          access_level: :unlocked,
          access_code: nil,
          furniture_placements: {
            markdown_text_block: { content: '# Welcome!' },
            video_bridge: {},
            breakout_tables_by_jitsi: { names: %w[engineering design ops] }
          }
        },
        {
          name: 'Listed Room 2',
          publicity_level: :listed,
          access_level: :unlocked,
          access_code: nil,
          furniture_placements: {
            video_bridge: {}
          }
        },
        {
          name: 'Listed Locked Room 1',
          publicity_level: :listed,
          access_level: :locked,
          access_code: :secret,
          furniture_placements: {
            video_bridge: {}
          }
        },
        {
          name: 'Unlisted Room 1',
          publicity_level: :unlisted,
          access_level: :unlocked,
          access_code: nil,
          furniture_placements: {
            video_bridge: {}
          }
        },
        {
          name: 'Unlisted Room 2',
          publicity_level: :unlisted,
          access_level: :unlocked,
          access_code: nil,
          furniture_placements: {
            video_bridge: {}
          }
        },
        {
          name: 'Entrance Hall',
          publicity_level: :unlisted,
          furniture_placements: {
            markdown_text_block: { content: '# Wooo!' },
            spotlight: {},
          }

        }
      ]
    }
  }.with_indifferent_access

  # @todo migrate this to a private configuration file!
  CLIENTS = [{
    client: {
      name: 'Zinc',
      space: {
        members: [{ email: 'zee@zinc.coop' }, { email: 'cheryl@zinc.coop' }],
        name: 'Zinc', branded_domain: 'meet.zinc.coop',
        entrance: 'lobby',
        utility_hookups: [
          {
            utility_slug: :jitsi, name: 'Jitsi', configuration:
            { meet_domain: 'convene-videobridge-zinc.zinc.coop' }
          }
        ],
        rooms: [{
          name: 'Lobby',
          access_level: :unlocked,
          publicity_level: :unlisted,
          furniture_placements: {
            markdown_text_block: {}
          }
        }, {
          name: 'Ada',
          access_level: :unlocked,
          publicity_level: :listed,
          furniture_placements: {
            video_bridge: {}
          }
        }, {
          name: 'Talk to Zee',
          access_level: :unlocked,
          publicity_level: :unlisted,
          furniture_placements: {
            video_bridge: {}
          }
        }]
      }
    }
  }, {
    client: {
      name: 'Zinc',
      space: {
        name: 'Convene',
        entrance: 'landing-page',
        members: [{ email: 'zee@zinc.coop' }],
        rooms: [{
          name: 'Landing Page',
          access_level: :unlocked,
          publicity_level: :unlisted,
          furniture_placements: {
            markdown_text_block: {}
          }
        }]
      }
    }
  }].freeze
end
