Gem::Specification.new do |s|
  s.name        = 'aws-codedeploy-session-helper'
  s.version     = '0.9.0'
  s.date        = '2016-12-27'
  s.summary     = "This tool helps grab AWS STS credentials, useful when using CodeDeploy OnPremises instances with IAM Sessions."
  s.description = "See readme of the code on GitHub, https://github.com/aws-labs/aws-codedeploy-samples/tree/master/utilities/aws-codedeploy-session-helper"
  s.authors     = ["Ryan Gorup"]
  s.email       = 'gorup@amazon.com'
  s.files       = ["lib/STSCredentialsProvider.rb"]
  s.executables = ["get_sts_creds"]
  s.homepage    =
    'https://github.com/aws-labs/aws-codedeploy-samples/tree/master/utilities/aws-codedeploy-session-helper'
  s.license       = 'Apache-2.0'

  s.add_runtime_dependency('aws-sdk-core', '~> 2.6')
  s.add_development_dependency('rake', '~> 12.3.3')
  s.add_development_dependency('simplecov', '~> 0.12')
  s.add_development_dependency('rspec', '~> 3.5')
end
