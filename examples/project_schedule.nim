## This example is showing how to solve a days taken from list of
## activities. The activities we use is sequence of building home.
## This example is taken from [ref: page 14](combinoptim).
## 
## In this example, we define two kinds of object. `Activity` itself and
## `Day`. `Activity` is kind of work with its total time (`timeNeeded`) and
## with the rest of time to finish this activity (`restOfTime`).
## 
## `Day` object acts as state for each transition which witholding the
## activities being worked on (field `working`) and which activity ids
## that has been done (field `done`). The day also indicate what is its current
## day worked on (field `pevDayCount`) with next day some work will be
## completed at (field `nextDayCount`).
## 
## We also calculate the each work prequisites (`workPrequisites`) to
## correctly add a new work after its prequisites already done.
## Hence we define function `subsetOf` whether the prequisites work ids
## in `done` field for each day.
## 
## For each day we reached the work done, we get the days working
## from current to next day (`diffdays`).
## We check each activity being worked on and see if it's reaching done
## status by sub it with previous day (`work.restOfTime - diffdays == 0`).
## If it's work that's done, we then check the next works from `requiredFor`
## and check whether the next work prequisites already done
## (`workPrequisites[nextwork.id].subsetOf(nextday.done)`).
## If it's not done yet, we re-add the current work and update its restOfTime
## with days it's been worked on (`act.restOfTime -= diffdays`).
## 
## Finally, if nothing are being worked on, we give the final day as
## next node to visit. We need to like this to complete the round trip
## from start to finish to get the traversed path record. Without this,
## we will get empty path due to no connectivity between start to finish.
## 
## combinoptim: https://homepages.cwi.nl/~lex/files/dict.pdf
## 
import std/[hashes, sugar, sequtils]
import graflib

type
    ActivityId = Natural
    Activity = object
        id: ActivityId
        name: string
        timeNeeded: Natural
        restOfTime: Natural
        requiredFor: seq[ActivityId]
    Day = object
        prevDayCount: Natural
        nextDayCount: Natural
        working: seq[Activity]
        done: seq[ActivityId]

func hash(d: Day): Hash =
    var h: Hash = 0
    h = h !& hash(d.prevDayCount)
    h = h !& hash(d.nextDayCount)
    result = !$h

template withTrail(body: untyped) =
    when defined(trail):
        body

const
    start = Activity(id: 0, name: "start", timeNeeded: 0,
        requiredFor: @[ActivityId 1])
    finish = Activity(id: 15, name: "finish", timeNeeded: 0)
    buildingHome = [
        start,
        Activity(id: 1, name: "groundwork", timeNeeded: 2, restOfTime: 2,
            requiredFor: @[ActivityId 2]),
        Activity(id: 2, name: "foundation", timeNeeded: 4, restOfTime: 4,
            requiredFor: @[ActivityId 3]),
        Activity(id: 3, name: "building walls", timeNeeded: 10, restOfTime: 10,
            requiredFor: @[ActivityId 4, 6, 7]),
        Activity(id: 4, name: "exterior plumbing", timeNeeded: 4, restOfTime: 4,
            requiredFor: @[ActivityId 5, 9]),
        Activity(id: 5, name: "interior plumbing", timeNeeded: 5, restOfTime: 5,
            requiredFor: @[ActivityId 10]),
        Activity(id: 6, name: "electricity", timeNeeded: 7, restOfTime: 7,
            requiredFor: @[ActivityId 10]),
        Activity(id: 7, name: "roof", timeNeeded: 6, restOfTime: 6,
            requiredFor: @[ActivityId 8]),
        Activity(id: 8, name: "finishing off outer walls", timeNeeded: 7, restOfTime: 7,
            requiredFor: @[ActivityId 9]),
        Activity(id: 9, name: "exterior painting", timeNeeded: 9, restOfTime: 9,
            requiredFor: @[ActivityId 14]),
        Activity(id: 10, name: "panelling", timeNeeded: 8, restOfTime: 8,
            requiredFor: @[ActivityId 11, 12]),
        Activity(id: 11, name: "floors", timeNeeded: 4, restOfTime: 4,
            requiredFor: @[ActivityId 13]),
        Activity(id: 12, name: "interior painting", timeNeeded: 5, restOfTime: 5,
            requiredFor: @[ActivityId 13]),
        Activity(id: 13, name: "finishing off interior", timeNeeded: 6, restOfTime: 6),
        Activity(id: 14, name: "finishing off exterior", timeNeeded: 2, restOfTime: 2),
        finish,
    ]
    allfinished = buildingHome[0 .. ^2].mapIt it.id
    workPrequisites = block:
        var preq = newseq[seq[ActivityId]](buildingHome.len)
        for b in buildingHome:
            for id in b.requiredFor:
                preq[id].add(b.id)
        preq
    startingDay = Day(prevDayCount: 0, working: @[start])
    finishedDay = Day(done: allfinished)

withTrail: dump workPrequisites

func subsetOf(set1, set2: seq[ActivityId]): bool =
    for s1 in set1:
        if s1 notin set2: return false
    true

func cost(d1, d2: Day): int = 0
func distance(d1, d2: Day): int = 0

proc next(day: Day; edges: seq[Edge[Day]]): seq[Day] =
    withTrail: dump day
    var nextday: Day
    nextday.done = day.done
    nextday.prevDayCount = day.nextDayCount
    let diffday = abs(day.nextDayCount - day.prevDayCount)
    for idwork in day.working:
        var act = idwork
        if abs(act.restOfTime - diffday) == 0:
            nextday.done.add act.id
            for nextwork in act.requiredFor:
                var nextact = buildingHome[nextwork]
                if workPrequisites[nextact.id].subsetOf(nextday.done):
                    nextday.working.add nextact
        else:
            act.restOfTime -= diffday
            nextday.working.add act
    if nextday.working.len > 0:
        let nextminday = min(nextday.working.mapIt(it.restOfTime))
        nextday.nextDayCount = nextday.prevDayCount + nextminday
        @[nextday]
    else:
        @[finishedDay]

proc main =
    var
        g = buildGraph[Day](directed = true)
    let buildingActivities = `a*`[Day, int](g, startingDay, finishedDay)
    withTrail: dump buildingActivities
    var totaldays = 0
    for build in buildingActivities:
        let day = build.prevDayCount
        if build.working.len > 0:
            dump day
            echo "working on"
            for work in build.working:
                dump work
        else:
            echo "day = ", totaldays
            echo "project done!"
        if build.nextDayCount != 0:
            totaldays = build.nextDayCount
    if buildingActivities.len > 1:
        echo "sequence of finished works: ",
            buildingActivities[^2].done & buildingActivities[^2].working[0].id
    dump totaldays

main()