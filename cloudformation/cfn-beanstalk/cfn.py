#!/usr/bin/env python

import yaml

from troposphere import (
    Base64, 
    FindInMap, 
    GetAtt, 
    Join, 
    Output, 
    Parameter, 
    Ref, 
    Tags, 
    Template
)

from troposphere.elasticbeanstalk import (
    Application,
    ConfigurationTemplate,
    Environment,
    OptionSettings,
)

def get_beanstalk_template():
    with open('config.yml', 'r') as yml:
        config = yaml.load(yml)

    t = Template()

    ##################
    # EB Application #
    ##################

    application = t.add_resource(Application(
        'application',
        ApplicationName=config['appname'],
        Description='myapp Description',
    ))

    globalOptionSettings = [
        OptionSettings(
            Namespace='aws:autoscaling:launchconfiguration',
            OptionName='EC2KeyName',
            Value=config['keypair'],
        ),

        OptionSettings(
            Namespace='aws:ec2:vpc',
            OptionName='VPCId',
            Value=config['vpc'],
        ),

        OptionSettings(
            Namespace='aws:ec2:vpc',
            OptionName='Subnets',
            Value=config['asgSubnets'],
        ),

        OptionSettings(
            Namespace='aws:ec2:vpc',
            OptionName='ELBSubnets',
            Value=config['elbSubnets'],
        ),
    ]

    # Add Custom Option Settings to Global Config

    for namespace in config['namespaces'].keys():
        options = config['namespaces'][namespace]
        for option in options.keys():
            globalOptionSettings.append(OptionSettings(
                Namespace=namespace,
                OptionName=option,
                Value=options[option],
            ))

    environments = config['environments']
    for env in environments.keys():
        environment = environments[env]
        environmentOptionSettings = []

        containerEnv = environment['containerEnv']
        for envvar in containerEnv.keys():
            environmentOptionSettings.append(OptionSettings(
                Namespace='aws:elasticbeanstalk:application:environment',
                OptionName=envvar,
                Value=containerEnv[envvar],
            ))

        for namespace in environment['namespaces']:
            options = environment['namespaces'][namespace]
            for option in options.keys():
                environmentOptionSettings.append(OptionSettings(
                    Namespace=namespace,
                    OptionName=option,
                    Value=options[option],
                ))

        environmentOptionSettings = globalOptionSettings + environmentOptionSettings

        envTags = { 
            'Application': config['appname'],
            'Environment': env,
        }
        for tag in environment['tags'].keys():
            envTags[tag] = environment['tags'][tag]

        t.add_resource(Environment(
            'env{appname}{envname}'.format(appname=config['appname'], envname=env),
            ApplicationName=Ref(application),
            SolutionStackName=config['solutionStack'],
            CNAMEPrefix='{appname}-{envname}'.format(appname=config['appname'], envname=env), # Must be unique within the region
            Description='{envname} Description'.format(envname=env),
            OptionSettings=environmentOptionSettings,
            EnvironmentName='{appname}-{envname}'.format(appname=config['appname'], envname=env), # Note that transient environments should not be given a name
            Tags=Tags(envTags),
        ))

        t.add_output(Output(
            '{appname}{envname}URL'.format(appname=config['appname'], envname=env),
            Value=Ref('env{appname}{envname}'.format(appname=config['appname'], envname=env)),
        ))

    return t.to_json()

if __name__ == '__main__':
    print(get_beanstalk_template())
