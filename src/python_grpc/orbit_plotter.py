from threading import Thread

import dash
from dash import dcc
from dash import html

dash_app = dash.Dash()
dash_app.layout = html.Div([])


def Start(dash_port):
    # Notes:
    #
    # 'host' set to '0.0.0.0' so the server is accessible when running in Docker.
    # 'use_reloader' set to False to enable running in a thread.
    thread = Thread(
        target=dash_app.run_server,
        kwargs={'debug': True,
                'port': dash_port,
                'host': '0.0.0.0',
                'use_reloader': False})
    thread.start()

def Plot(orbitFigure):
    dash_app.layout = html.Div([
        dcc.Graph(figure=orbitFigure)
    ])
