## Example of getting the permutation based on available
## search paths.
## By defining the `nmax` variable during compilation,
## we can observe the permutations for various N integers
## by default it's 3.  We can also observe with two others
## openArray that we want to see its permutation.

import graflib

iterator permut*[T](arr: openArray[T]): seq[T] =
    var g = buildGraph[T]()
    for a in arr:
        for b in arr:
            g.addEdges (a, b)
    for a in arr:
        for b in arr:
            for p in g.paths(a, b):
                if p.len != arr.len: continue
                yield p

when isMainModule:
    const nmax {.intdefine.}: int = 3

    when nmax <= 0:
        import std/strformat
        {.error: &"error nmax is not positive, provided {nmax}".}

    import std/[sugar, sequtils]
    for cc in permut(@['a', 'b', 'c']):
        dump cc

    for ss in permut(["field1", "field2", "field3"]):
        dump ss

    for ii in permut(toSeq(1 .. nmax)):
        dump ii