import os, strutils, sequtils, json, re
import nwt
import markdown

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

var templates = newNwt("template/*.html") # 模板引擎
#var markdown_files: seq[string]
var blogs: seq[Blog]

# 从Markdown文件获取博客信息
proc init_blog_form_md(file: string): Blog =
    var num = 0
    result.file = file
    var f = markdown_path & file
    for line in f.open().lines:
        num += 1
        if num < 6:
            var start_position = find(line, re"\(")
            var end_position = find(line, re"\)")
            if start_position > -1 and end_position > -1:
                var value = line[start_position + 1..end_position - 1]
                if num == 1: result.title = value
                if num == 2: result.category = value
                if num == 3: result.date = value
                if num == 4: result.keywords = value
                if num == 5: result.summary = value
    #echo result

# 获取Markdown文件
proc get_markdown_files() =
    for file in walkDirRec(markdown_path, relative = true):
        if file.endsWith ".md":
            #markdown_files.add file
            var blog = init_blog_form_md(file)
            blogs.add blog

# 生成首页
proc gen_index() =
    #var total_page: int = markdown_files.len div page_size
    #if markdown_files.len mod page_size > 0: total_page += 1
    #echo "total page: ", total_page
    #echo "len: ", markdown_files.len
    #for i in 1..total_page:
    var list: seq[string]
    for item in blogs:
        var html_item = """<li>
            <a class="title mb-10" href="/$1/$2.html">$2</a>
            <div class="info mb-10">分类：<a href="/$1">$1</a> 日期：<span>$3</span></div>
            <div class="summary mb-10">$4</div>
            <div class="keywords">$5</div>
        </li>""" % [item.category, item.title, item.date, item.summary, item.keywords]
        list.add html_item
    #echo list
    var context = %* {
        "list": list.join("")
    }
    var html = templates.renderTemplate("index.html", context)
    writeFile(html_path & "index.html", html)

# 生成博客页
proc gen_blog() =
    for item in blogs:
        var file = markdown_path & item.file
        var html_content: string
        for line in file.open().lines:
            html_content.add markdown(line)
        var context = %* {
            "content": html_content
        }
        var html = templates.renderTemplate("blog.html", context)
        var file_meta = splitFile(item.file)
        var target_dir = html_path & file_meta.dir
        if not existsDir(target_dir): createDir(target_dir)
        writeFile(target_dir & "/" & file_meta.name & ".html", html)

get_markdown_files()
gen_index()
gen_blog()