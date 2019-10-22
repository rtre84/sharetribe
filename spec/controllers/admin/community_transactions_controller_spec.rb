require 'spec_helper'

describe Admin::CommunityTransactionsController, type: :controller do
  let(:community) { FactoryGirl.create(:community) }
  let(:person1) do
    FactoryGirl.create(:person, member_of: community,
                                given_name: 'Florence',
                                family_name: 'Torres',
                                display_name: 'Floryt'
                      )
  end
  let(:person2) do
    FactoryGirl.create(:person, member_of: community,
                                given_name: 'Sherry',
                                family_name: 'Rivera',
                                display_name: 'Sky caterpillar'
                      )
  end
  let(:person3) do
    FactoryGirl.create(:person, member_of: community,
                                given_name: 'Connie',
                                family_name: 'Brooks',
                                display_name: 'Candidate'
                      )
  end
  let(:listing1) do
    FactoryGirl.create(:listing, community_id: community.id,
                                 title: 'Apple cake',
                                 author: person1)
  end
  let(:listing2) do
    FactoryGirl.create(:listing, community_id: community.id,
                                 title: 'Cosmic scooter',
                                 author: person1)
  end
  let(:transaction1) do
    FactoryGirl.create(:transaction, community: community,
                                     listing: listing1,
                                     starter: person2,
                                     current_state: 'confirmed',
                                     last_transition_at: 1.minute.ago)
  end
  let(:transaction2) do
    FactoryGirl.create(:transaction, community: community,
                                     listing: listing2,
                                     starter: person2,
                                     current_state: 'paid',
                                     last_transition_at: 30.minutes.ago)

  end
  let(:transaction3) do
    conversation = FactoryGirl.create(:conversation, community: community, last_message_at: 20.minutes.ago)
    FactoryGirl.create(:transaction, community: community,
                                     listing: listing1,
                                     starter: person3,
                                     current_state: 'rejected',
                                     last_transition_at: 60.minutes.ago,
                                     conversation: conversation)
  end

  before(:each) do
    @request.host = "#{community.ident}.lvh.me"
    @request.env[:current_marketplace] = community
    user = create_admin_for(community)
    sign_in_for_spec(user)
    transaction1
    transaction2
    transaction3
  end

  describe '#index' do
    it 'works' do
      get :index, params: {community_id: community.id}
      service = assigns(:service)
      transactions = service.transactions
      expect(transactions.count).to eq 3
    end

    it 'filters by party or listing title' do
      get :index, params: {community_id: community.id, q: 'Florence'}
      service = assigns(:service)
      transactions = service.transactions
      expect(transactions.count).to eq 3
      get :index, params: {community_id: community.id, q: 'Sky cat'}
      service = assigns(:service)
      transactions = service.transactions
      expect(transactions.count).to eq 2
      expect(transactions.include?(transaction1)).to eq true
      expect(transactions.include?(transaction2)).to eq true
      get :index, params: {community_id: community.id, q: 'Apple cake'}
      service = assigns(:service)
      transactions = service.transactions
      expect(transactions.count).to eq 2
      expect(transactions.include?(transaction1)).to eq true
      expect(transactions.include?(transaction3)).to eq true
    end

    it 'filters by status' do
      get :index, params: {community_id: community.id, status: 'confirmed'}
      service = assigns(:service)
      transactions = service.transactions
      expect(transactions.count).to eq 1
      expect(transactions.include?(transaction1)).to eq true
    end

    it 'sort' do
      get :index, params: {community_id: community.id}
      service = assigns(:service)
      transactions = service.transactions
      expect(transactions.count).to eq 3
      expect(transactions[0]).to eq transaction1
      expect(transactions[1]).to eq transaction3
      expect(transactions[2]).to eq transaction2
      get :index, params: {community_id: community.id, direction: 'asc'}
      service = assigns(:service)
      transactions = service.transactions
      expect(transactions.count).to eq 3
      expect(transactions[0]).to eq transaction2
      expect(transactions[1]).to eq transaction3
      expect(transactions[2]).to eq transaction1
    end
  end
end
