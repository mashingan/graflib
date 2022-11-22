# graflib
# Copyright Rahmatullah
# A minimum graph implementation library
# License MIT

## Graflib
## *******
##
## A simple graph implementation library.
## To scrutiny the trail when walking the graph, define ``trail`` to
## see in stdout the nodes visited.
## Compile it:
##
## ::
##
##   $ nim c -d:trail yourcodefile
##
## The current implementation walks into graph nodes to find the connection
## between origin node to destination node without consider the weight cost
## each edge has. The sequences of nodes (vertices) will have its each
## vertex/node having weight which different with defined nodes' weight.
## The weight resulted in sequence of vertices for each node is actually
## the cost of calculated edge so we can use that together with algorithm
## module to find out the total cost of resulting path.
##
## Example
## -------
##
##   .. code-block:: Nim
##     
##     from sequtils import mapIt
##     import graflib
##
##     # we build unweighted and undirected empty graph
##     var graph = buildGraph[char]()
##     doAssert(graph.vertices.len == 0)
##     doAssert(graph.edges.len == 0)
##
##     # Add edgest to our graph
##     graph.addEdges [
##       ("origin1", "destination1"),
##       ("origin2", "destination2"),
##       ("origin1", "destination2"),
##       ("origin1", "origin2", 0)
##     ].mapIt( initEdge(it[0], it[1]) )
##     doAssert(graph.edges.len == 4)
##     doAssert(graph.vertices.len == 4)
##
##     # Find paths from origin to destination node
##     var paths = graph.paths("origin1", "destination2")
##     doAssert(paths.len == 2)
##     doAssert(paths[0] == @["origin1", "destination2"]
##
##     # degree = indegree + outdegree
##     doAssert(graph.degree("origin1") == 3)
##     doAssert(graph.degree("origin2") == 2)
##
## When walking the connected graph, we use defined `==`
## for Vertex comparison. Hence if we use a specialized type
## for Vertex label, we need to define `==` operator for our type.
## 
## With additional A* search (proc `a*`), users must provide additional
## procs to make it works. Read the `a*` proc documentation for the detail.

import sequtils, tables, deques
from algorithm import reverse
import heapqueue
from sugar import dump

type
  Graph*[T] = object
    ## Graph type that implemented generically using ``T`` type as label
    ## and ``R`` as weight type.
    directed*: bool         ## If true, every edge has only a direction
                            ## for each time its defined.
    vertices*: seq[T]    ## Vertices or nodes
    edges*: seq[Edge[T]] ## Edge which spanned between node1 and node2

  Vertex*[T] = T  ## Alias left-over from previous dev version

  Edge*[T] = object
    ## Representation of two connected nodes with weight cost.
    node1*: T
    node2*: T

  GraphRef*[T] = ref Graph[T]
    ## Reference-type graph.

template label*(v: untyped): untyped = v

template withinTrail (body: typed): untyped =
  when defined(trail):
    body

proc `==`*(a, b: Edge): bool =
  result = a.node1 == b.node1 and
           a.node2 == b.node2

proc initEdge*[T](n1, n2: T): Edge[T] =
  Edge[T](node1: n1, node2: n2)

proc isDirected* (graph: Graph): bool = graph.directed

proc contains*(graph: Graph, vertice: Vertex): bool =
  vertice in graph.vertices

proc contains*[T] (graph: Graph[T], edge: Edge[T]): bool =
  if graph.isDirected:
    edge in graph.edges
  else:
    var swappedEdge = Edge[T](node1: edge.node2, node2: edge.node1,
      weight: edge.weight)
    edge in graph.edges or swappedEdge in graph.edges

proc contains*[T](edge: Edge[T], vertex: Vertex[T]): bool =
  if vertex.label == edge.node1 or vertex.label == edge.node2: true
  else: false

proc addVertices*[T](graph: var Graph[T], vertices: varargs[T]) =
  for vertex in items(vertices):
    if vertex notin graph.vertices:
      graph.vertices.add vertex

