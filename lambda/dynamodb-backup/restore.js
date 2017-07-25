#!/usr/bin/env node

var aws = require('aws-sdk');
var program = require('commander');
var async = require('async');
var zlib = require('zlib');

aws.config.update({ region: 'us-east-1' });
var s3 = new aws.S3();
var dynamo = new aws.DynamoDB();

var jsonArray;

program
  .arguments('<file>')
  .option('-b, --bucketname <bucketname>', 'The name of the s3 bucket to restore from')
  .option('-t, --target <target>', 'The name of the table to create')
  .option('-s, --source <source>', 'The name of source file')
  .parse(process.argv);

if (!program.target || !program.bucketname || !program.source) {
  console.log("You must pass target, source and buckename");
  process.exit(1);
}

async.waterfall([
  function getBackups(next) {
    console.log("Listing objects in bucket " + program.bucketname);
    s3.listObjects({Bucket: program.bucketname, Prefix: program.source}, next);
  },
  function findLatestBackup(data, next) {
    console.log("Finding the most recent backup...");
    var latest_backup = new Date('1995');
    var item_name;

    data.Contents.forEach(function (item) {
      var item_date = new Date(item.LastModified);
      if (item_date > latest_backup) {
        latest_backup = item_date;
        item_name = item.Key
      }
    });
    console.log("backup found " + item_name);
    s3.getObject({ Bucket: program.bucketname, Key: item_name}, next);
  },
  function uncompressBackup(response, next) {
    console.log("Uncompressing log...");
    zlib.gunzip(response.Body, next);
  },
  function restoreTable(jsonBuffer, next) {
    console.log("Creating table " + program.target);
    var json = jsonBuffer.toString();
    jsonArray = json.split("\n")

    params = JSON.parse(jsonArray.shift());

    params.TableName = program.target
    delete params["CreationDateTime"];
    delete params["TableSizeBytes"];
    delete params["ItemCount"];
    delete params["TableArn"];
    delete params["TableStatus"];
    delete params["ProvisionedThroughput"]["NumberOfDecreasesToday"];
    delete params["ProvisionedThroughput"]["LastIncreaseDateTime"];
    delete params["ProvisionedThroughput"]["LastDecreaseDateTime"];


	if(params.hasOwnProperty("GlobalSecondaryIndexes")) {
      params["GlobalSecondaryIndexes"].forEach(function(gsi) {
        delete gsi["IndexSizeBytes"];
        delete gsi["ItemCount"];
        delete gsi["IndexArn"];
        delete gsi["IndexStatus"];
        delete gsi["ProvisionedThroughput"]["NumberOfDecreasesToday"];
      });
	}

    dynamo.createTable(params, next);
  },
  function waitForTable(data,next) {
    console.log("Created table " + program.target + ", waiting for table to become active");
    dynamo.waitFor('tableExists', {TableName: program.target}, next);
  },
  function restoreItems(data, next) {
    console.log("Loading data into table " + program.target);
    jsonArray.forEach(function(line) {
      if(line) {
        dynamo.putItem(
          {
              TableName: program.target,
              Item: JSON.parse(line)
          },
          function (err, data) {
            if (err) {
                console.log(err, err.stack);
                throw err;
            }
          }
        );
      }
    });
  }
], function (err) {
    console.log(err);
    process.exit(1);
});
