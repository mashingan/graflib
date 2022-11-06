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
##     var graph = buildGraph[char, int]()
##     doAssert(graph.vertices.len == 0)
##     doAssert(graph.edges.len == 0)
##
##     # Add edgest to our graph
##     graph.addEdges [
##       ("origin1", "destination1", 0),
##       ("origin2", "destination2", 0),
##       ("origin1", "destination2", 0),
##       ("origin1", "origin2", 0)
##     ].mapIt( initEdge(it[0], it[1], it[2]) )
##     doAssert(graph.edges.len == 4)
##     doAssert(graph.vertices.len == 4)
##
##     # Find paths from origin to destination node
##     var paths = graph.paths(initVertex("origin1", 0), initVertex("destination2", 0))
##     doAssert(paths.len == 2)
##     doAssert(paths[0] == @[initVertex("origin1", 0), initVertex("destination2", 0)])
##
##     # degree = indegree + outdegree
##     doAssert(graph.degree(initVertex("origin1", 0)) == 3)
##     doAssert(graph.degree(initVertex("origin2", 0)) == 2)
##
## When walking the connected graph, we use defined `==`
## for Vertex comparison. Hence if we use a specialized type
## for Vertex label, we need to define `==` operator for our type.

import sequtils, tables, deques, hashes
from strutils import join
from algorithm import reverse
import heapqueue
from sugar import dump

type
  Graph*[T, R] = object
    ## Graph type that implemented generically using ``T`` type as label
    ## and ``R`` as weight type.
    directed*: bool               ## If true, every edge has only a direction
                                  ## for each time its defined.
    weighted*: bool               ## Whether the graph considered weighted
    vertices*: seq[Vertex[T, R]]  ## Vertices or nodes
    edges*: seq[Edge[T, R]]       ## Edge which spanned between node1 and node2

  Vertices*[T, R] = seq[Vertex[T, R]]
    ## An alias for sequence of nodes.

  Vertex*[T, R] = object
    ## Node representation
    label*: T     ## Label which used to identify node, usuall ``char`` or
                  ## ``string``
    weight*: R    ## Weight that will be used for various operations, such
                  ## determining most cost efficient path

  Edge*[T, R] = object
    ## Representation of two connected nodes with weight cost.
    node1*: T
    node2*: T
    weight*: R

  GraphRef*[T, R] = ref Graph[T, R]
    ## Reference-type graph.

template withinTrail (body: typed): untyped =
  when defined(trail):
    body


proc `==`*(a, b: Vertex): bool =
  a.label == b.label

proc `<`*(a, b: Vertex): bool =
  if a.weight < b.weight: true
  else: false

proc `==`*(a, b: Edge): bool =
  result = a.node1 == b.node1 and
           a.node2 == b.node2 and
           a.weight == b.weight

proc hash*(v: Vertex): Hash =
  !$v.label.hash

proc initEdge*[T, R](n1, n2: T, weight: R): Edge[T, R] =
  Edge[T, R](node1: n1, node2: n2, weight: weight)

proc initVertex*[T, R](label: T, weight: R): Vertex[T, R] =
  Vertex[T, R](label: label, weight: weight)

proc isDirected* (graph: Graph): bool = graph.directed
proc isWeighted*(graph: Graph): bool = graph.weighted

proc contains*(graph: Graph, vertice: Vertex): bool =
  vertice in graph.vertices

proc contains*[T,R] (graph: Graph[T,R], edge: Edge[T,R]): bool =
  if graph.isDirected:
    edge in graph.edges
  else:
    var swappedEdge = Edge[T, R](node1: edge.node2, node2: edge.node1,
      weight: edge.weight)
    edge in graph.edges or swappedEdge in graph.edges

proc contains (edge: Edge, vertex: Vertex): bool =
  if vertex.label == edge.node1 or vertex.label == edge.node2: true
  else: false

proc addVertices*[T,R](graph: var Graph, vertices: varargs[Vertex[T,R]]) =
  for vertex in items(vertices):
    if vertex notin graph.vertices:
      graph.vertices.add vertex

proc addEdges*[T, R] (graph: var Graph, edges: varargs[Edge[T, R]]) =
  for edge in items(edges):
    let
      node1 = edge.node1
      node2 = edge.node2
      v1 = Vertex[T,R](label: node1, weight: edge.weight)
      v2 = Vertex[T,R](label: node2, weight: edge.weight)
      swappedEdge = Edge[T,R](node1: node2,
        node2: node1, weight: edge.weight)

    if v1 notin graph.vertices:
      graph.vertices.add v1
    if v2 notin graph.vertices:
      graph.vertices.add v2

    if graph.isDirected and edge notin graph.edges:
      graph.edges.add edge
    elif not graph.isDirected and edge notin graph.edges and
        swappedEdge notin graph.edges:
      graph.edges.add edge

