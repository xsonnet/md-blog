import os, strutils, json, algorithm
import markdown
import util, blog

type
    App = object
        markdownPath*: string
        htmlPath*: string
        categories*: seq[string]
        blogs*: seq[Blog]
        pageSize*: int

# 清空已有的html文件
proc clearHTMLFile(app: App) = 
    for file in walkDirRec(app.htmlPath):
        if file.endsWith ".html":
            discard tryRemoveFile(file)

# 获取Markdown文件
proc initMdFile(app: var App) =
    for file in walkDirRec(app.markdownPath, relative = true):
        if file.endsWith ".md":
            var meta = splitFile(file)
            if not app.categories.contains meta.dir: app.categories.add(meta.dir) # 分类
            var blog = util.initBlogFromMd(app.markdownPath, file)
            app.blogs.add(blog)
    app.blogs.sort(util.sortBlog, order = SortOrder.Descending)

# 生成博客列表文件
proc genListFile(app: App, list: seq[Blog], category: string = "") =
    var totalPage = app.blogs.len div app.pageSize # 总页数
    var m = list.len mod app.pageSize # 余数
    if m > 0: totalPage += 1
    for page in 1..totalPage:
        var begin = page * app.pageSize - app.pageSize
        var number = app.pageSize
        if page == totalPage and m > 0: number = m
        let html = util.genBlogListHTML(list[begin..begin + number - 1])
        var context = %* {
            "title": if category.len  == 0: "首页" else: category,
            "list": html.join(""),
            "preview": if page > 1: """<a href="index$1.html">上一页</a>""" % [if page == 2: "" else: "-" & $(page - 1)] else: "",
            "next": if page < totalPage: """<a href="index-$1.html">下一页</a>""" % [$(page + 1)] else: "",
            "page": $page,
            "total_page": $totalPage
        }
        var target_file = app.htmlPath & category & "/index" & (if page > 1: "-" & $(page) else : "") & ".html"
        writeHtmlFile("list.html", target_file, context)

# 生成博客列表页
proc genListPage(app: App) =
    for item in app.categories:
        var list: seq[Blog]
        for blog in app.blogs:
            if blog.category == item: list.add blog
        if list.len > 0:
            app.genListFile(list, category = item)
            echo "Generated list pages of ", item

# 生成博客页
proc genDetailPage(app: App) =
    for item in app.blogs:
        var file = app.markdownPath & item.file
        var lines: seq[string]
        var num = 0
        for line in file.open().lines:
            if num > 4: lines.add line
            num += 1
        var context = %* {
            "content": markdown(lines.join("\n")),
            "title": item.title,
            "category": item.category,
            "date": item.date,
            "keywords": item.keywords,
            "summary": item.summary
        }
        var meta = splitFile(item.file)
        var target_file = app.htmlPath & meta.dir & "/" & meta.name & ".html"
        writeHtmlFile("detail.html", target_file, context)
        echo "Generated blog page of ", target_file

proc main() =
    var app: App
    app.markdownPath = "./markdown/" # Markdown文件路径
    app.htmlPath = "./html/" # 生成的HTML文件路径
    app.pageSize = 10

    app.clearHTMLFile()
    app.initMdFile()
    app.genListFile(app.blogs)
    app.genListPage()
    app.genDetailPage()

main()