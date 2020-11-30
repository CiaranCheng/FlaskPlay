from pyecharts import Bar 
bar = Bar()
bar.add("1",["衬衫", "羊毛衫", "雪纺衫", "裤子", "高跟鞋", "袜子"],[5, 20, 36, 10, 75, 90])

# render 会生成本地 HTML 文件，默认会在当前目录生成 render.html 文件
# 也可以传入路径参数，如 bar.render("mycharts.html")
bar.render("mychart.html")
# print(pyecharts.__version__)
# bar = Bar("此处为标题")
# bar.add_xaxis(["衬衫", "羊毛衫", "雪纺衫", "裤子", "高跟鞋", "袜子"])
# bar.add_yaxis("商家A", [5, 20, 36, 10, 75, 90])
# render 会生成本地 HTML 文件，默认会在当前目录生成 render.html 文件
# 也可以传入路径参数，如 bar.render("mycharts.html")
# bar.add("1",["玉米","大豆","小麦"],[20,40,12],is_more_utils = True )

# bar.render()