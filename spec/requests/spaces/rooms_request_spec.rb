# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe '/spaces/:space_slug/room/', type: :request do
  let(:space) { create(:space) }

  path '/spaces/{space_slug}/rooms/{room_slug}' do
    parameter name: :space_slug, in: :path, type: :string
    parameter name: :room_slug, in: :path, type: :string
    let(:api_key) { ENV['OPERATOR_API_KEY'] }
    let(:Authorization) { encode_authorization_token(api_key) }
    include ApiHelpers::Path

    let(:space_slug) { space.slug }
    let(:room_slug) { room.slug }

    get 'Returns the Room Resource' do
      tags 'Room'
      security [api_key: []]
      produces 'application/json'
      consumes 'application/json'

      let(:room) { create(:room, :with_furniture, space: space) }

      response '200', 'Room retrieved' do
        run_test! do |response|
          data = response_data(response)
          furniture_data = room.furniture_placements
                               .map(&FurniturePlacement::Serializer.method(:new))
                               .map(&:to_json)
          expect(data[:room]).to eq(id: room.id, name: room.name,
                                    slug: room.slug,
                                    furniture_placements: furniture_data)
        end
      end
    end

    put 'Modifies the Room' do
      tags 'Room'
      security [api_key: []]
      produces 'application/json'
      consumes 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          room: {
            type: :object,
            properties: {
              name: { type: :string, example: 'Fancy Room' },
              slug: { type: :string, example: 'fancy-room' },
              furniture_placements_attributes: {
                type: :array,
                items: {
                  type: :object,
                  properties: {}
                }
              }
            }
          }
        },
        required: ['room']
      }

      let(:body) { { room: attributes } }

      response '200', 'Room updated with furniture' do
        let(:room) { create(:room, space: space) }
        let(:attributes) do
          { name: 'A new name', furniture_placements_attributes: [attributes_for(:furniture_placement)] }
        end

        run_test! do
          data = response_data(response)
          expect(data[:room][:name]).to eq('A new name')
          expect(data[:room][:furniture_placements]).to be_present
        end
      end
    end
  end
  describe 'GET /spaces/:space_slug/rooms/new' do
    let(:path) { new_space_room_path(space) }

    context 'when the person is a guest' do
      it 'does not allow access to the new room form' do
        get path
        expect(response).not_to have_http_status(:success)
      end
    end

    context 'when the person is a space member' do
      let(:membership) { create(:membership, space: space) }
      let!(:person) { membership.member }

      before { sign_in(space, person) }

      it 'allows access to the new room form' do
        get path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'DELETE /spaces/:space_slug/rooms/:room_slug' do
    let(:room) { create(:room, space: space) }
    let(:path) { space_room_path(room.space, room) }
    context 'when the person is a guest' do
      it 'does not remove the room' do
        delete path
        expect(room.reload).to be_present
        expect(response).not_to have_http_status(:success)
      end
    end

    context 'when the person is a space member' do
      let(:membership) { create(:membership, space: space) }
      let!(:person) { membership.member }

      before { sign_in(space, person) }

      it 'removes the room' do
        delete path
        expect { room.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to redirect_to(edit_space_path(room.space))
        expect(flash[:notice]).to eql(I18n.t('rooms.destroy.success', room_name: room.name))
      end
    end
  end

  describe 'POST /spaces/:space_slug/room' do
    let(:path) { space_rooms_path(space) }
    let(:room_params) { attributes_for(:room, :with_slug, space: space) }
    subject(:do_request) { post path, params: { room: room_params } }

    context 'when the person is a guest' do
      it 'does not allow creating a new room' do
        do_request
        expect(response).not_to have_http_status(:success)
      end
    end

    context 'when the person is a space member' do
      let(:membership) { create(:membership, space: space) }
      let!(:person) { membership.member }

      before { sign_in(space, person) }

      it 'creates a new room' do
        expect { do_request }.to change(Room, :count).by(1)
      end

      it 'redirects to the edit path for the new room' do
        do_request
        expect(response).to redirect_to(edit_space_room_path(space, room_params[:slug]))
      end
    end
  end
end
