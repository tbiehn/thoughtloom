#!/usr/bin/env python3

from pytm import TM, Server, Dataflow, Boundary, Actor, Process

tm = TM("Symlink Attack")

target = Boundary("Target System")

attacker = Actor("Attacker")

vulnerable_process = Process("Vulnerable Process")
vulnerable_process.inBoundary = target
vulnerable_process.usesSymlinks = True
vulnerable_process.controls.validatesInput = False

attack = Dataflow(attacker, vulnerable_process, "Symlink Attack")

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
