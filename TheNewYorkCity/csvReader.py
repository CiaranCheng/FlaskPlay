import csv
import pandas as pd
# from pyecharts import Bar,Map,options
# win中复制的路径是
filename = r'F:/AsCoder/Flask_test/FlaskPlay/TheNewYorkCity/AB_NYC_2019.csv/AB_NYC_2019.csv'
   
# 默认为gbk的话，这里需要指定转码方式
# with open(filename,encoding = 'UTF-8') as datafile:
#     reader = csv.reader(datafile)
#     # print(reader.)
#     print(list(reader))



# 返回的是dataframe格式
df_tb = pd.read_csv(filename)
shop_top10 = df_tb.groupby('neighbourhood_group')['number_of_reviews'].sum().sort_values(ascending=False).head(3)

province_num = df_tb.groupby('province')['purchase_num'].sum().sort_values(ascending=False)

print(df_tb.info)

# dataframe如何取值 df_tb[""]返回的是？



# ru
# map1 = Map()
# map1.add("",[list(z) for z in zip(province_num.index.tolist(),province_num.values.tolist())],
#        maptype='china')
# map1.set_global_opts(
#     title_opts = opts.TitleOpts(title='国内各产地乐高销量分布图'),
#     visualmap_opts = opts.VisualMapOpts(max_=172277)
# )
# map1.render_notebook()
