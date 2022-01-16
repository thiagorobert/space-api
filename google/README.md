These are vendored (nice word for copied) proto definitions required to use gRPC.

This was required to generated proto code for Python, but not for Go.

These files were created with commands below.

```
curl https://raw.githubusercontent.com/googleapis/googleapis/master/google/api/annotations.proto > google/api/annotations.proto
curl https://raw.githubusercontent.com/googleapis/googleapis/master/google/api/http.proto > google/api/http.proto
```

In the future, it would be best to figure out a way to generate the Python code
without having to copy these files.
