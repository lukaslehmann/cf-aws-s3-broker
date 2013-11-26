require 'spec_helper'

describe ServiceBinding do
  let(:id) { '88f6fa22-c8b7-4cdc-be3a-dc09ea7734db' }
  let(:binding) { ServiceBinding.new(id: id, service_instance: instance) }

  let(:instance_id) { '88f6fa22-c8b7-4cdc-be3a-dc09ea7734db' }
  let(:instance) { ServiceInstance.new(id: instance_id) }
  let(:bucket) { instance.bucket }

  before do
    instance.save
  end

  after do
    instance.destroy
    binding.destroy
  end

  describe '.find_by_id' do
    context 'when the user exists' do
      it 'returns the binding' do
        binding.destroy
        binding.save
        binding = ServiceBinding.find_by_id(id)
        expect(binding).to be_a(ServiceBinding)
        expect(binding.id).to eq(id)
      end
    end

    context 'when the user does not exist' do
      it 'returns nil' do
        binding = ServiceBinding.find_by_id(id)
        expect(binding).to be_nil
      end
    end
  end

  describe '.find_by_id_and_service_instance_id' do
    context 'when the user exists' do
      before { binding.save }

      it 'returns the binding' do
        binding = ServiceBinding.find_by_id_and_service_instance_id(id, instance_id)
        expect(binding).to be_a(ServiceBinding)
        expect(binding.id).to eq(id)
      end
    end

    context 'when the user does not exist' do
      it 'returns nil' do
        binding = ServiceBinding.find_by_id_and_service_instance_id(id, instance_id)
        expect(binding).to be_nil
      end
    end
  end

  describe '.exists?' do
    context 'when the user exists and has the policy' do
      before { binding.save }

      it 'returns true' do
        expect(ServiceBinding.exists?(id: id, service_instance_id: instance_id)).to eq(true)
      end
    end

    context 'when the user does not exist' do
      it 'returns false' do
        expect(ServiceBinding.exists?(id: id, service_instance_id: instance_id)).to eq(false)
      end
    end
  end

  describe '#username' do
    it 'returns the same username for a given id' do
      binding1 = ServiceBinding.new(id: 'some_id')
      binding2 = ServiceBinding.new(id: 'some_id')
      expect(binding1.username).to eq (binding2.username)
    end

    it 'returns different usernames for different ids' do
      binding1 = ServiceBinding.new(id: 'some_id')
      binding2 = ServiceBinding.new(id: 'some_other_id')
      expect(binding2.username).to_not eq (binding1.username)
    end

    it 'returns only alphanumeric characters' do
      binding = ServiceBinding.new(id: '~!@#$%^&*()_+{}|:"<>?')
      expect(binding.username).to match /^[a-zA-Z0-9]+$/
    end

    it 'returns no more than 16 characters' do
      binding = ServiceBinding.new(id: 'fa790aea-ab7f-41e8-b6f9-a2a1d60403f5')
      binding.destroy
      expect(binding.username.length).to be <= 16
    end
  end

  describe '#save' do
    before { binding.save }

    it 'creates a new user' do
      iam = AWS::IAM.new
      user = iam.users[binding.username]
      expect(user.exists?).to eq(true)
    end

    it 'adds the new user to the group' do
      iam = AWS::IAM.new
      user = iam.users[binding.username]
      exp_group = user.groups.detect{|w| w.name == instance.group}
      expect(exp_group.name).to eq(instance.group)      
    end

    it 'raises an error when creating the same user twice' do
      expect {
           ServiceBinding.new(id: id, service_instance: instance).save
         }.to raise_error
    end
  end

  describe '#destroy' do
    context 'when the user exists' do
      before { binding.save }

      it 'deletes the user' do
        iam = AWS::IAM.new
        binding.destroy
        user = iam.users[binding.username]
        expect(user.exists?).to eq(false)      
      end
    end

    context 'when the user does not exist' do
      it 'does not raise an error' do
        expect {
          binding.destroy
        }.to_not raise_error

        iam = AWS::IAM.new
        user = iam.users[binding.username]
        expect(user.exists?).to eq(false)      
      end
    end
  end

  describe '#to_json' do
    let(:url) { AWS::S3.new.buckets[instance.bucket].url }    
    
    before { binding.save }
    
    it 'includes the credentials' do
      hash = JSON.parse(binding.to_json)
      credentials = hash.fetch('credentials')
      expect(credentials.fetch('bucket')).to eq(instance.bucket)
      expect(credentials.fetch('username')).to eq(binding.username)
      expect(credentials.fetch('password')).to eq(binding.password)
    end
  end
end
