"""import gevent
def f1():
    for i in range(2):
        print('run func:f1,index:%s '% i)
        gevent.sleep(0)
def f2():
    for i in range(2):
        print('run func:f2,index:%s '% i)

t1 = gevent.spawn(f1)
t2 = gevent.spawn(f2)
gevent.joinall(t1,t2)
"""
a=1>0
b = 1<0
c=1>0
print(a and not b or c )
print(a and ((not b ) or c))
print(a and  (not b) ) or c