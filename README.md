## README Amazon s3 Service broker

Cloudfoundry allows you to write your own Service Broker, check out this Documentation:
http://docs.cloudfoundry.com/docs/running/architecture/services/writing-service.html

This is a Service Broker for Cloudfoundry which can be used for Amazon s3 Storage as a service.
Once a new service is created in your Cloudfoundry target system, it creates a new bucket, a new user group 
and a new policy for this user group.
Later if you bind this service to any of your apps, it creates a new user and adds this user to the user
group, wich was created before.

## Configuration 
Please insert your Amazon s3 account credentials in file <b>config/initializers/aws.rb</b>.
It is important to set your own password in <b>config/settings.yml</b>, this credentials were used by the cloud controller to contact your application.

## Running Tests

The CF Amazon s3 Broker integration specs will exercise the catalog fetch, create, bind, unbind, and delete functions with your amazon s3 account.

1. Run the following commands

```
$ cd cf-s3-broker
$ bundle install
$ bundle exec rake spec
```

## Add service broker
To add your service broker to your current cloudfoundry installation use:
$ cf add-service-broker
  user and password from config/settings.yml
  
## ToDo
Need Quta enforcer, please contact if you have a good idea to solve this problem.
Thanks.