## This is example of solving water jugs to reach 4 L from available 2 and 5 L jugs.
## Each jug can only fill to its full capacity or empty the jug.
## For example: jug 2 L has full capacity and jug 5 L has 1 L, so we pour from jug 2 to jug 5
## as long the jug 5 has capacity or jug 2 still not empty. After that, we have jug 2 empty and jug 5
## 3 L.
## Another case, we have illegal pouring for example, jug 2 is empty and jug 5 has 3 L, we can't
## pour jug 2 only a liter to be jug 2 has 1 L and jug 5 has 2 L. We can't do this due to
## the jug doesn't have a measure on how much it's pouring. Either full capacity pouring or
## or full capacity poured.
##
## In this example, we see 2 kinds of various state-space searching, the first is looking for all available
## solutions with function ``paths``, this is Depth-first search. The second is looking using A* search.
## For A* search, because we define the distance and the cost is zero between states, it's basically
## just a Breadth-first search due to no paths prioritized.
import std/[sugar, strformat]
import graflib

type
  Jug2 = range[0..2]
  Jug5 = range[0..5]
  Waterjugs = object
    jug2: Jug2
    jug5: Jug5

func distance(w1, w2: Waterjugs): int = 0
func cost(w1, w2: Waterjugs): int = 0

var graf = buildGraph[Waterjugs](directed = true)

# emtpy glass
for i in Jug2.low .. Jug2.high:
  for j in Jug5.low .. Jug5.high:
    if i > Jug2.low:
      graf.addEdges(Edge[Waterjugs](
        node1: Waterjugs(jug2: i, jug5: j),
        node2: Waterjugs(jug2: Jug2.low, jug5: j)))
    if j > Jug5.low:
      graf.addEdges(Edge[Waterjugs](
        node1: Waterjugs(jug2: i, jug5: j),
        node2: Waterjugs(jug2: i, jug5: Jug5.low)))

# full glass
for i in Jug2.low .. Jug2.high:
  for j in Jug5.low .. Jug5.high:
    if i < Jug2.high:
      graf.addEdges(Edge[Waterjugs](
        node1: Waterjugs(jug2: i, jug5: j),
        node2: Waterjugs(jug2: Jug2.high, jug5: j)))
    if j < Jug5.high:
      graf.addEdges(Edge[Waterjugs](
        node1: Waterjugs(jug2: i, jug5: j),
        node2: Waterjugs(jug2: i, jug5: Jug5.high)))

# pour jug 2 to jug 5
for i in Jug2.low+1 .. Jug2.high:
  for j in Jug5.low .. Jug5.high-1:
    let toPour = min(abs(Jug5.high - j), i)
    let edge = Edge[Waterjugs](
      node1: Waterjugs(jug2: i, jug5: j),
      node2: Waterjugs(jug2: max(0, i - toPour), jug5: min(5, j + toPour))
    )
    graf.addEdges edge

# pour jug 5 to jug 2
for i in Jug2.low .. Jug2.high-1:
  for j in Jug5.low+1 .. Jug5.high:
    let toPour = min(abs(Jug2.high - i), j)
    let edge = Edge[Waterjugs](
      node1: Waterjugs(jug2: i, jug5: j),
      node2: Waterjugs(jug2: max(2, i + toPour), jug5: min(5, j - toPour))
    )
    graf.addEdges edge

let empty = Waterjugs(jug2: 0, jug5: 0)
let fourL = collect(for i in Jug2.low .. Jug2.high: Waterjugs(jug2: i, jug5: 4))
for goal in fourL:
  echo fmt"Looking for steps from {empty} to {goal}"
  for step in graf.paths(empty, goal):
    dump step

for goal in fourL:
  echo fmt"Looking for steps from {empty} to {goal} with A*"
  echo `a*`[Waterjugs, int](graf, empty, goal)
