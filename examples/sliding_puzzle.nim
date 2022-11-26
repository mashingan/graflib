import std/[sugar, sequtils, strutils, strformat]
when not defined(fixedInitials):
    import std/random
import graflib

## This is example of solving [sliding puzzle](https://en.wikipedia.org/wiki/Sliding_puzzle)
## by searching its state-space using A*.
## In this example we have by default wideN = 3 which the width of puzzle and
## total tile 6, which the target tile is 1 .. 5 and 0 as empty tile.
## Both wideN and total can be overriden during the compilation with options e.g.
## `-d:wideN=2` and `-d:total=5`.
## 
## For initial puzzle, by default it's generating a random position to be lined
## to its target position, for example we have this initial arrangement
## 
## ```
## 3, 0, 5
## 1, 4, 2
## ```
## 
## to be arranged to
## 
## ```
## 1, 2, 3
## 4, 5, 0
## ```
## 
## (note reminder: 0 is empty tile). The states solutions are below
## 
## ```
## slide = 
## 3, 0, 5
## 1, 4, 2

## slide = 
## 0, 3, 5
## 1, 4, 2

## slide = 
## 1, 3, 5
## 0, 4, 2

## slide = 
## 1, 3, 5
## 4, 0, 2

## slide = 
## 1, 3, 5
## 4, 2, 0

## slide = 
## 1, 3, 0
## 4, 2, 5

## slide = 
## 1, 0, 3
## 4, 2, 5

## slide = 
## 1, 2, 3
## 4, 0, 5

## slide = 
## 1, 2, 3
## 4, 5, 0
## ```
## 
## with `slide =` shows as each state progress from previous.
## Observe the changes of empty tile (0) movement.
## 
## For worked initials that has solution, we can compile with option `-d:fixedInitials`
## to see how the slides progressions for different initials.
## Note that for fixed initials, it's only work for wideN 3 and total 6,
## other than those setting, it will compile error.
## For randomized initial, there's possibility for unsolvable puzzle hence
## fixed initials solution option is provided.

const
    wideN {.intdefine.}: int = 3
    total {.intdefine.}: int = 6
    maxheight = when total mod wideN != 0: (total div wideN) + 1
                else: total div wideN

dump wideN
dump total
dump maxheight
type
    WideR = range[1 .. wideN]
    Slides = range[1 .. total]
    Tile = range[0 .. total-1]
    Pos = array[Slides, Tile]

template divmod(a: int): (int, int) =
    let adiv = a div wideN
    let amod = a mod wideN
    let r1 = if adiv == 0: WideR.low.int
             elif a == Slides.high: maxheight
             elif amod == 0: adiv
             else: adiv + 1
    let r2 = if amod == 0: WideR.high
             else: a mod wideN
    (r1, r2)

template withinTrail(body: untyped) =
    when defined(trail):
        `body`

template toPos(rowcol: (int, int)): int =
    let r = (rowcol[0]-1) * wideN + (if rowcol[1] == 0: wideN else: rowcol[1])
    r
func cost(p1, p2: Pos): int = 1
func distance(p1, p2: Pos): int =
    for i, n in p2:
        let (n11, n12) = divmod p1[i]
        let (n21, n22) = divmod n
        result += abs(n11 - n21) + abs(n12 - n22)

proc `$`(p: Pos): string =
    var dist = (@p).distribute(maxheight, spread = false)
    result = '\n' & dist.map(arr => arr.mapIt(fmt"{it:>2}").join(", ")).join("\n") & '\n'

var count = 0
proc next(p: Pos; edges: seq[Edge[Pos]]): seq[Pos] =
    withinTrail: echo "currp: ", p
    inc count
    if count >= 1_000_000: return @[]
    var idx = -1
    for i, n in p:
        if n == 0:
            idx = i
            break
    if idx == -1:
        return @[]
    let (row, col) = divmod idx
    withinTrail:
        dump idx
        dump (row, col)
    template addresult(rowcol: (int, int)) =
        let newidx = rowcol.toPos
        # dump newidx
        if newidx <= Slides.high:
            var newp = p
            newp[idx].swap newp[newidx]
            result.add newp
    if col - 1 >= WideR.low:
        addresult (row, col-1)
    if col + 1 <= WideR.high:
        addresult (row, col+1)
    if row - 1  >= WideR.low:
        addresult (row-1, col)
    if row + 1 <= maxheight:
        addresult (row+1, col)

when defined(fixedInitials):
    when wideN != 3 or total != 6:
        {.error: " fixedInitials can only work for puzzle wide 3 and total tile 6, i.e. from tile 1 to 5, with 0 as empty tile.".}
    var start: seq[Pos] = @[
        [Tile 4, 3, 0, 1, 5, 2],
        [Tile 3, 4, 1, 0, 2, 5],
        [Tile 5, 3, 1, 2, 4, 0],
        [Tile 3, 5, 1, 4, 2, 0],
    ]
else:
    randomize()
    var startnum = toSeq(0..total-1)
    shuffle startnum
    withinTrail: dump startnum
    var start: seq[Pos] = newseq[Pos](1)
    for s in start.mitems:
        for i in Pos.low .. Pos.high:
            s[i] = startnum[i-1]

proc main =
    var `end`: Pos
    for i in Slides.low .. Slides.high-1:
        `end`[i] = i
    `end`[^1] = 0
    dump `end`
    var slides = buildGraph[Pos](directed = true)
    echo "==========="
    for initial in start:
        dump initial
        for slide in `a*`[Pos, int](slides, initial, `end`):
            dump slide
        echo "==========="
    dump count

main()