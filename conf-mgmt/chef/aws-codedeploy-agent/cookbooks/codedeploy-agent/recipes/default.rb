remote_file "#{Chef::Config[:file_cache_path]}/codedeploy-agent.rpm" do
    source "https://s3.amazonaws.com/aws-codedeploy-us-east-1/latest/codedeploy-agent.noarch.rpm"
end

package "codedeploy-agent" do
	action :install
	source "#{Chef::Config[:file_cache_path]}/codedeploy-agent.rpm"
end

service "codedeploy-agent" do
	action [:enable, :start]
end
