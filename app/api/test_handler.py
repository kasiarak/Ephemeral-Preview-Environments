import json
import os
import unittest
from unittest import mock

import handler


def event(path, method="GET"):
    """Builds the subset of an API Gateway v2 payload the handler reads."""
    return {"requestContext": {"http": {"method": method, "path": path}}}


def body(response):
    return json.loads(response["body"])


class HandlerTest(unittest.TestCase):
    def test_health_reports_ok(self):
        response = handler.lambda_handler(event("/health"), None)

        self.assertEqual(200, response["statusCode"])
        self.assertEqual({"status": "ok"}, body(response))

    @mock.patch.dict(
        os.environ,
        {"ENV_NAME": "pr-42", "PR_NUMBER": "42", "COMMIT_SHA": "abc1234"},
    )
    def test_info_reports_deployed_version(self):
        response = handler.lambda_handler(event("/info"), None)

        self.assertEqual(200, response["statusCode"])
        self.assertEqual(
            {"env": "pr-42", "pr": "42", "commit": "abc1234"},
            body(response),
        )

    @mock.patch.dict(os.environ, {"ENV_NAME": "dev"}, clear=True)
    def test_info_omits_pr_outside_preview_environments(self):
        response = handler.lambda_handler(event("/info"), None)

        self.assertIsNone(body(response)["pr"])

    def test_unknown_path_is_not_found(self):
        response = handler.lambda_handler(event("/nope"), None)

        self.assertEqual(404, response["statusCode"])
        self.assertEqual("/nope", body(response)["path"])

    def test_non_get_is_rejected(self):
        response = handler.lambda_handler(event("/health", method="POST"), None)

        self.assertEqual(405, response["statusCode"])


if __name__ == "__main__":
    unittest.main()
