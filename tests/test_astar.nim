import std/[unittest, hashes]
import graflib

## This test is also example of how to search using A* method.
## This example is adapted and solved from Advent of Code 2021 Day 15.
## Ref: https://adventofcode.com/2021/day/15
## This example only takes the input example in the page hence the
## mapgraph' lines is already lined in seq[string] but the method
## to solve is still same. Hint: use
## [io.readLines](https://nim-lang.org/docs/io.html#readLines,string,Natural)
## to read from `stdin` file.

type Coord = object
  x, y, weight: int

func distance(c1, c2: Coord): int =
  abs(c1.x - c2.x) + abs(c1.y - c2.y)
func cost(c1, c2: Coord): int = c2.weight

proc hash(c: Coord): Hash =
  var h: Hash = 0
  h = h !& hash(c.x)
  h = h !& hash(c.y)
  h = h !& hash(c.weight)
  result = !$h

test "A* search":
  let mapgraph = @[
    "1163751742",
    "1381373672",
    "2136511328",
    "3694931569",
    "7463417111",
    "1319128137",
    "1359912421",
    "3125421639",
    "1293138521",
    "2311944581",
  ]

  var thenewgraph = buildGraph[Coord]()
  var mapnum = newseq[seq[int]](mapgraph.len)
  for i, line in mapgraph:
    var lineseq = newseq[int](line.len)
    for j, c in line:
      lineseq[j] = c.ord - '0'.ord
    mapnum[i] = lineseq

  for y in mapnum.low .. mapnum.high:
    for x in mapnum[y].low .. mapnum[y].high:
      let c = Coord(x: x+1, y: y+1, weight: mapnum[y][x])
      thenewgraph.addVertices c
      if x-1 >= mapnum[y].low:
        let c1 = Coord(x: x, y: y+1, weight: mapnum[y][x-1])
        thenewgraph.addVertices c1
        thenewgraph.addEdges Edge[Coord](node1: c, node2: c1)

      if x+1 <= mapnum[y].high:
        let c1 = Coord(x: x+2, y: y+1, weight: mapnum[y][x+1])
        thenewgraph.addVertices c1
        thenewgraph.addEdges Edge[Coord](node1: c, node2: c1)

      if y-1 >= mapnum.low:
        let c1 = Coord(x: x+1, y: y, weight: mapnum[y-1][x])
        thenewgraph.addVertices c1
        thenewgraph.addEdges Edge[Coord](node1: c, node2: c1)

      if y+1 <= mapnum.high:
        let c1 = Coord(x: x+1, y: y+2, weight: mapnum[y+1][x])
        thenewgraph.addVertices c1
        thenewgraph.addEdges Edge[Coord](node1: c, node2: c1)

  let
    start = Coord(x: 1, y: 1, weight: mapnum[0][0])
    goal = Coord(x: 10, y: 10, weight: mapnum[9][9])
    newgraphAstarPath = `a*`[Coord, int](thenewgraph, start, goal)
  var totalcount = 0
  for node in newgraphAstarPath[1..^1]:
    totalcount += node.label.weight
  check totalcount == 40
  let expectedPath = @[
    Coord(x: 1, y: 1, weight: 1),
    Coord(x: 1, y: 2, weight: 1),
    Coord(x: 1, y: 3, weight: 2),
    Coord(x: 2, y: 3, weight: 1),
    Coord(x: 3, y: 3, weight: 3),
    Coord(x: 4, y: 3, weight: 6),
    Coord(x: 5, y: 3, weight: 5),
    Coord(x: 6, y: 3, weight: 1),
    Coord(x: 7, y: 3, weight: 1),
    Coord(x: 7, y: 4, weight: 1),
    Coord(x: 8, y: 4, weight: 5),
    Coord(x: 8, y: 5, weight: 1),
    Coord(x: 8, y: 6, weight: 1),
    Coord(x: 9, y: 6, weight: 3),
    Coord(x: 9, y: 7, weight: 2),
    Coord(x: 9, y: 8, weight: 3),
    Coord(x: 9, y: 9, weight: 2),
    Coord(x: 10, y: 9, weight: 1),
    Coord(x: 10, y: 10, weight: 1),
  ]
  when defined(trail):
    echo "the a* paths"
    for path in newgraphAstarPath:
      echo path
  for i, path in newgraphAstarPath:
    check path.label == expectedPath[i]
