import pymssql

class dbUtils:
    @staticmethod
    def conn():
        connect = pymssql.connect('(local)', 'lc0049999', 'cwpass12!', 'cwbase4') #服务器名,账户,密码,数据库名
        if connect:
            print("连接成功!")
        return connect
    @staticmethod
    def sel():
        connect = pymssql.connect('(local)', 'lc0049999', 'cwpass12!', 'cwbase4')  #建立连接
        if connect:
            print("连接成功!")
            
        cursor = connect.cursor()   #创建一个游标对象,python里的sql语句都要通过cursor来执行
        sql = "select top 10 LSWLZD_WLBH, LSWLZD_WLMC from LSWLZD"
        cursor.execute(sql)   #执行sql语句
        row = cursor.fetchone()  #读取查询结果,
        while row:              #循环读取所有结果
            print("Name=%s, Sex=%s" % (row[0],row[1]))   # 输出结果
            row = cursor.fetchone()
        cursor.close()   
        connect.close()
        return connect
# if __name__ == '__main__':
#     # conn = conn()
#     sel = sel()