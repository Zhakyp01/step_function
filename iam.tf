data "aws_iam_policy_document" "sfn_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com", ]
    }
    actions = ["sts:AssumeRole"]
    sid     = ""
  }
}

data "aws_iam_policy_document" "lambda_eventbridge" {
  count = var.create_policy ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "event:PutEvents",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "zensar-cloudwatchlog-access-policy" {
  count = var.create_policy ? 1 : 0
  statement {
    sid = "VisualEditor0"

    actions = [
      "logs:ListTagsLogGroup",
      "logs:GetDataProtectionPolicy",
      "logs:DisassociateKmsKey",
      "logs:PutDataProtectionPolicy",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:DescribeSubscriptionFilters",
      "logs:StartQuery",
      "logs:Unmask",
      "logs:DescribeMetricsFilter",
      "logs:TagResource",
      "logs:CreateLogGroup",
      "logs:ListTagsForResource",
      "logs:CreateExportTask",
      "logs:PutMetricFilter",
      "iam:PassRole",
      "logs:CreateLogStream",
      "logs:TagLogGroup",
      "logs:AssociateKmsKey",
      "logs:FilterLogEvents",
      "logs:PutSubscriptionFilter",
      "logs:PutRetentionPolicy",
      "logs:GetLogGroupFields"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:*:*:*",
      "arn:aws:iam::aws:role/*",
      "arn:aws:logs:*:*:*"
    ]
  }
  statement {
    sid = "VisualEditor1"
    actions = [
      "logs:PutDestinationPolicy",
      "logs:GetLogEvents",
      "logs:PutSubscriptionFilter",
      "logs:TagResource",
      "logs:PutDestination",
      "logs:PutLogEvents",
      "logs:ListTagsForResource"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:*:*:*",
      "arn:aws:logs:*:*:*",
      "arn:aws:logs:*:*:*",
      "arn:aws:logs:*:*:*"
    ]
  }
}


locals {
  sfn_policies = {
    zensar-cloudwatchlog-access-policy = try(data.aws_iam_policy_document.zensar-cloudwatchlog-access-policy[0].json, "")
    lambda_eventbridge                 = try(data.aws_iam_policy_document.lambda_eventbridge[0].json, "")
  }
}

resource "aws_iam_policy" "step_function_policy" {
  for_each = { for i, v in local.sfn_policies : i => v if var.create_policy }
  name     = each.key
  policy   = each.value
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  for_each   = { for i, v in local.sfn_policies : i => v if var.create_policy }
  role       = module.step_function.role_name
  policy_arn = aws_iam_policy.step_function_policy[each.key].arn
}
