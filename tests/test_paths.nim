import std/unittest
from std/strutils import splitLines, split, isUpperAscii
from std/sequtils import all

import graflib

## This test is also example of looking for available paths in
## given input maps.
## This inputs map is from Advent of Code 2021 Day 12.
## We also illustrate that some node can be visited once more
## by defining the `isCycle` func.

let inputs = [
"""
start-A
start-b
A-c
A-b
b-d
A-end
b-end
""",
"""
dc-end
HN-start
start-kj
dc-start
dc-HN
LN-dc
HN-end
kj-sa
kj-HN
kj-dc
""",
"""
fs-end
he-DX
fs-he
start-DX
pj-DX
end-zg
zg-sl
zg-pj
pj-he
RW-he
fs-DX
pj-RW
zg-RW
start-pj
he-WI
zg-he
pj-fs
start-RW
""",
]

let graphs = block:
    var r = newseq[Graph[string]](inputs.len)
    for i, input in inputs:
        r[i] = buildGraph[string]()
        for line in input.splitLines:
            let nodes = line.split("-", maxsplit = 2)
            if nodes.len >= 2:
                r[i].addEdges(Edge[string](node1: nodes[0], node2: nodes[1]))
    r

func isCycle(s: string): bool = s.all isUpperAscii

test "Graph paths":
    let
        expectedPaths = [10, 19, 226]
        start = "start"
        `end` = "end"
    for i, g in graphs:
        let paths = g.paths(start, `end`)
        check expectedPaths[i] == paths.len