proc addEdges*[T] (graph: var Graph, edges: varargs[Edge[T]]) =
  for edge in items(edges):
    let
      node1 = edge.node1
      node2 = edge.node2
      v1 = node1
      v2 = node2
      swappedEdge = Edge[T](node1: node2,
        node2: node1)

    if v1 notin graph.vertices:
      graph.vertices.add v1
    if v2 notin graph.vertices:
      graph.vertices.add v2

    if graph.isDirected and edge notin graph.edges:
      graph.edges.add edge
    elif not graph.isDirected and edge notin graph.edges and
        swappedEdge notin graph.edges:
      graph.edges.add edge

proc buildGraph*[T](vertices: openArray[Vertex[T]] = @[],
    edges: openArray[Edge[T]] = @[],
    directed: bool = false, weighted: bool = false): Graph[T] =
  result = Graph[T](vertices: @vertices, edges: @edges,
    directed: directed)
  
  for edge in items(edges):
    let
      v1 = edge.node1
      v2 = edge.node2
    if v1 notin result.vertices:
      result.vertices.add v1
    elif v2 notin result.vertices:
      result.vertices.add v2

proc neighbors*[T](graph: Graph[T], vertex: T): seq[T] =
  result = newSeq[T]()
  for edge in graph.edges:
    let
      v1 = edge.node1
      v2 = edge.node2
    if vertex.label == edge.node1 and v2 notin result:
      result.add v2
    elif not graph.directed and vertex.label == edge.node2 and v1 notin result:
      result.add v1

proc `$`*[T](graph: Graph[T]): string =
  result = if graph.isDirected: "Directed "
           else: "Undirected "
  result &= "Graph with "
  result &= $(graph.vertices.len) & " vertices and " &
    $(graph.edges.len) & " edges."
  result &= "\nvertices: " & $(graph.vertices)
  result &= "\nedges: " & $(graph.edges)

proc `$`*(edge: Edge): string =
  $edge.node1 & ":" & $edge.node2

proc indegree*[T](graph: Graph[T], vertex: T): int =
  graph.edges.filterIt( it.node2 == vertex).len

proc outdegree*[T](graph: Graph[T], vertex: T): int =
  graph.edges.filterIt( it.node1 == vertex).len

proc degree*(graph: Graph, vertex: Vertex): int =
  graph.indegree(vertex) + graph.outdegree(vertex)

proc buildDigraph*[T](): Graph =
  buildGraph[T](directed = true)

proc newGraph*[T](): GraphRef[T] =
  GraphRef[T](vertices: @[], edges: @[], directed: false)

proc isConnected*[T](graph: Graph[T]): bool =
  result = true
  for vertex in graph.vertices:
    for edge in graph.edges:
      if vertex notin edge: return false

proc swapEdge[T](edge:Edge[T]): Edge[T] =
  Edge[T](node1: edge.node2, node2: edge.node1)


proc paths*[T](graph: Graph[T],v1, v2: Vertex[T]):
    seq[seq[Vertex[T]]] =
  if v1 notin graph.vertices or v2 notin graph.vertices:
    return @[]

  var
    edges = if graph.isDirected: graph.edges
            else: graph.edges.concat(graph.edges.map swapEdge)
    tempresult = newSeq[seq[Vertex[T]]]()

  template outFilt (x: untyped): untyped =
    var buff = newseq[Vertex[T]]()
    for edge in edges:
      if x.label == edge.node1:
        buff.add edge.node2
    buff

  var outbounds = outFilt v1
  withinTrail: echo "current outbounds: ", outbounds

  proc inPath(goal, v: Vertex, state: var seq[Vertex]): bool =
    withinTrail:
      echo "visiting: ", v
      echo "current state: ", state
    state.add v
    if v == goal:
      withinTrail: echo "return state: ", state
      tempresult.add state
      state = state[0 .. ^2]
      return true
    var nextbound = outFilt(v)
    withinTrail: echo "current nextbound: ", nextbound
    if nextbound == @[]:
      withinTrail: echo "no nextbound"
    var nextstate = newSeq[Vertex[T]]()
    for next in nextbound:
      withinTrail: echo "to visit next: ", next
      if next in state:
        withinTrail: echo next, " already in state"
        continue
      if not inPath(goal, next, state):
        state = state[0 .. ^2]
    withinTrail: echo "nextstate: ", nextstate
    false

  for v in outbounds:
    var state = @[v1]
    discard inpath(v2, v, state)

  withinTrail: echo "tempresult: ", tempresult
  result = tempresult.deduplicate

