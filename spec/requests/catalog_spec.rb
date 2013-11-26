require 'spec_helper'

describe 'GET /v2/catalog' do
  it 'returns the catalog of services' do
    get '/v2/catalog'

    expect(response.status).to eq(200)
    catalog = JSON.parse(response.body)

    services = catalog.fetch('services')
    expect(services).to have(1).service

    service = services.first
    expect(service.fetch('name')).to eq('cf-amazons3')
    expect(service.fetch('description')).to eq('Cloud Foundry Amazons3 Service')
    expect(service.fetch('bindable')).to be_true
    expect(service.fetch('metadata')).to eq(
      {
        'provider' => { 'name' => nil },
        'listing' => {
          'imageUrl' => nil,
          'blurb' => 'Amazons3 Service for testing and development',
        }
      }
    )

    plans = service.fetch('plans')
    expect(plans).to have(1).plan

    plan = plans.first
    expect(plan.fetch('name')).to eq('free2')
    expect(plan.fetch('description')).to eq('Free Trial')
    expect(plan.fetch('metadata')).to eq(
      {
        'cost' => 0.0,
        'bullets' => [
          { 'content' => 'Shared new bucket' },
          { 'content' => '100 MB storage' },
        ]
      }
    )
  end
end
