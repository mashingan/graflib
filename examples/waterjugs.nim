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

type
  Jug3 = range[0..3]
  Jug5 = range[0..5]
  Waterjugs = object
    jug3: Jug3
    jug5: Jug5

func distance(w1, w2: Waterjugs): int = 0
func cost(w1, w2: Waterjugs): int = 0

var graf = buildGraph[Waterjugs](directed = true)

# emtpy glass
for i in Jug3.low .. Jug3.high:
  for j in Jug5.low .. Jug5.high:
    if i > Jug3.low:
      graf.addEdges(Edge[Waterjugs](
        node1: Waterjugs(jug3: i, jug5: j),
        node2: Waterjugs(jug3: Jug3.low, jug5: j)))
    if j > Jug5.low:
      graf.addEdges(Edge[Waterjugs](
        node1: Waterjugs(jug3: i, jug5: j),
        node2: Waterjugs(jug3: i, jug5: Jug5.low)))

# full glass
for i in Jug3.low .. Jug3.high:
  for j in Jug5.low .. Jug5.high:
    if i < Jug3.high:
      graf.addEdges(Edge[Waterjugs](
        node1: Waterjugs(jug3: i, jug5: j),
        node2: Waterjugs(jug3: Jug3.high, jug5: j)))
    if j < Jug5.high:
      graf.addEdges(Edge[Waterjugs](
        node1: Waterjugs(jug3: i, jug5: j),
        node2: Waterjugs(jug3: i, jug5: Jug5.high)))

# pour jug 2 to jug 5
for i in Jug3.low+1 .. Jug3.high:
  for j in Jug5.low .. Jug5.high-1:
    let toPour = min(abs(Jug5.high - j), i)
    let edge = Edge[Waterjugs](
      node1: Waterjugs(jug3: i, jug5: j),
      node2: Waterjugs(
        jug3: max(Jug3.low, i - toPour),
        jug5: min(Jug5.high, j + toPour))
    )
    graf.addEdges edge

# pour jug 5 to jug 2
for i in Jug3.low .. Jug3.high-1:
  for j in Jug5.low+1 .. Jug5.high:
    let toPour = min(abs(Jug3.high - i), j)
    let edge = Edge[Waterjugs](
      node1: Waterjugs(jug3: i, jug5: j),
      node2: Waterjugs(
        jug3: max(Jug3.high, i + toPour),
        jug5: min(Jug5.high, j - toPour))
    )
    graf.addEdges edge

let empty = Waterjugs(jug3: 0, jug5: 0)
let fourL = collect(for i in Jug3.low .. Jug3.high: Waterjugs(jug3: i, jug5: 4))
for goal in fourL:
  echo fmt"Looking for steps from {empty} to {goal}"
  for step in graf.paths(empty, goal):
    dump step

for goal in fourL:
  echo fmt"Looking for steps from {empty} to {goal} with A*"
  echo `a*`[Waterjugs, int](graf, empty, goal)