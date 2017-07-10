# Example of assuming a role in a different account

This directory contains templates and a shell script that together provide an example of one role assuming a different role in a different AWS account.

A use case for this is an EC2 instance running under a **home instance profile** in a **home AWS account** needing to assume a **target role** in a **target AWS account** so that it can operate within that target account with the privileges granted by the target role.

This example can be used to specifically create the following resources:
* In the **home AWS account**
  * An IAM role `example-role` and instance profile `example-instance-profile` that an EC2 instance in the home AWS account can use as an instance profile. The instance profile specifically names the **target role** in the **target AWS account** that will be assumed.
* In the **target AWS account**
  * An IAM role `shib-dba` that includes three key features:
    * Trust configuration that will allow Cornell users to assume the role in the **target AWS account**, assuming that the corresponding Active Directory group has been configured. See https://confluence.cornell.edu/x/cghqF.
    * Trust configuration that will allow an EC2 instance running in the **home AWS account** with `example-instance-profile` to assume the role.
    * The privileges that a DBA might need to support RDS instances in the **target AWS account**. See also [shib-dba-role.yaml](../shib-dba-role.yaml) CloudFormation template.

## How to use these files - High level instructions

1. The following instructions assume the following account numbers. You will want to replace with the relevant account numbers for your case.
    * **home AWS account** account number: 111111111111
    * **target AWS account** account number: 999999999999
2. With appropriate privileges (e.g., shib-admin) in the **home AWS account**, create a new  CloudFormation stack using [instance-profile.yaml](instance-profile.yaml) as the template.
    * When providing parameters to the stack, be sure to replace the account number in the default "RoleToBeAssumed" value with that of your **target AWS account**. If you plan to use a different **target role name** in the **target AWS account**, then replace `shib-dba` with that role name (created in the next step).
    * Optionally, replace the default role name and instance profile name with ones of your own choosing.
    * This step will create a new role and instance profile in the **home AWS account**.
    * Take note of the ARN of the ExampleRole under the `Resources` tab of the CloudFormation stack. You will need this in the step below. It will look something like `arn:aws:iam::111111111111:role/example-role`, only with your **home AWS account** number and the name of the role, if specified something other than the default in the parameter section of the stack.

1. Now, with appropriate privileges in the **target AWS account**, create a new CloudFormation stack using the [shib-dba-role-with-assume-role.yaml](shib-dba-role-with-assume-role.yaml) template.
    * When providing parameters to the stack, be sure to:
      * provide a name for the role to be created by the template; use `shib-dba` unless that conflicts with an existing role. This name must match the name you provided in the previous step.
      * provide the appropriate ARN for that was created in the previous step.
    * Note the ARN of the role created by the CloudFormation stack. It will be in the `Resources` tab.

## How to test your roles -- High level instructions

1. In the **home AWS account**, create an EC2 instance running Amazon Linux. Be sure to:
    * launch it on a subnet that has outgoing internet connectivity.
    * specify a key-pair that you have access to, since you will need to ssh into that instance for this test.
    * specify a security group that will allow port 22 access from your workstation.

1. Once the instance has started, ssh to it. E.g., `ssh -i mykey.pem ec2-user@11.22.33.44`.

1. In a shell on the instance:
    1. Install `jq` (https://stedolan.github.io/jq/).
    ```
    $ sudo yum install jq -y
    ```
    2. Create the test script.
    ```
    $ wget https://raw.githubusercontent.com/CU-CommunityApps/aws-examples/master/cloudformation/iam/assume-role-example/assume-role.sh
    $ chmod +x assume-role.sh
    ```
    3. Change the value of the ASSUME_ROLE variable to the ARN of the `shib-dba` role above.
      * Use nano, or your favorite linux editor to do this.
    4. Run the script
    ```
    $ ./assume-role.sh
    Assume role: arn:aws:iam::999999999999:role/shib-dba
    Assume role response:
    {
        "AssumedRoleUser": {
            "AssumedRoleId": "AROAJ3L7...RLKR4:mysession",
            "Arn": "arn:aws:sts::999999999999:assumed-role/shib-dba/mysession"
        },
        "Credentials": {
            "SecretAccessKey": "lXyszzVD...Y+s",
            "SessionToken": "FQoDYXdzEJH//////////wEaDG5GlfxxxoaM...+GlEWAo8XtpLHLhJsJxDgsoHTsJrhLB9ChXdEgHhB9BAe+yjSwY7LBQ==",
            "Expiration": "2017-07-10T15:59:18Z",
            "AccessKeyId": "ASIAJVS...IXXXX"
        }
    }
    Retrieved temp access key  for role arn:aws:iam::999999999999:role/shib-dba. Key will expire at 2017-07-10T15:59:18Z.
    AWS CLI command: aws rds describe-db-instances --region us-east-1
    Command output:
    {
      "DBInstances": [
        ...
      ]
    }
    ```
    * If the **target AWS account** doesn't have any existing RDS instances, the "Command output" above will be empty.
    * The test is a success if you don't get any errors when running the `assume-role.sh` script. The IDs and keys in your "Assume role response" will be different than what is shown here.





