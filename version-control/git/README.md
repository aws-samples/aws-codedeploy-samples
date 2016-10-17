Git Hooks
=========

The scripts here provide basic functionality to hook AWS CodeDeploy into git
events. The primary script is provided as a `pre-push` hook, which executes the
`aws deploy push` command for the local repository before git finishes pushing
to the remote. It then starts a new deployment of the revision. Both the AWS
CodeDeploy Application and Deployment Group must already exist.

    !!! CAUTION !!! Because this does an S3 upload on every push, you may incur S3 transfer charges.

    --Note, you need to make this script executable ( chmod +x pre-push ) after installing it in ./.git/hooks/pre-push

No changes to the script itself should be required. Instead, it pulls the
necessary information from git config. The required keys are
`aws-codedeploy.application-name`, `aws-codedeploy.s3bucket`, and
`aws-codedeploy.deployment-group`. They can be set with the following commands
(replace values with your own):

    git config aws-codedeploy.application-name MyApplication
    git config aws-codedeploy.s3bucket MyS3Bucket
    git config aws-codedeploy.deployment-group MyDeploymentGroup

The deployment created with this script will use the default deployment
configuration for the configured deployment group.
