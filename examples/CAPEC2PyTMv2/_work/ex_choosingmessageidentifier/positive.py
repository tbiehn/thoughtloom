#!/usr/bin/env python3

from pytm import (
    TM,
    Actor,
    Boundary,
    Classification,
    Process,
    Data,
    Dataflow,
    Datastore,
    Lambda,
    Server,
    DatastoreType,
)

tm = TM("Positive Example")

tm.isOrdered = True
tm.mergeResponses = True

internet = Boundary("Internet")

server_db = Boundary("Server/DB")
server_db.levels = [2]

user = Actor("User")
user.inBoundary = internet
user.levels = [2]

web = Server("Web Server")
web.OS = "Ubuntu"
web.controls.sanitizesInput = False
web.controls.encodesOutput = True
web.controls.authenticatesDestination = False
web.controls.authenticatesSource = False
web.sourceFiles = ["pytm/json.py", "docs/template.md"]

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
