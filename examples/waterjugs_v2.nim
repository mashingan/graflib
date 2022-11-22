## Version 2 by defining custom outgoing state as next available states.

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

## Uncomment this block to see that the edges are overrided by `next`
## defined below this entire commented edges addition.
# # emtpy glass
# for i in Jug3.low .. Jug3.high:
#   for j in Jug5.low .. Jug5.high:
#     if i > Jug3.low:
#       graf.addEdges(Edge[Waterjugs](
#         node1: Waterjugs(jug3: i, jug5: j),
#         node2: Waterjugs(jug3: Jug3.low, jug5: j)))
#     if j > Jug5.low:
#       graf.addEdges(Edge[Waterjugs](
#         node1: Waterjugs(jug3: i, jug5: j),
#         node2: Waterjugs(jug3: i, jug5: Jug5.low)))

# # full glass
# for i in Jug3.low .. Jug3.high:
#   for j in Jug5.low .. Jug5.high:
#     if i < Jug3.high:
#       graf.addEdges(Edge[Waterjugs](
#         node1: Waterjugs(jug3: i, jug5: j),
#         node2: Waterjugs(jug3: Jug3.high, jug5: j)))
#     if j < Jug5.high:
#       graf.addEdges(Edge[Waterjugs](
#         node1: Waterjugs(jug3: i, jug5: j),
#         node2: Waterjugs(jug3: i, jug5: Jug5.high)))

# # pour jug 2 to jug 5
# for i in Jug3.low+1 .. Jug3.high:
#   for j in Jug5.low .. Jug5.high-1:
#     let toPour = min(abs(Jug5.high - j), i)
#     let edge = Edge[Waterjugs](
#       node1: Waterjugs(jug3: i, jug5: j),
#       node2: Waterjugs(
#         jug3: max(Jug3.low, i - toPour),
#         jug5: min(Jug5.high, j + toPour))
#     )
#     graf.addEdges edge

# # pour jug 5 to jug 2
# for i in Jug3.low .. Jug3.high-1:
#   for j in Jug5.low+1 .. Jug5.high:
#     let toPour = min(abs(Jug3.high - i), j)
#     let edge = Edge[Waterjugs](
#       node1: Waterjugs(jug3: i, jug5: j),
#       node2: Waterjugs(
#         jug3: max(Jug3.high, i + toPour),
#         jug5: min(Jug5.high, j - toPour))
#     )
#     graf.addEdges edge

proc next(j: Waterjugs, edges: seq[Edge[Waterjugs]]): seq[Waterjugs] =

  # empty jug
  if j.jug3 > Jug3.low:
    result.add Waterjugs(jug3: 0, jug5: j.jug5)
  if j.jug5 > Jug5.low:
    result.add Waterjugs(jug3: j.jug3, jug5: 0)
  
  # full jug
  if j.jug3 < Jug3.high:
    result.add Waterjugs(jug3: Jug3.high, jug5: j.jug5)
  if j.jug5 < Jug5.high:
    result.add Waterjugs(jug3: j.jug3, jug5: Jug5.high)
  
  # pour jug 3 to jug 5
  if j.jug3 > Jug3.low and j.jug5 < Jug5.high:
    let toPour = min(abs(Jug5.high - j.jug5), j.jug3)
    result.add Waterjugs(
        jug3: max(Jug3.low, j.jug3 - toPour),
        jug5: min(Jug5.high, j.jug5 + toPour))

  # pour jug 5 to jug 2
  if j.jug5 > Jug5.low and j.jug3 < Jug3.high:
    let toPour = min(abs(Jug3.high - j.jug3), j.jug5)
    result.add Waterjugs(
        jug3: max(Jug3.high, j.jug3 + toPour),
        jug5: min(Jug5.high, j.jug5 - toPour))

let empty = Waterjugs(jug3: 0, jug5: 0)
let fourL = collect(for i in Jug3.low .. Jug3.high: Waterjugs(jug3: i, jug5: 4))
for goal in fourL:
  echo fmt"Looking for steps from {empty} to {goal}"
  for step in graf.paths(empty, goal):
    dump step

for goal in fourL:
  echo fmt"Looking for steps from {empty} to {goal} with A*"
  echo `a*`[Waterjugs, int](graf, empty, goal)