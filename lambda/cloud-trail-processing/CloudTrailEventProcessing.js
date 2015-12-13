var aws  = require('aws-sdk');
var zlib = require('zlib');
var async = require('async');

var EVENT_SOURCE_TO_TRACK = /route53.amazonaws.com/;
var EVENT_NAME_TO_TRACK   = /ChangeResourceRecordSets/;
var ALLOWED_TYPES = /A|AAA|CNAME/;
var DEFAULT_SNS_REGION  = 'us-east-1';
var SNS_TOPIC_ARN       = 'arn:aws:sns:us-east-1:225162606092:cloud-trail-alerts';

var s3 = new aws.S3();
var route53 = new aws.Route53({apiVersion: '2013-04-01'});
var sns = new aws.SNS({
    apiVersion: '2010-03-31',
    region: DEFAULT_SNS_REGION
});


exports.handler = function(event, context) {
    var srcBucket = event.Records[0].s3.bucket.name;
    var srcKey = event.Records[0].s3.object.key;

    async.waterfall([
        function fetchLogFromS3(next){
            console.log('Fetching compressed log from S3...');
            s3.getObject({
               Bucket: srcBucket,
               Key: srcKey
            },
            next);
        },
        function uncompressLog(response, next){
            console.log("Uncompressing log...");
            zlib.gunzip(response.Body, next);
        },
        function publishNotifications(jsonBuffer, next) {
            console.log('Filtering log...');
            var json = jsonBuffer.toString();
            console.log('CloudTrail JSON from S3:', json);
            var records;
            try {
                records = JSON.parse(json);
            } catch (err) {
                next('Unable to parse CloudTrail JSON: ' + err);
                return;
            }
            var matchingRecords = records
                .Records
                .filter(function(record) {
                    var retval = false;
                    if(record.eventSource.match(EVENT_SOURCE_TO_TRACK) && record.eventName.match(EVENT_NAME_TO_TRACK)) {
                          record.requestParameters.changeBatch.changes.forEach(function(change) {
                            console.log("record type " + change.resourceRecordSet.type);
                            if (!change.resourceRecordSet.type.match(ALLOWED_TYPES) &&
                                change.action != "DELETE") {
                              retval =  true;
                            }
                          });
                        }
                      return retval;
                });

            console.log('Publishing ' + matchingRecords.length + ' notification(s) in parallel...');
            async.each(
                matchingRecords,
                function(record, publishComplete) {
                    var changeBatch = record.requestParameters.changeBatch;
                    var params = {ChangeBatch: { Changes: [] }, HostedZoneId: record.requestParameters.hostedZoneId};
                    var mesaage = "The following DNS change request(s) were not of allowed record types";

                    changeBatch.changes.forEach(function(change) {
                      if (!change.resourceRecordSet.type.match(ALLOWED_TYPES)) {
                        newChange = {
                            Action: "DELETE",
                            ResourceRecordSet: {
                              Name: change.resourceRecordSet.name,
                              Type: change.resourceRecordSet.type,
                              TTL: change.resourceRecordSet.tTL,
                              ResourceRecords: [ { Value: change.resourceRecordSet.resourceRecords[0].value }]
                            },
                        };

                        params.ChangeBatch.Changes.push(newChange);
                        mesaage += "\n" + change.resourceRecordSet.name + " of type " + change.resourceRecordSet.type + "\n"
                      }
                      console.log(JSON.stringify(params));

                      route53.changeResourceRecordSets(params, function(err, data) {
                        if (err) {
                          console.log(err, err.stack);
                        } else {
                          console.log("Successfully deleted record " + data);
                        }
                      });
                    });

                    console.log('Publishing notification: ', record);
                    sns.publish({
                        Message:
                            'Alert... SNS topic created: \n TopicARN=' + record.responseElements.topicArn + '\n\n' +
                            mesaage,
                        TopicArn: SNS_TOPIC_ARN
                    }, publishComplete);
                },
                next
            );
        }
    ], function (err) {
        if (err) {
            console.error('Failed to publish notifications: ', err);
        } else {
            console.log('Successfully published all notifications.');
        }
        context.done(err);
    });
};
