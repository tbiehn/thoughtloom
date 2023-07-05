#!/usr/bin/env python3

from pytm import (
    TM,
    Server,
    Dataflow,
    Actor,
)

tm = TM("Positive Example")

tm.isOrdered = True
tm.mergeResponses = True

user = Actor("User")

web = Server("Web Server")
web.codeType="Web server"
web.implementsAPI = True
web.controls.validatesInput = False
web.controls.sanitizesInput = False
web.controls.implementsAuthenticationScheme = False
web.controls.hasAccessControl = False

user_to_web = Dataflow(user, web, "User sends HTTP request")
user_to_web.protocol = "HTTP"

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
