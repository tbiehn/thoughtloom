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

tm = TM("Negative Example")

user = Actor("User")

web = Server("Web Server")
web.controls.sanitizesInput = True
web.controls.validatesInput = True

user_data = Data("User Data", classification=Classification.PUBLIC)
user_to_web = Dataflow(user, web, "User enters data (*)")
user_to_web.data = user_data

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
