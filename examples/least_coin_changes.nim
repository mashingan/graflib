# In this example we illustrate the classic puzzle of least coins for changes.
# Using the initValue that can be defined during the compile time, with option
# `-d:initValue=N` with N is the value that we want to check.
# The default initValue is 150_00.
#
# We're using the least nomimal in Cent hence a Dollar is 100 and 100 Dollars,
# a Buck, is 100_00. So above default value is one hundred and fifty dollars.
#
# This illustration checking optimum (or minimum) coins for changes using
# shrinking search-space for each visit of coin changes. The bigger the coin
# nominal is getting more prioritized.
#
# This example we describe the path is state of changes, hence we have the
# current value and the coin to get that value.
# For start and end of changes, we omit the Coin altogether, casted to int will
# yield 0 as invalid data but since we don't compare its coin, we compare the
# current value only. Hence in the hash and `==` we only hash and compare the
# current value of state changes.
import std/[sugar, hashes, tables]
import graflib

const initValue {.intdefine.}: int = 150_00

type
    Coin = enum
        Cent = 1
        Pound = 5
        Dime = 10
        Dollar = 1_00
        Buck = 100_00
    
    Changes = object
        currentValue: int
        coin: Coin

const coins = [Cent, Pound, Dime, Dollar, Buck]

func hash(c: Changes): Hash =
  !$hash(c.currentValue)

func `==`(c1, c2: Changes): bool =
    c1.currentValue == c2.currentValue
func distance(c1, c2: Changes): int = 1
func cost(c1, c2: Changes): int = c1.currentValue - int(c2.coin)

template withTrail(body: untyped) =
    when defined(trail):
        `body`

proc next(changes: Changes, edges: seq[Edge[Changes]]): seq[Changes] =
    withTrail: dump changes

    for coin in coins:
        # dump coin
        if changes.currentValue - int(coin) < 0: continue
        let c = Changes(currentValue: changes.currentValue - int(coin), coin: coin)
        result.add c
    withTrail: dump result

proc main =
    var g = buildGraph[Changes]()
    let
        start = Changes(currentValue: initValue)
        finish = Changes(currentValue: 0)
    let changes = `a*`[Changes, int](g, start, finish)
    var coinsChange: seq[Coin]
    var sum = 0
    for change in changes:
        if int(change.coin) == 0: continue
        coinsChange.add change.coin
        sum += int change.coin
    for coin in coins:
        if abs(sum + int(coin)) == initValue:
            coinsChange.add coin
            break
    dump coinsChange.toCountTable

main()