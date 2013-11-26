require 'spec_helper'

describe ServiceInstance do
  let(:id) { '88f6fa22-c8b7-4cdc-be3a-dc09ea7734db' }
  let(:bucket) { 'cf88f6fa22c8b74cdcbe3adc09ea7734db' }
  let(:group) { 'cfgrp88f6fa22c8b7_4cdcbe3adc09ea7734db' }
  let(:instance) { ServiceInstance.new(id: id) }

  before do
    s3 = AWS::S3.new
    iambucket = s3.buckets.create(bucket)

    iam = AWS::IAM.new
    iamgroup = iam.groups.create(group)

    policy = AWS::IAM::Policy.new
    policy.allow(actions:["s3:AbortMultipartUpload",
                          "s3:CreateObject",
                          "s3:DeleteObject",
                          "s3:DeleteObjectVersion",
                          "s3:GetBucketLogging",
                          "s3:GetBucketNotification",
                          "s3:GetBucketWebsite",                     
                          "s3:GetObject",
                          "s3:GetObjectAcl",
                          "s3:GetObjectTorrent",
                          "s3:GetObjectVersion",
                          "s3:GetObjectVersionAcl",
                          "s3:GetObjectVersionTorrent",
                          "s3:ListBucket",
                          "s3:ListBucketMultipartUploads",
                          "s3:ListBucketVersions",
                          "s3:ListMultipartUploadParts",
                          "s3:PutBucketLogging",
                          "s3:PutBucketNotification",
                          "s3:PutBucketVersioning",
                          "s3:PutBucketWebsite",
                          "s3:PutObject",
                          "s3:PutObjectAcl",
                          "s3:PutObjectVersionAcl"], 
                  resources:"arn:aws:s3:::#{bucket}/*")
    iamgroup.policies["cf_access"] = policy
  end

  after do
    iam = AWS::IAM.new
    iamgroup = iam.groups[group]
    if iamgroup.exists?
      iamgroup.policies.clear
      iamgroup.users.clear
      iamgroup.delete         
    end

    s3 = AWS::S3.new
    iambucket = s3.buckets[bucket]
    if iambucket.exists?
      iambucket.delete!   
    end

  end

  describe '.find_by_id' do
    context 'when the bucket exists' do
      it 'returns the instance' do
        instance = ServiceInstance.find_by_id(id)
        expect(instance).to be_a(ServiceInstance)

        expect(instance.id).to eq(id)
      end
    end

    context 'when the bucket does not exist' do
      it 'returns nil' do
        instance = ServiceInstance.find_by_id('000192129')
        expect(instance).to be_nil
      end
    end
  end

  describe '.find' do
    context 'when the bucket exists' do
      it 'returns the instance' do
        instance = ServiceInstance.find(id)
        expect(instance).to be_a(ServiceInstance)
        expect(instance.id).to eq(id)
      end
    end

    context 'when the bucket does not exist' do
      it 'raises an error' do
        expect {ServiceInstance.find('000192129')}.to raise_error
      end
    end
  end

  describe '.exists?' do
    context 'when the bucket exists' do
      it 'returns true' do
        expect(ServiceInstance.exists?(id)).to eq(true)
      end
    end

    context 'when the bucket does not exist' do
      it 'returns false' do
        expect(ServiceInstance.exists?('000192129')).to eq(false)
      end
    end
  end

  describe '.get_number_of_existing_instances' do
    context 'when the bucket exists' do
      it 'returns the number of instances' do
        expect(ServiceInstance.get_number_of_existing_instances).not_to eq(0)
      end
    end
  end

  describe '#save' do
    it 'created bucket exists' do
      instance.destroy
      instance.save
      s3 = AWS::S3.new
      iambucket = s3.buckets[instance.bucket]
      expect(iambucket.exists?).to eq(true)
    end
  end

  describe '#destroy' do
    it 'delets the bucket' do
      instance.destroy
      s3 = AWS::S3.new
      iambucket = s3.buckets[instance.bucket]
      expect(iambucket.exists?).to eq(false)
    end
  end

  describe '#database' do
    it 'returns a namespaced, amazon-safe group name from the id' do
      instance = ServiceInstance.new(id: '88f6fa22-c8b7-4cdc-be3a-dc09ea7734db')
      expect(instance.bucket).to eq('cf88f6fa22c8b74cdcbe3adc09ea7734db')
    end

    it 'returns a namespaced, amazon-safe bucket name from the id' do
      instance = ServiceInstance.new(id: '88f6fa22-c8b7-4cdc-be3a-dc09ea7734db')
      expect(instance.group).to eq('cfgrp88f6fa22c8b74cdcbe3adc09ea7734db')
    end
    context 'when there are strange characters in the id' do
      let(:instance) { ServiceInstance.new(id: '!@\#$%^&*() ;') }

      it 'raises an error' do
        expect {
          instance.bucket
        }.to raise_error
      end
    end
  end

  describe '#to_json' do
    it 'includes a dashboard_url' do
      hash = JSON.parse(instance.to_json)
      expect(hash.fetch('dashboard_url')).to eq('http://console.amazons3.com')
    end
  end
end
