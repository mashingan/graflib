## This is example of solving water jugs to reach 4 L from available 3 and 5 L jugs.
## Each jug can only fill to its full capacity or empty the jug.
## For example: jug 3 L has full capacity and jug 5 L has 1 L, so we pour from jug 3 to jug 5
## as long the jug 5 has capacity or jug 3 still not empty. After that, we have jug 3 empty and jug 5
## 4 L.
## Another case, we have illegal pouring for example, jug 3 is empty and jug 5 has 3 L, we can't
## pour to jug 3 only a liter to be jug 3 has 1 L and jug 5 has 2 L. We can't do this due to
## the jug doesn't have a measure on how much it's pouring. Either full capacity pouring or
## or full capacity poured.
##
## In this example, we see 2 kinds of various state-space searching, the first is looking for all available
## solutions with function ``paths``, this is Depth-first search. The second is looking using A* search.
## For A* search, because we define the distance and the cost is zero between states, it's basically
## just a Breadth-first search due to no paths prioritized.
import std/[sugar, strformat]
import graflib

const
  cap1 {.intdefine.}: int = 3
  cap2 {.intdefine.}: int = 5
  targetcap {.intdefine.} = 4

when targetcap > cap1 and targetcap > cap2:
  {.error: &"targetcap ({targetcap}) cannot bigger than any capacities, {cap1} and {cap2}".}
type
  FirstJug = range[0..cap1]
  SecondJug = range[0..cap2]
  Waterjugs = (FirstJug, SecondJug)

func distance(w1, w2: Waterjugs): int = 0
func cost(w1, w2: Waterjugs): int = 0

var graf = buildGraph[Waterjugs](directed = true)

# emtpy glass
for i in FirstJug.low .. FirstJug.high:
  for j in SecondJug.low .. SecondJug.high:
    if i > FirstJug.low:
      graf.addEdges(((i, j), (FirstJug.low, j)))

    if j > SecondJug.low:
      graf.addEdges(((i, j), (i, SecondJug.low)))

# full glass
for i in FirstJug.low .. FirstJug.high:
  for j in SecondJug.low .. SecondJug.high:
    if i < FirstJug.high:
      graf.addEdges(((i, j), (FirstJug.high, j)))
    if j < SecondJug.high:
      graf.addEdges(((i, j), (i, SecondJug.high)))

# pour jug 2 to jug 5
for i in FirstJug.low+1 .. FirstJug.high:
  for j in SecondJug.low .. SecondJug.high-1:
    let toPour = min(abs(SecondJug.high - j), i)
    let edge = Edge[Waterjugs](
      node1: (FirstJug i, j),
      node2: (FirstJug max(FirstJug.low, i - toPour),
              SecondJug min(SecondJug.high, j + toPour))
    )
    graf.addEdges edge

# pour jug 5 to jug 2
for i in FirstJug.low .. FirstJug.high-1:
  for j in SecondJug.low+1 .. SecondJug.high:
    let toPour = min(abs(FirstJug.high - i), j)
    let edge = Edge[Waterjugs](
      node1: (i, SecondJug j),
      node2: (
        FirstJug max(FirstJug.high, i + toPour),
        SecondJug min(SecondJug.high, j - toPour))
    )
    graf.addEdges edge

let empty = (FirstJug 0, SecondJug 0)
when cap1 > cap2:
  let fourL = collect(for i in SecondJug.low .. SecondJug.high: (FirstJug targetcap, i))
else:
  let fourL = collect(for i in FirstJug.low .. FirstJug.high: (i, SecondJug targetcap))
for goal in fourL:
  echo fmt"Looking for steps from {empty} to {goal}"
  for step in graf.paths(empty, goal):
    dump step

for goal in fourL:
  echo fmt"Looking for steps from {empty} to {goal} with A*"
  echo `a*`[Waterjugs, int](graf, empty, goal)