override_data {
  target = data.terraform_remote_state.shared

  values = {
    outputs = {
      alarm_topic_arn = "arn:aws:sns:us-east-1:000000000000:preview-alarms"
    }
  }
}

variables {
  pr_number  = "42"
  commit_sha = "abc1234"
}

run "names_every_resource_after_the_pull_request" {
  command = plan

  assert {
    condition     = output.function_name == "pr-42-api"
    error_message = "Lambda must be named after the pull request."
  }

  assert {
    condition     = output.log_group_name == "/aws/lambda/pr-42-api"
    error_message = "Log group must match the Lambda name, otherwise the runtime writes elsewhere."
  }

  assert {
    condition     = output.alarm_name == "pr-42-lambda-errors"
    error_message = "Alarm must be named after the pull request."
  }
}

run "rejects_a_non_numeric_pull_request_number" {
  command = plan

  variables {
    pr_number = "not-a-number"
  }

  expect_failures = [var.pr_number]
}
