import json
import os

JSON_HEADERS = {"Content-Type": "application/json"}


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": JSON_HEADERS,
        "body": json.dumps(body),
    }


def _info():
    return {
        "env": os.environ.get("ENV_NAME", "unknown"),
        "pr": os.environ.get("PR_NUMBER") or None,
        "commit": os.environ.get("COMMIT_SHA", "unknown"),
    }


def lambda_handler(event, context):
    request = event.get("requestContext", {}).get("http", {})
    method = request.get("method", "")
    path = request.get("path", "/")

    if method != "GET":
        return _response(405, {"error": "method not allowed", "method": method})

    if path == "/health":
        return _response(200, {"status": "ok"})

    if path == "/info":
        return _response(200, _info())

    return _response(404, {"error": "not found", "path": path})
