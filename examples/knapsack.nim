## This is classic example of knapsack problem and solving it
## with graph search.
## In this example we use `Item` as state of changes between
## nodes with `currentWeight` is cumulative from previous nodes.
## 
## The formula that we want to maximize is the value per weight.
## The bigger the ratio the better. Since the priority node is
## emphasizing which has lower priority number, so we maximize
## it by multiplying it with -1.
## 
## This example also provide 2 different capacity case, first is 50
## which is the default that can be changed during compliation and
## the second is 60 hardcoded.
## 
from std/sugar import dump
from std/sequtils import allIt, foldl
from std/hashes import `!&`, Hash, hash, `!$`
from graflib import Edge, buildGraph, `a*`, `<`

const capacity {.intdefine.}: Natural = 50

type
    Item = object
        name: string
        capacity: Natural
        currentWeight: Natural
        weight: Natural
        value: Natural

func hash(item: Item): Hash =
    var h: Hash = 0
    h = h !& hash(item.name)
    h = h !& hash(item.weight)
    h = h !& hash(item.value)
    h = h !& hash(item.currentWeight)
    h = h !& hash(item.capacity)
    result = !$h

var items = @[
    Item(name: "ransom", weight: 10, value: 30, capacity: capacity),
    Item(name: "health-kit", weight: 20, value: 100, capacity: capacity),
    Item(name: "elixir", weight: 30, value: 120, capacity: capacity),
]

func cost(i1, i2: Item): int = -(i2.value div i2.weight)
func distance(i1, i2: Item): int = 0

template withtrail(body: untyped) =
    when defined(trail):
        `body`

proc next(item: Item; edges: seq[Edge[Item]]): seq[Item] =
    withTrail: dump item
    for inv in items:
        withTrail: dump inv
        if item.currentWeight + inv.weight > item.capacity:
            continue
        var newitem = inv
        newitem.currentWeight = item.currentWeight + newitem.weight
        withTrail: dump newitem
        result.add newitem
    if result.len == 0:
        result.add Item(name: "full", weight: item.capacity, value: 0)
    withTrail: dump result


proc main =
    var
        g = buildGraph[Item]()
        empty = Item(name: "nothing", weight: 0, value: 0, capacity: capacity)
        full = Item(name: "full", weight: capacity)
    dump items
    dump full.weight
    var packs = `a*`[Item, int](g, empty, full)
    dump packs
    dump packs.foldl(a + b.value, 0)

    let newcap = 60
    for item in items.mitems:
        item.capacity = newcap
    empty.capacity = newcap
    full.weight = newcap
    dump full.weight
    packs = `a*`[Item, int](g, empty, full)
    dump packs
    dump packs.foldl(a + b.value, 0)

main()