# ECS Spot Termination Draining

Sets up a CloudWatch Event rule to match EC2 Spot instances
that are scheduled to be terminated. If the instance is
in the cluster, it is set to DRAINING. ECS will then move
currently running tasks off that instance to another.

**Important**

This module uses a singleton CloudWatch Event Rule to
match all instances in an AWS account. It uses SNS to
support multiple ECS clusters in the same account. This
means that if this module is used more than once in the same
account, the `aws_cloudwatch_event_rule` and associated
resources must be imported.

Resources to import:

```
module.{module_name}.aws_cloudwatch_event_rule.spot-termination-notice
module.{module_name}.aws_cloudwatch_event_target.spot-termination-notice-sns
module.{module_name}.aws_sns_topic.spot-termination-notice
```
