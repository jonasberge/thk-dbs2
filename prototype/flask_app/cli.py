import os
import re
import time

import click
from flask.cli import AppGroup
from flask import current_app

from flask_app.db import get_db
from flask_app.demo import add_test_data


db = AppGroup('db')


start_nested = [
    r"^\s*create\s+or\s+replace\s+trigger.*$",
    r"^\s*create\s+or\s+replace\s+procedure.*$",
    r"^\s*create\s+or\s+replace\s+function.*$",
]

end_nested = r"end.*;\s*$"


def match_any(patterns, string, flags=0):
    for pattern in patterns:
        if re.match(pattern, string, flags):
            return True
    return False


def split_commands(script):
    LINEFEED = '\n'
    SEMICOLON = ';'
    SENTINEL = chr(0)
    RE_FLAGS = re.IGNORECASE

    is_nested = False

    lines = script.split(LINEFEED)
    for i, line in enumerate(lines):
        if is_nested:

            if re.match(end_nested, line, RE_FLAGS):
                lines[i] = line.replace(SEMICOLON, SENTINEL + SEMICOLON)
                is_nested = False
                continue

            lines[i] = line.replace(SEMICOLON, SENTINEL)
            continue

        if match_any(start_nested, line, RE_FLAGS):
            is_nested = True
            continue

    commands = LINEFEED.join(lines).split(SEMICOLON)
    return [
        command.replace(SENTINEL, SEMICOLON)
        for command in commands
    ]


@db.command('init')
def init_db():
    db = get_db()
    path = os.path.join(current_app.root_path, '../../oracle/model.sql')

    start_total = time.time()

    with db.cursor() as cursor:
        with open(path) as file:
            commands = split_commands(file.read())

        for i, command in enumerate([ c.strip() for c in commands[:-1] ]):

            if i != 0: print()
            print(command)

            start = time.time()
            cursor.execute(command)
            end = time.time()

            delta = (end - start) * 1000
            print('-> TOOK %.2fms' % (delta,))

    db.commit()

    delta_total = time.time() - start_total
    print('=> DONE %.1fs' % (delta_total,))


@db.command('demo')
def create_demo():
    add_test_data()
