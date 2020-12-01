import csv
import pandas as pd
# win中复制的路径是
filename = r'F:/AsCoder/Flask_test/FlaskPlay/TheNewYorkCity/AB_NYC_2019.csv/AB_NYC_2019.csv'
   
# 默认为gbk的话，这里需要指定转码方式
# with open(filename,encoding = 'UTF-8') as datafile:
#     reader = csv.reader(datafile)
#     # print(reader.)
#     print(list(reader))

df_tb = pd.read_csv(filename)
shop_top10 = df_tb.groupby('neighbourhood_group')['number_of_reviews'].sum().sort_values(ascending=False).head(3)

print(shop_top10)
