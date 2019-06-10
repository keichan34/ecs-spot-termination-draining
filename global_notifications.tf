// Note: This file contains resources that should be shared

resource "aws_cloudwatch_event_rule" "spot-termination-notice" {
  name        = "ecs-spot-termination-notice"
  description = "Captures ECS Spot Instance Interruption notices to drain ECS Container Instances."

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Spot Instance Interruption Warning"
  ]
}
PATTERN
}

resource "aws_cloudwatch_event_target" "spot-termination-notice-sns" {
  rule = "${aws_cloudwatch_event_rule.spot-termination-notice.name}"
  arn  = "${aws_sns_topic.spot-termination-notice.arn}"
}

data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "spot-termination-notice" {
  name = "ecs-spot-termination-notice"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "__default_statement_ID",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "SNS:GetTopicAttributes",
        "SNS:SetTopicAttributes",
        "SNS:AddPermission",
        "SNS:RemovePermission",
        "SNS:DeleteTopic",
        "SNS:Subscribe",
        "SNS:ListSubscriptionsByTopic",
        "SNS:Publish",
        "SNS:Receive"
      ],
      "Resource": "arn:aws:sns:ap-northeast-1:${data.aws_caller_identity.current.account_id}:ecs-spot-termination-notice",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "${data.aws_caller_identity.current.account_id}"
        }
      }
    },
    {
      "Sid": "AWSEvents_spot-termination-notice",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sns:Publish",
      "Resource": "arn:aws:sns:ap-northeast-1:${data.aws_caller_identity.current.account_id}:ecs-spot-termination-notice"
    }
  ]
}
EOF
}
