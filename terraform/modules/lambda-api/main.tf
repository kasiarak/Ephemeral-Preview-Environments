locals {
  function_name = "${var.name_prefix}-api"
}

data "archive_file" "package" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/.terraform/${local.function_name}.zip"
  excludes    = ["test_handler.py", "__pycache__"]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "logs" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.api.arn}:*"]
  }
}

resource "aws_iam_role" "api" {
  name               = "${local.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "logs" {
  name   = "logs"
  role   = aws_iam_role.api.id
  policy = data.aws_iam_policy_document.logs.json
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.retention_in_days
}

resource "aws_lambda_function" "api" {
  function_name    = local.function_name
  role             = aws_iam_role.api.arn
  runtime          = var.runtime
  handler          = var.handler
  filename         = data.archive_file.package.output_path
  source_code_hash = data.archive_file.package.output_base64sha256
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = {
      ENV_NAME   = var.env_name
      PR_NUMBER  = var.pr_number
      COMMIT_SHA = var.commit_sha
    }
  }

  depends_on = [aws_cloudwatch_log_group.api]
}

resource "aws_lambda_function_url" "api" {
  function_name      = aws_lambda_function.api.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "public_url" {
  statement_id           = "AllowPublicFunctionUrlInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.api.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}
