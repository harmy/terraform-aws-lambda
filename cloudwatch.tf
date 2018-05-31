locals {
  schedule_enabled = "${var.schedule_expression != ""}"
}

resource "aws_lambda_permission" "cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${var.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.lambda.arn}"
  count         = "${local.schedule_enabled ? 1 : 0}"
  depends_on    = ["aws_lambda_function.lambda", "aws_lambda_function.lambda_with_dl", "aws_lambda_function.lambda_with_vpc", "aws_lambda_function.lambda_with_dl_and_vpc"]
}

resource "aws_cloudwatch_event_rule" "lambda" {
  name                = "${var.function_name}"
  schedule_expression = "${var.schedule_expression}"
  description         = "Invokes ${var.function_name} at ${var.schedule_expression}"
  is_enabled          = "${var.enabled}"
  count               = "${local.schedule_enabled ? 1 : 0}"
}

resource "aws_cloudwatch_event_target" "lambda" {
  target_id = "${var.function_name}"
  rule      = "${aws_cloudwatch_event_rule.lambda.name}"
  arn       = "${aws_lambda_function.lambda.arn}"
  count     = "${! var.attach_vpc_config && ! var.attach_dead_letter_config ? 1 : 0}"
}

resource "aws_cloudwatch_event_target" "lambda_with_dl" {
  target_id = "${var.function_name}"
  rule      = "${aws_cloudwatch_event_rule.lambda.name}"
  arn       = "${aws_lambda_function.lambda_with_dl.arn}"
  count     = "${var.attach_dead_letter_config && ! var.attach_vpc_config ? 1 : 0}"
}

resource "aws_cloudwatch_event_target" "lambda_with_vpc" {
  target_id = "${var.function_name}"
  rule      = "${aws_cloudwatch_event_rule.lambda.name}"
  arn       = "${aws_lambda_function.lambda_with_vpc.arn}"
  count     = "${var.attach_vpc_config && ! var.attach_dead_letter_config ? 1 : 0}"
}

resource "aws_cloudwatch_event_target" "lambda_with_dl_and_vpc" {
  target_id = "${var.function_name}"
  rule      = "${aws_cloudwatch_event_rule.lambda.name}"
  arn       = "${aws_lambda_function.lambda_with_dl_and_vpc.arn}"
  count     = "${var.attach_dead_letter_config && var.attach_vpc_config ? 1 : 0}"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = "${var.log_retention_days}"
}