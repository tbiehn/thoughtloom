#!/usr/bin/env python3

from pytm import (
    TM,
    Server,
    Datastore,
)

tm = TM("Negative Example")

server = Server("Web Server")
server.OS = "Linux"
server.hasNTFSFileSystem = False

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
