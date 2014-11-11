require 'spec_helper'

describe 'codedeploy' do
  let(:facts) {{
    :osfamily => 'RedHat',
  }}
  describe "codedeploy class without any parameters" do

    it { should compile.with_all_deps }

    it { should contain_class('codedeploy::params') }
    it { should contain_class('codedeploy::install') }
    it { should contain_class('codedeploy::service').that_subscribes_to('codedeploy::install') }

    it { should contain_service('codedeploy-agent') }
    it { should contain_package('codedeploy-agent')
      .with_ensure('present')
      .with_source('https://s3.amazonaws.com/aws-codedeploy-us-east-1/latest/codedeploy-agent.noarch.rpm')
    }
  end

  describe "codedeploy class with custom package source" do
    let(:params) {{ :package_source => 'https://example.com/package.rpm' }}
    it { should contain_package('codedeploy-agent').with_source('https://example.com/package.rpm') }
  end

  context 'unsupported operating system' do
    describe 'codedeploy class without any parameters on Solaris/Nexenta' do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta',
      }}

      it { expect { should contain_package('codedeploy') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
