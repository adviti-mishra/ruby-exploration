# Thoughts based on proof of concept 

## Things to figure out: 
Currently, the callbacks are registered in the order in which the user registers them. 
However, we need to: 
1. Get the persistance operation the user is performing (eg: create)
2. Figure out an ordering of the sub-operations for the persistance operation (eg: validate, save, create)
3. Register callbacks for this instance based on the sub-operations

## 1st proof of concept: <br />
recurse once to collect all callbacks 

## 2nd proof of concept: <br />

1st recursive function: <br/>

1. execute begin callbacks (stack-frame for begin created, executed immediately, and popped)
2. create around fiber and resume (runs until yield) (no stack-frame created)

2nd recursive function: <br/>

1. resume around fiber (runs after yield) (no stack-frame created)
2. execute after callbacks (stack-frame for after created, executed immediately, and popped)

Difference: <br/>
1st proof of concept: <br/>
 [before for root, around for root, after for root, before for child1, around for child1, after for child1, ...]
No. of fibers: 3x
Number of traversals: 
1st: recursive DFS
2nd: iterative

2nd proof of concept: 
callbacks: []
No. of fibers: x
N

| Criteria | 1st proof of concept | 2nd proof of concept |
|----------|----------------------|----------------------|
| Traversal #1| recursive DFS | recursive DFS|
| Traversal #2 | iterative | recursive DFS | 
| No. of fibers | 3x | 3|
| callbacks | class-variable [before for root, around for root, after for root, before for child1, around for child1, after for child1, ...] | for each instance, store fibers for around callbacks and execute in reverse order