data "archive_file" "spot_termination_zip" {
  type        = "zip"
  output_path = "/tmp/lambda_py/spot_termination-${sha256(file("${path.module}/lambda_py/spot_termination.py"))}.zip"
  source_file = "${path.module}/lambda_py/spot_termination.py"
}

resource "aws_lambda_function" "spot_termination" {
  handler          = "spot_termination.lambda_handler"
  function_name    = "ecs-${var.cluster_name}-spot-termination"
  role             = "${aws_iam_role.spot_termination.arn}"
  runtime          = "python3.6"
  filename         = "${data.archive_file.spot_termination_zip.output_path}"
  source_code_hash = "${data.archive_file.spot_termination_zip.output_base64sha256}"

  environment {
    variables = {
      CLUSTER_NAME = "${var.cluster_name}"
    }
  }

  timeout = "30"
}

resource "aws_sns_topic_subscription" "cluster-instances-asg-lifecycle-lambda" {
  topic_arn = "${aws_sns_topic.spot-termination-notice.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.spot_termination.arn}"
}

resource "aws_lambda_permission" "spot_termination" {
  function_name = "${aws_lambda_function.spot_termination.arn}"

  statement_id = "AllowExecutionFromSNS"
  action       = "lambda:InvokeFunction"
  principal    = "sns.amazonaws.com"

  source_arn = "${aws_sns_topic.spot-termination-notice.arn}"
}

resource "aws_iam_role" "spot_termination" {
  name               = "ecs-${var.cluster_name}-spot-termination"
  assume_role_policy = "${file("${path.module}/files/lambda_assume_role.json")}"
}

resource "aws_iam_role_policy_attachment" "spot_termination-basic-exec" {
  role       = "${aws_iam_role.spot_termination.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "spot_termination" {
  name = "ecs-${var.cluster_name}-spot-termination"
  role = "${aws_iam_role.spot_termination.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:ListContainerInstances"
      ],
      "Effect": "Allow",
      "Resource": "${var.cluster_arn}"
    },
    {
      "Action": [
        "ecs:UpdateContainerInstancesState",
        "ecs:DescribeContainerInstances"
      ],
      "Effect": "Allow",
      "Resource": "*",
      "Condition": {
        "ArnEquals": {
          "ecs:cluster": "${var.cluster_arn}"
        }
      }
    }
  ]
}
EOF
}
