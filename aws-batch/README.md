# AWS Batch Example
This repo shows how to setup a batch job to use Docker.  This is extremely powerful for any type of batch task, including etl's.  Batch was a new service launched in December by AWS.  Here are some of Batch's features:
* Jobs represent a unit of work, which are submitted to Job Queues, where they reside, and are prioritized, until they are able to be attached to a compute resource.
* Job Definitions specify how Jobs are to be run. While each job must reference a Job Definition, many parameters can be overridden, including vCPU, memory, Mount points and container properties.
* Job Queues store Jobs until they are ready to run. Jobs may wait in the queue while dependent Jobs are being executed or waiting for system resources to be provisioned.
* Compute Environments include both Managed and Unmanaged environments. Managed compute environments enable you to describe your business requirements (instance types, min/max/desired vCPUs etc.) and AWS will launch and scale resources on your behalf. Unmanaged environments allow you to launch and manage your own resources such as containers.
* Scheduler evaluates when, where and how to run Jobs that have been submitted to a Job Queue. Jobs run in approximately the order in which they are submitted as long as all dependencies on other jobs have been met.

The eventual goal of this repo is to setup a batch process for the AWS CIT Config Script.  For now, I just want to document the steps on how to utilize AWS Batch

In general, these are the steps:

1) Create Compute Environment 
```
aws batch create-compute-environment --cli-input-json file://compute-environment-normal.json`
```

2) Create Job Queue 
```
aws batch create-job-queue --cli-input-json file://job-queue-normal.json
```

3) Register Job Definition 
```
aws batch register-job-definition --cli-input-json file://vet-dw-etl-sb-job-definition.json
```

You will never have to do this unless you want to create an entire infrastructure from scratch. The configuration for the compute environment and job queue is in this repo. The job definition, however, contains secrets and will need you to enter passwords into the file. Here's a skeleton:


```
{
    "jobDefinitionName": "vet-dw-etl-sb", 
    "type": "container", 
    "parameters": { }, 
    "containerProperties": {
        "image": "IMAGE FROM ECR", 
        "vcpus": 2, 
        "memory": 2000, 
        "command": [
            "node",
            "app.js"
        ],
        "volumes": [ ], 
        "environment": [
            {
                "name": "PARAMETER",
                "value": "FILL IN "
            },
            {
                "name": "PARAMETER",
                "value": "FILL IN "
            }
        ], 
        "mountPoints": [ ],
        "ulimits": [ ]
    }
}
```
