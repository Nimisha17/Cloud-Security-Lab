def hello_http(request):
    import os
    secret = os.environ.get("SECRET_FLAG", "no secret")
    return f"Leaked: {secret}"
