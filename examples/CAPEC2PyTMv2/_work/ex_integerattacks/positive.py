#!/usr/bin/env python3

from pytm import TM, Server, Datastore, Dataflow, Data, Classification

tm = TM("Positive Example")

server = Server("Web Server")
server.tracksExecutionFlow = True

user_data = Data("User Data", classification=Classification.RESTRICTED)
user_data.isStored = True

user_db = Datastore("User Database")
user_db.storesLogData = True
user_db.data = [user_data]

user_to_server = Dataflow(server, user_db, "User to Server")
user_to_server.data = user_data

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
