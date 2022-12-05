## This example we show for searching the task assignment
## configuration using permutations we defined in `permutations.nim`.
##
## While this example is included in this particular case,
## in actuality we search all possible configuration with permutations.
## So we indirectly use the graph searching method in permutations.
##
## Since we search the permutation, this solution is complete at cost
## of increased search time due to searching all possible solutions.
## Note that there's a method for better and efficient like [0] but
## we show here for the sake of example of using graph (albeit indirectly).
## 
## In this example, we define the `Task` as representative of
## index in each row of cost. Each row is representative of
## each worker so in the `workersCost` the row 1 (index 0) means
## worker 1 while each column in rows represents cost of each task
## for that particular worker/row i.e. workersCost[0][1] is 80 means
## the cost of worker 1 (row 0) for task 2 (col 1) is 80.
## 
## 0: Hungarian method/algorithm: https://en.wikipedia.org/wiki/Hungarian_algorithm

from std/sequtils import toSeq
from std/strformat import fmt
from ./permutations import permut

const workersCost = [
    [90, 80, 75, 70],
    [35, 85, 55, 65],
    [125, 95, 90, 95],
    [45, 110, 95, 115],
    [50, 100, 90, 100],
]

type Task = range[-1 .. workersCost.high-1] # -1 means unallocated

proc main =
    var
        mincost = int.high
        config: seq[Task]
    for taskAssignment in permut(toSeq(Task.low .. Task.high)):
        var curr = 0
        for worker, costid in taskAssignment:
            if costid == -1: continue
            curr += workersCost[worker][costid]
        if curr < mincost:
            mincost = curr
            config = taskAssignment
    echo "assignment with least cost: ", config
    for i, task in config:
        if task == -1:
            echo fmt"worker {i+1} not assigned any work"
        else:
            echo fmt"worker {i+1} assigned to task {task+1} " &
                 fmt"with cost: {workersCost[i][task]}"


main()