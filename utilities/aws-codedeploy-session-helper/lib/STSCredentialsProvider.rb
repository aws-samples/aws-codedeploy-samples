require 'aws-sdk-core'
require 'socket'

class STSCredentialsProvider
    def initialize(args)
        raise ArgumentError.new("Param to STSCredentialsProvider.new() must be present, of type hash") if args.nil? or !args.is_a? Hash
        @role = args[:role]
        @creds_file = args[:creds_file]
        @region = args[:region]
        @session_name = args[:session_name]
        @duration = args[:duration]
        @output_arn = args[:output_arn]

        # Validation
        raise ArgumentError.new("No value for AWS IAM Role that the session credentials will assume, use --role-arn ROLE_ARN") if @role.nil?

        raise ArgumentError.new("No value for the fully qualified path that the session credentials will be written to, use --file FILEPATH") if @creds_file.nil?
        raise ArgumentError.new("Unable to write to directory " + File.dirname(@creds_file) + ".") unless File.writable?(File.dirname(@creds_file))
        raise ArgumentError.new("Unable to write to file " + @creds_file + ".") unless (File.exist?(@creds_file) ? File.writable?(@creds_file) : true)

        @session_name = Socket.gethostname if @session_name.nil?
    end

    def configure_aws_client
        Aws.use_bundled_cert!
        if !@region.nil?
            Aws.config.update({
                region: @region,
            })
        end
    end

    def get_session_creds
        sts = Aws::STS::Client.new
        return sts.assume_role({
            role_arn: @role,
            role_session_name: @session_name,
            duration_seconds: @duration
        })
    end

    def get
        configure_aws_client()
        resp = get_session_creds()

        if resp.nil? or resp.credentials.nil? or resp.credentials.access_key_id.nil? or resp.credentials.secret_access_key.nil? or resp.credentials.session_token.nil?
            raise RuntimeError.new("Unexpected response from call to AWS STS, did not have expected fields, response: #{resp.inspect}")
        end

        puts resp.assumed_role_user.arn if @output_arn

        str = "[default]\naws_access_key_id = #{resp.credentials.access_key_id}\naws_secret_access_key = #{resp.credentials.secret_access_key}\naws_session_token = #{resp.credentials.session_token}\n"
        begin
            file = File.open(@creds_file, "w")
            file.write(str)
        rescue IOError => e
            raise RuntimeError.new("Unable to write to file " + @creds_file + ". Error: #{e}")
        ensure
            file.close unless file.nil?
        end
    end
end