proc shortestPath*[T](graph: Graph[T], v1, v2: T):
    seq[Vertex[T]] =
  if v1 notin graph or v2 notin graph:
    return @[]
  let conn = if graph.isDirected: graph.edges
             else: graph.edges.concat(graph.edges.map swapEdge)
  withinTrail:
    dump conn
  var
    visited = newseq[Vertex[T]]()
    parent = newTable[Vertex[T], Vertex[T]]()
    neighbor = initDeque[Vertex[T]]()
    connected = false

  template nextVisiting(x: untyped): untyped =
    var next = initHeapQueue[Vertex[T]]()
    for edge in conn:
      if x.label == edge.node1:
        let node = edge.node2
        next.push node
        if node notin parent: parent[node] = x
    next
  template addedToNeighbour(ns: HeapQueue[Vertex]) =
    for i in 0 ..< ns.len: neighbor.addLast ns[i]

  visited.add v1
  v1.nextVisiting.addedToNeighbour
  while neighbor.len > 0:
    let n = neighbor.popFirst
    if n in visited: continue
    visited.add n
    if n == v2:
      connected = true
      break
    n.nextVisiting.addedToNeighbour

  if not connected:
    return @[]

  var curr = visited[^1]
  while curr != v1:
    result.add curr
    curr = parent[curr]
  result.add curr
  result.reverse

proc adjacencyMatrix*[T](graph: Graph[T]): seq[seq[int]] =
  let
    m = graph.vertices.len
    edges = if graph.isDirected: graph.edges
            else: graph.edges.concat(graph.edges.map swapEdge)
  result = 0.repeat(m).repeat(m)

  for edge in edges:
    let
      i = graph.vertices.find(edge.node1)
      j = graph.vertices.find(edge.node2)
    result[i][j] = 1

proc incidenceMatrix*(graph: Graph): seq[seq[int]] =
  let
    m = graph.vertices.len
    edges = if graph.isDirected: graph.edges
            else: graph.edges.concat(graph.edges.map swapEdge)
    n = edges.len
  result = 0.repeat(n).repeat(m)
  
  for i in 0 .. <m:
    let node = graph.vertices[i]
    for j in 0 .. <n:
      let edge = edges[j]
      result[i][j] = if node.label == edge.node1 and
                        node.label == edge.node2: 2
                     elif node.label == edge.node1: 1
                     elif node.label == edge.node2: -1
                     else: 0

proc deleteVertex*[T](graph: var Graph[T], vertex: Vertex[T]):
    bool =
  let pos = graph.vertices.find(vertex)
  if pos >= 0:
    graph.vertices.delete(pos)
    graph.edges.keepIf(proc(e: Edge[T]): bool =
      e.node1 != vertex.label and e.node2 != vertex.label
    )

    true
  else:
    false

proc deleteEdge*[T](graph: var Graph[T], edge: Edge[T]): bool =
  let pos = graph.edges.find(edge)
  if pos >= 0:
    graph.edges.delete(pos, pos)
    true
  else:
    false

type PriorityNode[T, C] = object
  node: Vertex[T]
  cost: C

proc `<`*[T, C](p1, p2: PriorityNode[T, C]): bool = p1.cost < p2.cost
  ## Internal function. Won't be usable because the PriorityNode itself is
  ## private. Added to support priority queue that requires this operator
  ## visible in the priority queue module.

