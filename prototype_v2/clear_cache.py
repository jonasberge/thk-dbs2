from flask_app import create_app, cache


def main():
    with create_app().app_context():
        cache.cache.clear()


if __name__ == '__main__':
    main()
