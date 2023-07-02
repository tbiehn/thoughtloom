#!/usr/bin/env python3

from pytm import (
    TM,
    Server,
)

tm = TM("Positive Example")

server = Server("Web Server")
server.controls.validatesInput = False

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
