#!/usr/bin/env python3

from pytm import (
    TM,
    Server,
)

tm = TM("Negative Example")

server = Server("Web Server")
server.controls.validatesInput = True

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