proc buildGraph*[T, R](vertices: openArray[Vertex[T, R]] = @[],
    edges: openArray[Edge[T, R]] = @[],
    directed: bool = false, weighted: bool = false): Graph[T, R] =
  result = Graph[T, R](vertices: @vertices, edges: @edges,
    directed: directed, weighted: weighted)
  
  for edge in items(edges):
    let
      v1 = Vertex[T, R](label:edge.node1, weight:edge.weight)
      v2 = Vertex[T, R](label:edge.node2, weight:edge.weight)
    if v1 notin result.vertices:
      result.vertices.add v1
    elif v2 notin result.vertices:
      result.vertices.add v2

proc neighbors*[T, R](graph: Graph, vertex: Vertex[T, R]):
    seq[Vertex[T, R]] =
  result = newSeq[Vertex[T, R]]()
  for edge in graph.edges:
    let
      v1 = Vertex[T, R](label: edge.node1, weight: edge.weight)
      v2 = Vertex[T, R](label: edge.node2, weight: edge.weight)
    if vertex.label == edge.node1 and v2 notin result:
      result.add v2
    elif vertex.label == edge.node2 and v1 notin result:
      result.add v1

proc `$`*(graph: Graph): string =
  result = if graph.isDirected: "Directed "
           else: "Undirected "
  result &= "Graph with "
  result &= $(graph.vertices.len) & " vertices and " &
    $(graph.edges.len) & " edges."
  result &= "\nvertices: " & $(graph.vertices)
  result &= "\nedges: " & $(graph.edges)

proc `$`*(edge: Edge): string =
  $edge.node1 & ":" & $edge.node2 & "@" & $edge.weight

proc indegree*(graph: Graph, vertex: Vertex): int =
  graph.edges.filterIt( it.node2 == vertex.label ).len

proc outdegree*(graph: Graph, vertex: Vertex): int =
  graph.edges.filterIt( it.node1 == vertex.label ).len

proc degree*(graph: Graph, vertex: Vertex): int =
  graph.indegree(vertex) + graph.outdegree(vertex)

proc buildDigraph*[T, R](): Graph =
  buildGraph[T, R](directed = true)

proc newGraph*[T, R](): GraphRef[T, R] =
  GraphRef[T, R](vertices: @[], edges: @[], directed: false)

proc isConnected*[T, R](graph: Graph[T,R]): bool =
  result = true
  for vertex in graph.vertices:
    if (graph.edges.all do (edge: Edge[T, R])->bool: vertex notin edge):
      result = false
      break

proc swapEdge[T,R](edge:Edge[T,R]): Edge[T,R] =
  Edge[T,R](node1: edge.node2, node2: edge.node1, weight: edge.weight)


proc paths*[T,R](graph: Graph[T,R],v1, v2: Vertex[T,R]):
    seq[seq[Vertex[T,R]]] =
  if v1 notin graph.vertices or v2 notin graph.vertices:
    return @[]

  var
    edges = if graph.isDirected: graph.edges
            else: graph.edges.concat(graph.edges.map swapEdge)
    tempresult = newSeq[seq[Vertex[T,R]]]()

  template outFilt (x: untyped): untyped =
    var buff = newseq[Vertex[T,R]]()
    for edge in edges:
      if x.label == edge.node1:
        buff.add initVertex(edge.node2, edge.weight)
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
    var nextstate = newSeq[Vertex[T,R]]()
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

proc shortestPath*[T,R](graph: Graph[T,R], v1, v2: Vertex[T,R]):
    seq[Vertex[T,R]] =
  if v1 notin graph or v2 notin graph:
    return @[]
  let conn = if graph.isDirected: graph.edges
             else: graph.edges.concat(graph.edges.map swapEdge)
  withinTrail:
    dump conn
  var
    visited = newseq[Vertex[T,R]]()
    parent = newTable[Vertex[T,R], Vertex[T,R]]()
    neighbor = initDeque[Vertex[T,R]]()
    connected = false

  template nextVisiting(x: untyped): untyped =
    var next = initHeapQueue[Vertex[T,R]]()
    for edge in conn:
      if x.label == edge.node1:
        let node = initVertex(edge.node2, x.weight + edge.weight)
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

proc shortestPath*[T, R](graph: Graph[T,R], v1, v2: T): seq[Vertex[T,R]] =
  graph.shortestPath(initVertex(v1, 0), initVertex(v2, 0))

proc adjacencyMatrix*[T, R](graph: Graph[T,R]): seq[seq[R]] =
  let
    m = graph.vertices.len
    edges = if graph.isDirected: graph.edges
            else: graph.edges.concat(graph.edges.map swapEdge)
  result = 0.repeat(m).repeat(m)

  for edge in edges:
    let
      i = graph.vertices.find(Vertex[T,R](label:edge.node1,
        weight: edge.weight))
      j = graph.vertices.find(Vertex[T,R](label:edge.node2,
        weight: edge.weight))
    result[i][j] = if graph.isWeighted: edge.weight
                   else: 1

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

