override_data {
  target = data.terraform_remote_state.shared

  values = {
    outputs = {
      alarm_topic_arn = "arn:aws:sns:us-east-1:000000000000:preview-alarms"
    }
  }
}

variables {
  pr_number  = "9001"
  commit_sha = "0ddba11"
}

run "creates_a_reachable_environment" {
  command = apply

  assert {
    condition     = can(regex("^http://[a-z0-9]+\\.lambda-url\\.", output.api_url))
    error_message = "api_url must be a Lambda function URL."
  }

  assert {
    condition     = output.site_bucket == "pr-9001-static"
    error_message = "Site bucket must be named after the pull request."
  }

  assert {
    condition     = output.function_name == "pr-9001-api"
    error_message = "Lambda must be named after the pull request."
  }
}
