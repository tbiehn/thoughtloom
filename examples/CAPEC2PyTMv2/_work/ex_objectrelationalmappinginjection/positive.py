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

user = Actor("User")

db = Datastore("SQL Database")
db.isSQL = True
db.hasWriteAccess = True
db.controls.sanitizesInput = False
db.controls.validatesInput = False
db.controls.implementsPOLP = False
db.controls.usesParameterizedInput = False

user_to_db = Dataflow(user, db, "User enters data")
user_to_db.data = Data("User input", classification=Classification.PUBLIC)

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
