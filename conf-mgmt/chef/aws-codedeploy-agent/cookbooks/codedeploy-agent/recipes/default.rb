remote_file "#{Chef::Config[:file_cache_path]}/codedeploy-agent-install" do
    source "https://s3.amazonaws.com/aws-codedeploy-us-east-1/latest/install"
    mode 0755
end

bash "install-codedeploy-agent" do
  code <<-EOH
    #{Chef::Config[:file_cache_path]}/codedeploy-agent-install auto
  EOH
end

service "codedeploy-agent" do
	action [:enable, :start]
end
