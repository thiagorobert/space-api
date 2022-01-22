FROM ubuntu:20.04

# Set up dependencies.
RUN apt-get update

# Install `tzdata` separately to avoid interactive input (see https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image)
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata

# Install dependencies.
RUN apt-get install -o Acquire::ForceIPv4=true -y \
    python3 \
    python3-pip \
    protobuf-compiler \
    curl

# Install a more recent version of Go (`apt-get install golang` yields 1.1 in this environment).
RUN curl https://storage.googleapis.com/golang/go1.17.5.linux-amd64.tar.gz -o go1.17.5.linux-amd64.tar.gz
RUN tar -zxf go1.17.5.linux-amd64.tar.gz -C /usr/local/ && rm go1.17.5.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Install a more recent version of Node (`apt-get install nodejs` yields 10.19.0 in this environment).
RUN curl https://nodejs.org/dist/v14.18.3/node-v14.18.3-linux-x64.tar.xz -o node-v14.18.3-linux-x64.tar.xz
RUN tar -xf node-v14.18.3-linux-x64.tar.xz -C /usr/local/ && rm node-v14.18.3-linux-x64.tar.xz
ENV PATH="/usr/local/node-v14.18.3-linux-x64/bin:${PATH}"

# Install gRPC support in Python.
RUN pip install \
    protobuf \
    grpcio \
    grpcio-health-checking \
    grpcio-reflection \
    grpcio-tools

# Install space-related libraries.
# Numba (dep of tletools) needs NumPy 1.21 or less
RUN pip install \
    numpy==1.21 \
    TLE-tools \
    dash

# Setup $GOBIN and add it to $PATH.
ENV GOBIN=/go/bin
RUN mkdir -p ${GOBIN}
ENV PATH="${GOBIN}:${PATH}"

# Set up workdir, copy code.
ENV CODE_ROOT=/go/src/thiago.pub/space-api
RUN mkdir -p ${CODE_ROOT}
WORKDIR ${CODE_ROOT}
COPY google ${CODE_ROOT}/google
COPY proto ${CODE_ROOT}/proto
COPY src ${CODE_ROOT}/src
COPY tools ${CODE_ROOT}/tools

# Set up Node UI.
WORKDIR ${CODE_ROOT}/src/ui
RUN npm install

# Install protoc-gen-go (see https://github.com/grpc-ecosystem/grpc-gateway/)
WORKDIR ${CODE_ROOT}/tools
RUN go mod init github.com/thiagorobert/space-api/go_proto_tools
RUN go mod tidy -compat=1.17
RUN go install \
  github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway \
  github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2 \
  google.golang.org/protobuf/cmd/protoc-gen-go \
  google.golang.org/grpc/cmd/protoc-gen-go-grpc

# Generate proto code, setup Go modules, and build Go code.
WORKDIR ${CODE_ROOT}

RUN python3 -m grpc_tools.protoc \
  -I=. \
  --python_out=./src/python_grpc \
  --grpc_python_out=./src/python_grpc \
  ./google/api/http.proto ./google/api/annotations.proto \
  ./proto/unary.proto

RUN protoc \
  -I=. \
  --go_out ./src/go_rest_proxy/autogenerated/ --go_opt paths=source_relative \
  --go-grpc_out ./src/go_rest_proxy/autogenerated/ --go-grpc_opt paths=source_relative \
  --grpc-gateway_out ./src/go_rest_proxy/autogenerated/ \
  --grpc-gateway_opt logtostderr=true \
  --grpc-gateway_opt paths=source_relative \
  ./proto/unary.proto

# Setup required Go modules and build REST proxy.
WORKDIR ${CODE_ROOT}/src/go_rest_proxy/autogenerated/proto/
RUN go mod init github.com/thiagorobert/space-api/autogenerated_proto
RUN go mod tidy

WORKDIR ${CODE_ROOT}
RUN go mod init github.com/thiagorobert/space-api
RUN echo "replace github.com/thiagorobert/space-api/autogenerated_proto => ./src/go_rest_proxy/autogenerated/proto/" >> go.mod
RUN go mod tidy -compat=1.17

RUN go build src/go_rest_proxy/rest_reverse_proxy.go

# Expose requierd ports. This is not required, it's more of a documentation.
# UI
EXPOSE 8080
# REST proxy
EXPOSE 8081
# gRPC server
EXPOSE 9090
# Dash server (to render orbit plots)
EXPOSE 9091
# Reserved for future use
EXPOSE 9092

# Copy and run script that starts gRPC server and REST proxy.
COPY ./bootstrap.sh ${CODE_ROOT}/bootstrap.sh
CMD ["/go/src/thiago.pub/space-api/bootstrap.sh"]
