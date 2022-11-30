## This is classic example of knapsack problem and solving it
## with graph search.
## In this example we use `Item` as state of changes between
## nodes with `currentWeight` and `currentValue` is cumulative
## from previous nodes.
## 
## The current solution is quite unstable considering how the cost
## and distance defined.
## For example in first case, we have default capacity of 50, and we
## want to pack three different items kind which that's `items`.
## The first case is correctly yield the result:
## 
##  - nothing (starter, not item)
##  - health-kit: w=20, v=100
##  - health-kit: w=20, v=100
##  - ransom: w=10, v=30
##  - full (finisher, not item)
## 
## This configuration will yield optimum solution of total weight 50,
## within capacity 50 and total value 230. No other configuration
## will yield better total value than this.
## 
## But as soon we change the item ransom value to 60, we'll get:
## 
##  - nothing (starter, not item)
##  - health-kit: w=20, v=100
##  - ransom: w=10, v=60
##  - ransom: w=10, v=60
##  - ransom: w=10, v=60
##  - full (finisher, not item)
## 
## That's total weight is 50 too and total value become 280.
## Note that this is suboptimum. The optimum configuration is:
## 
##  - nothing (starter, not item)
##  - ransom: w=10, v=60
##  - ransom: w=10, v=60
##  - ransom: w=10, v=60
##  - ransom: w=10, v=60
##  - ransom: w=10, v=60
##  - full (finisher, not item)
## 
## This will yield total value 300 but our current cost and distance
## definition will only yield 280.
## 
## From this we can say the optimum solution will be depend on how
## the cost and distance defined. In current cost solution, we simply
## minimize the weight (+weight) and maximize the value (-value) of item.
## Hence we define it as `item2.weight + -item2.value`.
## 
## This example also provide 2 different capacity case, first is 50
## which is the default that can be changed during compliation and
## the second is 60 hardcoded.
## In the second case, we also have suboptimal solution when the ransom
## value changed from 30 to 60. Our solution yields total value 340
## while the optimum solution should yield total value 360.
## 
## The distance itself we prioritized the path that has current maximum
## total values.
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
        currentValue: Natural
        weight: Natural
        value: Natural

func hash(item: Item): Hash =
    var h: Hash = 0
    h = h !& hash(item.name)
    h = h !& hash(item.weight)
    h = h !& hash(item.value)
    h = h !& hash(item.currentWeight)
    h = h !& hash(item.currentValue)
    h = h !& hash(item.capacity)
    result = !$h

var items = @[
    Item(name: "ransom", weight: 10, value: 30, capacity: capacity),
    Item(name: "health-kit", weight: 20, value: 100, capacity: capacity),
    Item(name: "elixir", weight: 30, value: 120, capacity: capacity),
]

proc cost(i1, i2: Item): int = i2.weight - i2.value
func distance(i1, i2: Item): int = -i1.currentValue

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
        newitem.currentValue = item.currentValue + newitem.value
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