from flask import current_app, g
from flask_caching import Cache


cache = Cache(config={
    'CACHE_TYPE': 'simple'
})


def init_app(app):
    cache.init_app(app)
