/**
 * Lambda function: Forwards ALB access logs from S3 to CloudWatch Logs.
 *
 * Use case:
 * ALB stores access logs as .gz files in S3. This function is triggered on each new log file,
 * decompresses it, parses each line, and pushes structured log events to CloudWatch Logs.
 *
 * Key features:
 * - Supports ALB logs in gzip format
 * - Uses AWS SDK v3
 * - Automatically creates the log stream if it doesn't exist
 *
 * Integrated with:
 * - S3 bucket notifications (ObjectCreated event)
 * - CloudWatch log group "/alb/access-logs"
 * - Terraform-based deployment
 */

import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import {
  CloudWatchLogsClient,
  DescribeLogStreamsCommand,
  CreateLogStreamCommand,
  PutLogEventsCommand,
} from '@aws-sdk/client-cloudwatch-logs';
import { gunzipSync } from 'zlib';

const s3 = new S3Client({});
const logs = new CloudWatchLogsClient({});

const LOG_GROUP = process.env.LOG_GROUP_NAME || '/alb/access-logs';
const LOG_STREAM = 'alb-stream';

const streamToBuffer = async (stream) => {
  const chunks = [];
  for await (const chunk of stream) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
};

export const handler = async (event) => {
  const bucket = event.Records[0].s3.bucket.name;
  const key = decodeURIComponent(
    event.Records[0].s3.object.key.replace(/\+/g, ' ')
  );

  try {
    // Download and decompress
    const object = await s3.send(
      new GetObjectCommand({ Bucket: bucket, Key: key })
    );
    const gzippedBuffer = await streamToBuffer(object.Body);
    const decompressed = gunzipSync(gzippedBuffer);
    const lines = decompressed.toString('utf-8').split('\n').filter(Boolean);

    const logEvents = lines.map((line) => ({
      message: line,
      timestamp: Date.now(),
    }));

    // Check if log stream exists
    const describe = await logs.send(
      new DescribeLogStreamsCommand({
        logGroupName: LOG_GROUP,
        logStreamNamePrefix: LOG_STREAM,
      })
    );

    let token;
    if (!describe.logStreams || describe.logStreams.length === 0) {
      // Create if not exists
      await logs.send(
        new CreateLogStreamCommand({
          logGroupName: LOG_GROUP,
          logStreamName: LOG_STREAM,
        })
      );
      console.log(`🆕 Created log stream ${LOG_STREAM}`);
    } else {
      token = describe.logStreams[0].uploadSequenceToken;
    }

    await logs.send(
      new PutLogEventsCommand({
        logGroupName: LOG_GROUP,
        logStreamName: LOG_STREAM,
        logEvents,
        ...(token && { sequenceToken: token }),
      })
    );

    console.log(`✅ Pushed ${logEvents.length} log lines from ${key}`);
  } catch (err) {
    console.error(`❌ Failed to process ${key}`, err);
    throw err;
  }
};
