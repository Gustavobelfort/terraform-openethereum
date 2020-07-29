resource "aws_sns_topic" "alarm" { #tfsec:ignore:AWS016
  name = "parity-ethereum-alarms"

  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF

  provisioner "local-exec" {
    command = "aws sns subscribe --region ${var.region} --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.alarms_email}"
  }
}

resource "aws_cloudwatch_metric_alarm" "memory" {
  count               = var.eth_count
  alarm_name          = "openethereum-${var.region}-${count.index + 1}-high-mem"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "CWAgent"
  evaluation_periods  = "1"
  metric_name         = "mem_used_percent"
  period              = "3600"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "This metric monitors EC2 Memory utilization"
  alarm_actions       = [aws_sns_topic.alarm.arn]

  dimensions = {
    InstanceId   = aws_instance.ethereum[count.index].id
    InstanceType = var.instance_type
    ImageId      = data.aws_ami.ubuntu-18_04.id
  }
}

resource "aws_cloudwatch_metric_alarm" "disk" {
  count               = var.eth_count
  alarm_name          = "parity-ethereum-${var.region}-${count.index + 1}-high-disk-usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "CWAgent"
  evaluation_periods  = "1"
  metric_name         = "disk_used_percent"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors the disk space holding the blockchain data"
  alarm_actions       = [aws_sns_topic.alarm.arn]

  dimensions = {
    path         = "/"
    InstanceId   = aws_instance.ethereum[count.index].id
    InstanceType = var.instance_type
    ImageId      = data.aws_ami.ubuntu-18_04.id
    device       = "xvda1"
    fstype       = "ext4"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  count               = var.eth_count
  alarm_name          = "parity-ethereum-${var.region}-${count.index + 1}-high-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "3600"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alarm.arn]

  dimensions = {
    InstanceId = element(aws_instance.ethereum.*.id, count.index)
  }
}

resource "aws_cloudwatch_metric_alarm" "health" {
  count               = var.eth_count
  alarm_name          = "parity-ethereum-${var.region}-${count.index + 1}-status-check"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "3600"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ec2 health status"
  alarm_actions       = [aws_sns_topic.alarm.arn]

  dimensions = {
    InstanceId = element(aws_instance.ethereum.*.id, count.index)
  }
}

resource "aws_iam_user" "cloudwatch" {
  name = "cloudwatch-reporter-${var.application}"
  path = "/system/"

  tags = {
    tag-key = "cloudwatch-reporter-${var.application}"
  }
}

resource "aws_iam_access_key" "cloudwatch" {
  user = aws_iam_user.cloudwatch.name
}

resource "aws_iam_user_policy" "cloudwatch_role" {
  name = "cloudwatch-reporter-policy"
  user = aws_iam_user.cloudwatch.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "ec2:DescribeTags",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
        }
    ]
}
EOF

}
