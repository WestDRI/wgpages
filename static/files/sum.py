from time import time
import argparse
import concurrent.futures

parser = argparse.ArgumentParser()
parser.add_argument('--n', default=100_000_000, type=int, help='number of terms')
parser.add_argument('--ntasks', default=1, type=int, help='number of tasks')
args = parser.parse_args()
n, ntasks = args.n, args.ntasks

def slow(interval):
    total = 0
    for i in range(interval[0], interval[1]+1):
        if not "9" in str(i):
            total += 1.0 / i
    return total

size = n//ntasks   # size of each batch
intervals = [(i*size+1,(i+1)*size) for i in range(ntasks)]
if n > intervals[-1][1]: intervals[-1] = (intervals[-1][0], n)   # add the remainder, if any

print("running with", args.ntasks, "threads over", intervals)
start = time()
with concurrent.futures.ThreadPoolExecutor() as pool:
    results = pool.map(slow, intervals)

end = time()
print("Time in seconds:", round(end-start,3))
print("sum =", sum(r for r in results))
