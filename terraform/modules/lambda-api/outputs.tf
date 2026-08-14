output "api_url" {
  value = trimsuffix(aws_lambda_function_url.api.function_url, "/")
}

output "function_name" {
  value = aws_lambda_function.api.function_name
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.api.name
}
