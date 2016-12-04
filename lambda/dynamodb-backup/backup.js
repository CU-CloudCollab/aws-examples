var aws = require('aws-sdk');
var stream = require('stream');
var ReadableStream = require('./readable-stream');
var zlib = require('zlib');
var async = require('async');

var dateFormat = require('dateformat');
var ts = dateFormat(new Date(), "mmddyyyy-HHMMss")

aws.config.update({ region: 'us-east-1' });
dynamo = new aws.DynamoDB();

function backupTable(tablename, callback) {
  var data_stream = new ReadableStream();//new stream.Readable();
  var gzip = zlib.createGzip();

  // create parameters hash for table scan
  var params = {TableName: tablename, ReturnConsumedCapacity: 'NONE', Limit: '1'};

  // body will contain the compressed content to ship to s3
  var body = data_stream.pipe(gzip);

  var s3obj = new aws.S3({params: {Bucket: 'ccu-dynamo-backups', Key: tablename + '/' + tablename + '-' + ts + '.gz'}});
  s3obj.upload({Body: body}).
    on('httpUploadProgress', function(evt) {
      console.log(evt);
    }).
    send(function(err, data) { console.log(err, data); callback(); });

  function onScan(err, data) {
    if (err) console.log(err, err.stack);
    else {
      for (var idx = 0; idx < data.Items.length; idx++) {
        data_stream.append(JSON.stringify(data.Items[idx]));
        data_stream.append("\n");
      }

      if (typeof data.LastEvaluatedKey != "undefined") {
        params.ExclusiveStartKey = data.LastEvaluatedKey;
        dynamo.scan(params, onScan);
      }
      else {
        data_stream.end()
      }
    }
  }

  // describe the table and write metadata to the backup
  dynamo.describeTable({TableName: tablename}, function(err, data) {
    if (err) console.log(err, err.stack);
    else {
      table = data.Table
      // Write table metadata to first line
      data_stream.append(JSON.stringify(table));
      data_stream.append("\n");

      // limit the the number or reads to match our capacity
      params.Limit = table.ProvisionedThroughput.ReadCapacityUnits

      // start streaminf table data
      dynamo.scan(params, onScan);
    }
  });

}

function backupAll(context) {
  dynamo.listTables({}, function(err, data) {
    if (err) console.log(err, err.stack); // an error occurred
    else {
      async.each(data.TableNames, function(table, callback) {
        console.log('Backing up ' + table);
        backupTable(table, callback);
      }, function(err){
        if( err ) {
          console.log('A table failed to process');
        } else {
          console.log('All tables have been processed successfully');
        }
        context.done(err);
      });
    }
  });
}

module.exports.backupAll = backupAll;
