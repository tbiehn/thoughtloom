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

user = Actor("User")
user.inBoundary = internet

web = Server("Web Server")
web.OS = "Ubuntu"
web.controls.isEncrypted = False

proc = Process("A process")
proc.codeType="C"
proc.implementsAPI = True

userIdToken = Data(
    name="User ID Token",
    description="Some unique token that represents the user real data in the secret database",
    classification=Classification.TOP_SECRET,
)

user_to_web = Dataflow(user, web, "User enters comments (*)")
user_to_web.protocol = "HTTP"
user_to_web.data = userIdToken

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