proc deleteVertex*[T,R](graph: var Graph[T,R], vertex: Vertex[T,R]):
    bool =
  let pos = graph.vertices.find(vertex)
  if pos >= 0:
    graph.vertices.delete(pos)
    graph.edges.keepIf(proc(e: Edge[T,R]): bool =
      e.node1 != vertex.label and e.node2 != vertex.label
    )

    true
  else:
    false

proc deleteEdge*[T, R](graph: var Graph[T,R], edge: Edge[T,R]): bool =
  let pos = graph.edges.find(edge)
  if pos >= 0:
    graph.edges.delete(pos, pos)
    true
  else:
    false

type PriorityNode[T, R] = object
  node: Vertex[T, R]
  cost: R
proc `<`*[T, R](p1, p2: PriorityNode[T, R]): bool = p1.cost < p2.cost

proc `a*`*[T, R](graph: var Graph[T, R], v1, v2: T): seq[Vertex[T, R]] =
  ## A* search based on its start (v1) label (v2) to end.
  ## Users need to provide accessible `proc cost(v1, v2: T): R` and
  ## `proc distance(v1, v2: T): R` with T and R are matched with Graph[T, R].
  ## In rare case users could also need to provide operator "+" and "<" for T
  ## that returns R viz ```proc `+`(cost1, cost2: R): R``` and
  ## ```proc `<`(cost1, cost2: R): bool```.
  when not compiles(cost(v1, v2)):
    {.error: "`proc cost[T, R](v1, v2: T): R` is not defined".}

  when not compiles(distance(v1, v2)):
    {.error: "`proc distance[T, R](v1, v2: T): R` is not defined".}

  let
    start = Vertex[T, R](label: v1)
    goal = Vertex[T, R](label: v2)

  var
    costSoFar = initTable[Vertex[T, R], R]()
    visited = initTable[Vertex[T, R], Vertex[T, R]]()
    visiting = initHeapQueue[PriorityNode[T, R]]()
    thecost: R

  costSoFar[start] = thecost
  visited[start] = start
  visiting.push(PriorityNode[T, R](node: start, cost: thecost))
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
        visiting.push(PriorityNode[T, R](node: nextnode, cost: priority))
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
  var graph = buildGraph[char, int]()
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
  graph.addEdges(Edge[char,int](node1:'a', node2:'b', weight:0),
    Edge[char, int](node1:'b', node2:'c', weight:0),
    Edge[char, int](node1:'c', node2:'d', weight:0))

  proc makeEdge[T](conns: varargs[tuple[n1, n2: T]]): seq[Edge[T, int]] =
    result = newSeq[Edge[T, int]]()
    for edge in conns:
      result.add Edge[T, int](node1: edge.n1, node2: edge.n2, weight: 0)
  #[
  echo "degree a: ", graph.degree('a'), ": ", graph.neighbors('a')
  echo "degree b: ", graph.degree('b'), ": ", graph.neighbors('b')
  echo "degree c: ", graph.degree('c'), ": ", graph.neighbors('c')
  ]#
  graph.addEdges(makeEdge[char](('d', 'f'), ('b', 'e'), ('e', 'f'),
    ('f', 'g'), ('g', 'b'), ('a', 'e'), ('c', 'e')))
  echo "degree a: ", graph.degree(Vertex[char, int](label:'a',
    weight: 0)), ": ",
    graph.neighbors(Vertex[char, int](label: 'a', weight: 0))
  echo "degree b: ", graph.degree(Vertex[char, int](label:'b',
    weight: 0)), ": ",
    graph.neighbors(Vertex[char, int](label: 'b', weight: 0))
  echo "degree c: ", graph.degree(Vertex[char, int](label:'c',
    weight: 0)), ": ",
    graph.neighbors(Vertex[char, int](label: 'c', weight: 0))
  echo if graph.isConnected: "graph is connected"
       else: "graph is disconnected"
  echo graph.paths(Vertex[char,int](label:'g', weight:0),
    Vertex[char,int](label:'d', weight:0)).join("\n")
  #echo graph.paths('a', 'd')
  echo "shortest path: ", graph.shortestPath(
    Vertex[char,int](label:'g', weight:0),
    Vertex[char,int](label:'d', weight:0))
  echo "shortest path2: ", graph.shortestPath('g', 'd')
  echo "adjacency matrix:"
  for adj in graph.adjacencyMatrix():
    echo adj

  func cost(v1, v2: char): int = 1
  func distance(v1, v2: char): int = 0

  echo "A*: ", graph.`a*`('g', 'd')
  let g = Vertex[char,int](label:'g', weight:0)
  if graph.deleteVertex(g):
    echo "Vertex ", g, " is deleted"
    echo "now graph is ", graph

  #[
  var gr = buildGraph[int]()
  gr.directed = true
  gr.addVertices(0, 1, 2, 3, 4)
  gr.addEdges((0, 1), (0, 2), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3),
    (2, 4))
  echo gr
  echo "incidence matrix 2:"
  for adj in gr.incidenceMatrix():
    echo adj
  ]#
