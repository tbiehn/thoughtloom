#!/usr/bin/env python3

from pytm import (
    TM,
    Server,
)

tm = TM("Positive Example")

server = Server("Target Server")
server.protocol = "UDP"

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
