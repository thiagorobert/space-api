import argparse
import sys
import grpc
from grpc_health.v1 import health
from grpc_health.v1 import health_pb2
from grpc_health.v1 import health_pb2_grpc
from grpc_reflection.v1alpha import reflection
from concurrent import futures
import time
import proto.unary_pb2_grpc as pb2_grpc
import proto.unary_pb2 as pb2

_THREAD_POOL_SIZE = 10
_SERVICE_NAMES = (
    pb2.DESCRIPTOR.services_by_name['Unary'].full_name,
    reflection.SERVICE_NAME,
    health.SERVICE_NAME,
)


def inputFlags():
    parser = argparse.ArgumentParser(description='Space API gRPC server')
    parser.add_argument(
        '--server_port', dest='server_port', default='9090', help='server port')
    return parser.parse_args()


class UnaryService(pb2_grpc.UnaryServicer):

    def __init__(self, *args, **kwargs):
        pass

    def GetServerResponse(self, request, context):

        # get the string from the incoming request
        message = request.message
        result = f'Hello I am up and running received "{message}" message from you'
        result = {'message': result, 'received': True}

        return pb2.MessageResponse(**result)


# See https://github.com/grpc/grpc/blob/master/doc/python/server_reflection.md
def enableReflectionAPI(server):
    reflection.enable_server_reflection(_SERVICE_NAMES, server)


# See https://github.com/grpc/grpc/blob/master/examples/python/xds/server.py
def enableHealthChecks(server):
    # Create a health check servicer. We use the non-blocking implementation
    # to avoid thread starvation.
    health_servicer = health.HealthServicer(
        experimental_non_blocking=True,
        experimental_thread_pool=futures.ThreadPoolExecutor(
            max_workers=_THREAD_POOL_SIZE))
    health_pb2_grpc.add_HealthServicer_to_server(health_servicer, server)

    for service in _SERVICE_NAMES:
        health_servicer.set(service, health_pb2.HealthCheckResponse.SERVING)


def serve(options):
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=_THREAD_POOL_SIZE))
    enableReflectionAPI(server)
    enableHealthChecks(server)

    pb2_grpc.add_UnaryServicer_to_server(UnaryService(), server)

    server.add_insecure_port('[::]:' + options.server_port)
    server.start()
    server.wait_for_termination()


if __name__ == '__main__':
    options = inputFlags()

    print(f'\nServer listening at ":{options.server_port}"')

    serve(options)