proc `a*`*[T, C](graph: var Graph[T], start, goal: T): seq[Vertex[T]] =
  ## A* search based on its start (v1) label (v2) to end.
  ## Users need to provide accessible `proc cost(v1, v2: T): R` and
  ## `proc distance(v1, v2: T): R` with T and R are matched with Graph[T].
  ## In rare case users could also need to provide operator "+" and "<" for T
  ## that returns R viz ```nim proc `+`(cost1, cost2: R): R``` and
  ## ```nim proc `<`(cost1, cost2: R): bool```.
  ## Additionally users could be needed to provide the hash proc for T,
  ## i.e `proc hash(t: T): Hash`. Check the std/hashes on how to do it.

  var
    costSoFar = initTable[T, C]()
    visited = initTable[T, T]()
    visiting = initHeapQueue[PriorityNode[T, C]]()
    thecost: C

  costSoFar[start] = thecost
  visited[start] = start
  visiting.push(PriorityNode[T, C](node: start, cost: thecost))
  while visiting.len > 0:
    let nextpriority = visiting.pop
    let node = nextpriority.node
    if node == goal: break
    let nextvisit = graph.neighbors(node)
    withinTrail:
      echo "visiting: ", node
    for nextnode in nextvisit:
      thecost = costSoFar[node] + node.label.cost(nextnode.label)
      if nextnode notin costSoFar or thecost < costSoFar[nextnode]:
        costSoFar[nextnode] = thecost
        let priority = thecost + nextnode.label.distance(goal.label)
        visiting.push(PriorityNode[T, C](node: nextnode, cost: priority))
        visited[nextnode] = node
        withinTrail:
          echo "added to queue with priority: ", priority

  var current = goal
  while true:
    result.add current
    if current == start: break
    if current notin visited: return @[]
    current = visited[current]

  result.reverse

when isMainModule:
  from strutils import join
  from std/strformat import fmt
  var graph = buildGraph[char]()
  #[
  graph.vertices = @['a', 'b', 'c', 'd', 'e']
  graph.addEdges(('a', 'b'), ('a', 'e'), ('b', 'c'))
  echo graph
  graph.addVertices 'a'
  graph.addVertices 'f'
  graph.addEdges(('b', 'a'))
  echo graph
  echo graph.neighbors('a')
  graph.addVertices(['f', 'g', 'h'])
  echo graph
  echo graph.neighbors 'h'
  var graph2 = buildGraph[int]()
  graph2.addEdges((1, 2), (1, 3), (1, 4), (2, 3), (3, 4))
  echo graph2
  graph2.addEdges((2, 1))
  echo graph2
  echo "Changed to directed graph"
  graph2.directed = true
  graph2.addEdges((2, 1))
  echo graph2
  var graphRef = newGraph[int]()
  echo graphRef.repr
  graphRef.vertices = @[1, 2, 3]
  echo graphRef[]
  echo "degree of 1 is " & $graphRef[].degree(1)
  graph.addEdges(('a', 'b'), ('b', 'c'), ('c', 'd'))
  ]#
  #graph.directed = true
  graph.addEdges(Edge[char](node1:'a', node2:'b'),
    Edge[char](node1:'b', node2:'c'),
    Edge[char](node1:'c', node2:'d'))

  proc makeEdge[T](conns: varargs[tuple[n1, n2: T]]): seq[Edge[T]] =
    result = newSeq[Edge[T]](conns.len)
    for i, edge in conns:
      result[i] = Edge[T](node1: edge.n1, node2: edge.n2)

  #[
  echo "degree a: ", graph.degree('a'), ": ", graph.neighbors('a')
  echo "degree b: ", graph.degree('b'), ": ", graph.neighbors('b')
  echo "degree c: ", graph.degree('c'), ": ", graph.neighbors('c')
  ]#
  graph.addEdges(makeEdge[char](('d', 'f'), ('b', 'e'), ('e', 'f'),
    ('f', 'g'), ('g', 'b'), ('a', 'e'), ('c', 'e')))
  echo "graph edges are\n    ", graph.edges.join("\n    ")
  echo "degree a: ", graph.degree('a'), ": ", graph.neighbors('a')
  echo "degree b: ", graph.degree('b'), ": ", graph.neighbors('b')
  echo "degree c: ", graph.degree('c'), ": ", graph.neighbors('c')
  echo if graph.isConnected: "graph is connected"
       else: "graph is disconnected"
  echo "all paths:\n\t", graph.paths('g', 'd').join("\n\t")
  #echo graph.paths('a', 'd')
  echo "shortest path: ", graph.shortestPath('g','d')
  echo "adjacency matrix:"
  for adj in graph.adjacencyMatrix():
    echo '\t', adj

  func cost(v1, v2: char): int = 1
  func distance(v1, v2: char): int = 0

  #echo "A*: ", graph.`a*`[char, int]('g', 'd')
  echo "A*: ", `a*`[char, int](graph, 'g', 'd')
  let g = 'g'
  if graph.deleteVertex(g):
    echo "Vertex ", g, " is deleted"
    echo fmt"now graph is {graph}"
