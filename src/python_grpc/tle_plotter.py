from threading import Thread

import dash
from dash import dcc
from dash import html
from tletools import TLE

dash_app = dash.Dash()
dash_app.layout = html.Div([])


def Start(dash_port):
    thread = Thread(target=dash_app.run_server,
                    kwargs={'debug': True,
                            'port': dash_port,
                            # Required so the server is accessible when running in Docker.
                            # See https://stackoverflow.com/questions/44045451/cant-access-flask-app-which-is-inside-docker-container
                            'host': '0.0.0.0',
                            # Set 'use_reloader' to False to enable running in a new thread.
                            # see https://stackoverflow.com/questions/31264826/start-a-flask-application-in-separate-thread
                            'use_reloader': False})
    thread.start()

def Plot(orbitFigure):
    dash_app.layout = html.Div([
        dcc.Graph(figure=orbitFigure)
    ])
