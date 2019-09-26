import os, strutils, sequtils, json, algorithm, times
import markdown
import render

type
    Blog = object
        title: string
        category: string
        date: string
        keywords: string
        summary: string
        file: string

const markdown_path = "./markdown/" # Markdown文件路径
const html_path = "./html/" # 生成的HTML文件路径
const page_size = 10 #分页大小

var view = View(path: "./template/") #实例化View对象
var categories: seq[string] # 所有分类
var blogs: seq[Blog] # 所有博客

# 从Markdown文件获取博客信息
proc initBlogFromMd(file: string): Blog =
    var num = 0
    result.file = file
    result.category = splitFile(file).dir
    var f = markdown_path & file
    for line in f.open().lines:
        if num == 0: result.title = line
        if num == 1: result.date = line
        if num == 2: result.keywords = line
        if num == 3: result.summary = line
        if num < 4: num += 1

# 按时间倒序排列
proc sortBlog(x, y: Blog): int =
    var a = parse(x.date, "yyyy-MM-dd")
    var b = parse(y.date, "yyyy-MM-dd")
    if a < b: -1 else: 1

# 清空已有的html文件
proc clearHTMLFile() = 
    for file in walkDirRec(html_path):
        if file.endsWith ".html":
            discard tryRemoveFile(file)

# 获取Markdown文件
proc initMdFile() =
    for file in walkDirRec(markdown_path, relative = true):
        if file.endsWith ".md":
            var meta = splitFile(file)
            if not categories.contains meta.dir: categories.add meta.dir # 分类
            var blog = initBlogFromMd(file)
            blogs.add blog
    blogs.sort(sortBlog, order = SortOrder.Descending)

# 写入HTML文件
proc writeHtmlFile(sourceFile, targetFile: string, data: JsonNode) =
    var source = view.render(sourceFile, data, uglify = true)
    var meta = splitFile(targetFile)
    if not existsDir(meta.dir): createDir(meta.dir)
    writeFile(targetFile, source)

# 生成博客列表内容
proc genBlogListHTML(list_blogs: seq[Blog]): seq[string] =
    for item in list_blogs:
        var meta = splitFile(item.file)
        var context = %* {
            "title": item.title,
            "category": item.category,
            "date": item.date,
            "keywords": item.keywords,
            "summary": item.summary,
            "file": meta.dir & "/" & meta.name & ".html"
        }
        var html = view.render("list-item.html", context, uglify = true)
        result.add html

# 生成博客列表文件
proc genListFile(list_blogs: seq[Blog], category: string = "") =
    var total_page = list_blogs.len div page_size # 总页数
    var m = list_blogs.len mod page_size # 余数
    if m > 0: total_page += 1
    for page in 1..total_page:
        var begin = page * page_size - page_size
        var number = page_size
        if page == total_page and m > 0: number = m
        var list_html = genBlogListHTML(list_blogs[begin..begin + number - 1])
        var context = %* {
            "title": if category.len  == 0: "首页" else: category,
            "list": list_html.join(""),
            "preview": if page > 1: """<a href="index$1.html">上一页</a>""" % [if page == 2: "" else: "-" & $(page - 1)] else: "",
            "next": if page < total_page: """<a href="index-$1.html">下一页</a>""" % [$(page + 1)] else: "",
            "page": page,
            "total_page": total_page
        }
        var target_file = html_path & category & "/index" & (if page > 1: "-" & $(page) else : "") & ".html"
        writeHtmlFile("list.html", target_file, context)
        
# 生成首页
proc genIndexPage() =
    genListFile(blogs)
    echo "Generated index page"

# 生成博客列表页
proc genListPage() =
    for c in categories:
        var list_blogs: seq[Blog]
        for blog in blogs:
            if blog.category == c: list_blogs.add blog
        genListFile(list_blogs, category = c)
        echo "Generated list pages of ", c

# 生成博客页
proc genDetailPage() =
    for item in blogs:
        var file = markdown_path & item.file
        var lines: seq[string]
        var num = 0
        for line in file.open().lines:
            if num > 4: lines.add line
            num += 1
        var html_content = markdown(lines.join("\n"))
        var context = %* {
            "content": html_content,
            "title": item.title,
            "category": item.category,
            "date": item.date,
            "keywords": item.keywords,
            "summary": item.summary
        }
        var meta = splitFile(item.file)
        var target_file = html_path & meta.dir & "/" & meta.name & ".html"
        writeHtmlFile("detail.html", target_file, context)
        echo "Generated blog page of ", target_file

initMdFile()
clearHTMLFile()
genIndexPage()
genListPage()
genDetailPage()