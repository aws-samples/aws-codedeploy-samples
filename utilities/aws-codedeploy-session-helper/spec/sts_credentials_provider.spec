require 'aws-sdk'
require 'simplecov'
SimpleCov.start
SimpleCov.minimum_coverage_by_file 100

require_relative '../lib/STSCredentialsProvider'

describe STSCredentialsProvider do
    describe "initilize" do
        it "errors on nil everything" do
            expect{STSCredentialsProvider.new({})}.to raise_error(ArgumentError)
        end
        it "errors on nil role" do
            expect{STSCredentialsProvider.new({creds_file: "file"})}
                .to raise_error(ArgumentError, "No value for AWS IAM Role that the session credentials will assume, use --role-arn ROLE_ARN")
        end
        it "errors on nil cred file loc" do
            expect{STSCredentialsProvider.new({role: "role"})}
                .to raise_error(ArgumentError, "No value for the fully qualified path that the session credentials will be written to, use --file FILEPATH")
        end
    end

    describe "configure_aws_client" do
        it "provides region if value is present" do
            config_hash = {}
            aws_stub = class_double("Aws").as_stubbed_const
            expect(config_hash).to receive(:update).with({region: "us-east-1"})
            expect(aws_stub).to receive(:config).and_return(config_hash)
            expect(aws_stub).to receive(:use_bundled_cert!)

            aws_creds_stub = class_double("Aws::Credentials").as_stubbed_const
            expect(aws_creds_stub).not_to receive("new")

            provider = STSCredentialsProvider.new({
                                role: "role",
                                creds_file: "file",
                                region: "us-east-1"
                            })
            provider.instance_eval{ configure_aws_client }
        end
    end

    describe "get_session_creds" do
        it "passes arguments to STS client" do
            sts_response = {}
            sts = {}
            sts_stub = class_double("Aws::STS::Client").as_stubbed_const
            expect(sts_stub).to receive("new").and_return(sts)
            expect(sts).to receive("assume_role").with({
                    role_arn: "role",
                    role_session_name: "session1",
                    duration_seconds: 1234
                }).and_return(sts_response)

            provider = STSCredentialsProvider.new({
                                role: "role",
                                creds_file: "file",
                                session_name: "session1",
                                region: "us-east-1",
                                duration: 1234
                            })
            provider.instance_eval{ get_session_creds }
        end
    end

    describe "get" do
        it "calls expected setup methods and attempts to write to file" do
            ENV['AWS_REGION'] = ""

            file_class_stub = class_double("File").as_stubbed_const
            allow(file_class_stub).to receive(:dirname).with("file").and_return "dir"
            allow(file_class_stub).to receive(:writable?).with("dir").and_return true
            allow(file_class_stub).to receive(:exist?).with("file").and_return true
            allow(file_class_stub).to receive(:writable?).with("file").and_return true

            file_stub = instance_double(File)
            expect(File).to receive(:open).with("file", "w").and_return(file_stub)
            expect(file_stub).to receive(:write).with("[default]\naws_access_key_id = akid\naws_secret_access_key = sak\naws_session_token = token\n")
            expect(file_stub).to receive(:close)

            resp = {}
            credentials = {}
            allow(resp).to receive(:credentials).and_return(credentials)
            allow(credentials).to receive(:access_key_id).and_return("akid")
            allow(credentials).to receive(:secret_access_key).and_return("sak")
            allow(credentials).to receive(:session_token).and_return("token")

            provider = STSCredentialsProvider.new({
                role: "role",
                creds_file: "file",
                region: "region",
                session_name: "session1",
                duration: 1234})
            expect(provider).to receive(:configure_aws_client)
            expect(provider).to receive(:get_session_creds).and_return(resp)
            provider.get()
        end

        it "catches ioerror then raises ArgumentError and closes file" do
            file_stub = instance_double(File)
            expect(File).to receive(:open).with("file", "w").and_return(file_stub)
            expect(file_stub).to receive(:write).with("[default]\naws_access_key_id = akid\naws_secret_access_key = sak\naws_session_token = token\n").and_raise(IOError.new("error"))
            expect(file_stub).to receive(:close)

            resp = {}
            credentials = {}
            allow(resp).to receive(:credentials).and_return(credentials)
            allow(credentials).to receive(:access_key_id).and_return("akid")
            allow(credentials).to receive(:secret_access_key).and_return("sak")
            allow(credentials).to receive(:session_token).and_return("token")

            provider = STSCredentialsProvider.new({
                role: "role",
                creds_file: "file"
            })
            expect(provider).to receive(:configure_aws_client)
            expect(provider).to receive(:get_session_creds).and_return(resp)
            expect{provider.get()}
                .to raise_error(RuntimeError)
        end

        it "throws exception on nil response from sts" do
            ENV['AWS_REGION'] = ""
            provider = STSCredentialsProvider.new({
                role: "role",
                creds_file: "file"
            })
            expect(provider).to receive(:configure_aws_client)
            expect(provider).to receive(:get_session_creds).and_return(nil)
            expect{provider.get()}
                .to raise_error(RuntimeError)
        end
        it "throws exception on nil credentials field from sts" do
            ENV['AWS_REGION'] = ""
            provider = STSCredentialsProvider.new({
                role: "role",
                creds_file: "file",
            })
            resp = {}
            allow(resp).to receive(:credentials).and_return(nil)

            expect(provider).to receive(:configure_aws_client)
            expect(provider).to receive(:get_session_creds).and_return(resp)
            expect{provider.get()}
                .to raise_error(RuntimeError)
        end
        it "throws exception on nil credentials.akid field from sts" do
            ENV['AWS_REGION'] = ""
            provider = STSCredentialsProvider.new({
                role: "role",
                creds_file: "file",
            })
            resp = {}
            credentials = {}
            allow(resp).to receive(:credentials).and_return(credentials)
            expect(credentials).to receive(:access_key_id).and_return(nil)
            allow(credentials).to receive(:secret_access_key).and_return("sak")
            allow(credentials).to receive(:session_token).and_return("token")
            expect(provider).to receive(:configure_aws_client)
            expect(provider).to receive(:get_session_creds).and_return(resp)
            expect{provider.get()}
                .to raise_error(RuntimeError)
        end
        it "throws exception on nil credentials.sak field from sts" do
            ENV['AWS_REGION'] = ""
            provider = STSCredentialsProvider.new({
                role: "role",
                creds_file: "file",
            })
            resp = {}
            credentials = {}
            allow(resp).to receive(:credentials).and_return(credentials)
            allow(credentials).to receive(:access_key_id).and_return("akid")
            expect(credentials).to receive(:secret_access_key).and_return(nil)
            allow(credentials).to receive(:session_token).and_return("token")
            expect(provider).to receive(:configure_aws_client)
            expect(provider).to receive(:get_session_creds).and_return(resp)
            expect{provider.get()}
                .to raise_error(RuntimeError)
        end
        it "throws exception on nil credentials.token field from sts" do
            ENV['AWS_REGION'] = ""
            provider = STSCredentialsProvider.new({
                role: "role",
                creds_file: "file",
            })
            resp = {}
            credentials = {}
            allow(resp).to receive(:credentials).and_return(credentials)
            allow(credentials).to receive(:access_key_id).and_return("akid")
            allow(credentials).to receive(:secret_access_key).and_return("sak")
            expect(credentials).to receive(:session_token).and_return(nil)
            expect(provider).to receive(:configure_aws_client)
            expect(provider).to receive(:get_session_creds).and_return(resp)
            expect{provider.get()}
                .to raise_error(RuntimeError)
        end
    end
end
