class ServiceBinding < BaseModel
  attr_accessor :id, :service_instance

  # Returns a given binding, if the Amazon user exists.
  def self.find_by_id(id)
    binding = new(id: id)
    
    iam = AWS::IAM.new
    user = iam.users[binding.username]
    if user.exists?
      binding
    end
  end

  # Returns a given binding, if it exists.
  def self.find_by_id_and_service_instance_id(id, instance_id)
    instance = ServiceInstance.new(id: instance_id)
    binding = new(id: id)

    iam = AWS::IAM.new
    user = iam.users[binding.username]
    if user.exists?
      binding
    end
  end

  # Checks to see if the given binding exists.
  #
  # NOTE: This method uses +find_by_id_and_service_instance_id+ to
  # verify true existence, and thus cannot currently be used by the
  # binding controller.
  def self.exists?(conditions)
    id = conditions.fetch(:id)
    instance_id = conditions.fetch(:service_instance_id)

    find_by_id_and_service_instance_id(id, instance_id).present?
  end

  def bucket
    service_instance.bucket
  end

  def group
    service_instance.group
  end

  def username
    Digest::MD5.base64digest(id).gsub(/[^a-zA-Z0-9]+/, '')[0...16]
  end

  def password
    @password ||= SecureRandom.base64(20).gsub(/[^a-zA-Z0-9]+/, '')[0...16]
  end

  def save
    iam = AWS::IAM.new
    user = iam.users.create(username)
    access_key = user.access_keys.create
    @credentials = access_key.credentials
    iamgroup = iam.groups[group].users
    iamgroup.add(user)
  end

  def destroy
    iam = AWS::IAM.new
    user = iam.users[username]
    if user.exists?
      keys = user.access_keys.first 
      keys.delete if !keys.nil?
      user.groups.clear
      user.delete
    end
  end

  def to_json(*)
    {
      'credentials' => {
        'bucket' => bucket,
        'username' => username,
        'password' => password,
        'access_key_id' => @credentials[:access_key_id],
        'secret_access_key' => @credentials[:secret_access_key],
        'uri' => uri,
      }
    }.to_json
  end

  private

  def uri
    s3 = AWS::S3.new
    bucket = s3.buckets[bucket]
    bucket.url
  end
end
