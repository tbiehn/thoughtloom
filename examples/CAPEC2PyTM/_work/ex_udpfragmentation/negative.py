#!/usr/bin/env python3

from pytm import (
    TM,
    Server,
)

tm = TM("Negative Example")

server = Server("Target Server")
server.protocol = "TCP"

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
