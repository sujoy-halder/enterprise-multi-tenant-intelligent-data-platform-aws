import json
import os

import boto3

sns = boto3.client("sns")


def handler(event, context):
    topic_arn = os.environ["SNS_TOPIC_ARN"]
    records = event.get("Records", [])
    messages = []

    for record in records:
        message = record.get("Sns", {}).get("Message", "{}")
        try:
            payload = json.loads(message)
        except json.JSONDecodeError:
            payload = {"raw_message": message}
        messages.append(payload)

    summary = {
        "source": "enterprise-data-platform",
        "records": len(messages),
        "alerts": messages,
        "request_id": getattr(context, "aws_request_id", "local"),
    }

    sns.publish(
        TopicArn=topic_arn,
        Subject="[data-platform] alert routed",
        Message=json.dumps(summary, indent=2, default=str),
    )

    return {"statusCode": 200, "body": json.dumps({"alerts": len(messages)})}
