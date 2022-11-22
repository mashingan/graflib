# Graflib
This is minimal implementation of graph library. Using generic for labelling
and for adding a weight type.  
Hopefully this can be expanded to more generic graph implementation.

The current implementation is able to

1. Make graph undirected.
2. Find nodes' neighbours within defined mapping.
3. Find the paths between origin node to destination node using DFS.
4. Find the shortest path between origin node to destination node using `A*`.

Available examples are provided in folder [examples](./examples).

## Note for A* searching

User must provide the proc that has signature
`proc cost[N, C](n1, n2: N): C` and `proc distance[N, C](n1, n2: N): C`
with `N` is the node type and `C` is the cost type.
The cost type has to support `<` and `+` operator to make `A*` search to work.  
See the [tests/test_astar.nim](tests/test_astar.nim) for the example
to see how it works.

## Installation

Minimum supported Nim version `1.6.0` in order to run the test.

```
$ nimble install https://github.com/mashingan/graflib
```

## doc
[Documentation](https://mashingan.github.io/graflib/htmldocs/graflib.html)

### License
MIT