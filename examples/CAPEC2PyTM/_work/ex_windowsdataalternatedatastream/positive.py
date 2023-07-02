#!/usr/bin/env python3

from pytm import (
    TM,
    Server,
    Datastore,
)

tm = TM("Positive Example")

server = Server("Web Server")
server.OS = "Windows"
server.hasNTFSFileSystem = True

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
