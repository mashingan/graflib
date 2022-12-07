## Example of solving puzzle of SEND+MORE=MONEY
## which each alphabet is a number.
## The constraint is S and M is not 0 and all alphabets
## are unique each others.
## In this example, we search all combinations of possible
## configuration using its permutations.
## We use (indirectly) the `paths` function provided in
## `permutations.permut` iterator.
when defined(from0):
    from std/sequtils import toSeq
from std/times import cpuTime
from ./permutations import permut

const
    sendmory = ['S', 'E', 'N', 'D', 'M', 'O', 'R', 'Y']
    spos = sendmory.find('S')
    epos = sendmory.find('E')
    npos = sendmory.find('N')
    dpos = sendmory.find('D')
    mpos = sendmory.find('M')
    opos = sendmory.find('O')
    rpos = sendmory.find('R')
    ypos = sendmory.find('Y')

proc checks(cfg: sink seq[int]): bool =
    template check(test: untyped) =
        result = result and (`test`)
        if not result: return false
    result = true
    check cfg[spos] != 0 and cfg[mpos] != 0
    let send = cfg[spos]*1_000 + cfg[epos]*100 + cfg[npos]*10 + cfg[dpos]
    let more = cfg[mpos]*1_000 + cfg[opos]*100 + cfg[rpos]*10 + cfg[epos]
    let money = cfg[mpos]*10_000 + cfg[opos]*1_000 + cfg[npos]*100 + cfg[epos]*10 + cfg[ypos]
    check (send + more) == money

proc main =
    # we're cheating by searching from 9 instead of 0
    # to avoid searching too long if searching from 0
    # (~4-5 seconds on my machine).
    # To check the slow search, add option: `-d:from0`
    # when compiling.
    when not defined(from0):
        let vals = [9,8,7,6,5,4,3,2,1,0]
    else:
        let vals = toSeq(0..9)

    var cfg: seq[int]
    let start = cpuTime()
    for config in permut(vals, sendmory.len):
        if config[spos] == 0 or config[mpos] == 0: continue
        if checks(config):
            cfg = config
            break

    echo "the configuration is:"
    for i, c in sendmory:
        echo c, ": ", cfg[i]
    echo "program elapsed: ", cpuTime() - start, " seconds"

main()