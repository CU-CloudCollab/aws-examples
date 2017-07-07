# Example of assuming a role in a different account

This directory contains templates and a shell script that together provide an example of one role assuming a different role in a different AWS account.

A use case for this is an EC2 instance running under a **home instance profile** in a **home AWS account** needing to assume a **target role** in a **target AWS account** so that it can operate within that target account with the privileges granted by the target role.
