class ServiceInstance < BaseModel
  attr_accessor :id
  BUCKET_PREFIX = 'cf'.freeze
  GROUP_PREFIX = 'cfgrp'.freeze

  def self.find_by_id(id)
    instance = new(id: id)
    s3 = AWS::S3.new 
    iambucket = s3.buckets[instance.bucket]
    iamgroup = instance.group
    instance if iambucket.exists?
  end

  def self.find(id)
    find_by_id(id) || raise("Couldn't find ServiceInstance with id=#{id}")
  end

  def self.exists?(id)
    find_by_id(id).present?
  end

  def self.get_number_of_existing_instances
    s3 = AWS::S3.new
    s3.buckets.count
  end

  def bucket
    @bucket ||= begin
      # bucket names are limited to [0-9,a-z,A-Z$_] and 64 chars
      if id =~ /[^0-9,a-z,A-Z$-]+/
        raise 'Only ids matching [0-9,a-z,A-Z$-]+ are allowed'
      end

      bucket = id.gsub('-', '')

      "#{BUCKET_PREFIX}#{bucket}"      
    end
  end

  def group
    @group ||= begin
      # group names are limited to [0-9,a-z,A-Z$_] and 64 chars
      if id =~ /[^0-9,a-z,A-Z$-]+/
        raise 'Only ids matching [0-9,a-z,A-Z$-]+ are allowed'
      end

      group = id.gsub('-', '')

      "#{GROUP_PREFIX}#{group}"
    end
  end

  def save
    begin
      s3 = AWS::S3.new
      iambucket = s3.buckets.create(bucket)
      iam = AWS::IAM.new
      iamgroup = iam.groups.create(group)
    rescue AWS::Errors => e
      raise
    end

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

  def destroy
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

  def to_json(*)
    {
      'dashboard_url' => 'http://console.amazons3.com'
    }.to_json
  end
end
