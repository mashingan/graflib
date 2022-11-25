## Version 2 by defining custom outgoing state as next available states.

import std/[sugar, strformat]
import graflib
const
  cap1 {.intdefine.}: int = 3
  cap2 {.intdefine.}: int = 5
  targetcap {.intdefine.} = 4

type
  FirstJug = range[0..cap1]
  SecondJug = range[0..cap2]
  Waterjugs = (FirstJug, SecondJug)

func distance(w1, w2: Waterjugs): int = 0
func cost(w1, w2: Waterjugs): int = 0

var graf = buildGraph[Waterjugs](directed = true)

proc next(j: Waterjugs, edges: seq[Edge[Waterjugs]]): seq[Waterjugs] =

  # empty jug
  if j[0] > FirstJug.low:
    result.add (FirstJug.low, j[1])

  if j[1] > SecondJug.low:
    result.add (j[0], SecondJug.low)
  
  # full jug
  if j[0] < FirstJug.high:
    result.add (FirstJug.high, j[1])
  if j[1] < SecondJug.high:
    result.add (j[0], SecondJug.high)
  
  # pour jug 3 to jug 5
  if j[0] > FirstJug.low and j[1] < SecondJug.high:
    let toPour = min(abs(SecondJug.high - j[1]), j[0])
    result.add (FirstJug max(FirstJug.low, j[0] - toPour),
                SecondJug min(SecondJug.high, j[1] + toPour))

  # pour jug 5 to jug 2
  if j[1] > SecondJug.low and j[0] < FirstJug.high:
    let toPour = min(abs(FirstJug.high - j[0]), j[1])
    result.add (FirstJug max(FirstJug.high, j[0] + toPour),
                SecondJug min(SecondJug.high, j[1] - toPour))

let empty = (FirstJug 0, SecondJug 0)
let fourL = collect(for i in FirstJug.low .. FirstJug.high: (i, SecondJug targetcap))
for goal in fourL:
  echo fmt"Looking for steps from {empty} to {goal}"
  for step in graf.paths(empty, goal):
    dump step

for goal in fourL:
  echo fmt"Looking for steps from {empty} to {goal} with A*"
  echo `a*`[Waterjugs, int](graf, empty, goal)