import blog, times, os, nview, json

# 从Markdown文件获取博客信息
proc initBlogFromMd*(path, file: string): Blog =
    var num = 0
    result.file = file
    result.category = splitFile(file).dir
    let f = path & file
    for line in f.open().lines:
        if num == 0: result.title = line
        if num == 1: result.date = line
        if num == 2: result.keywords = line
        if num == 3: result.summary = line
        if num < 4: num += 1

# 按时间倒序排列
proc sortBlog*(x, y: Blog): int =
    let a = parse(x.date, "yyyy-MM-dd")
    let b = parse(y.date, "yyyy-MM-dd")
    if a < b: -1 else: 1

# 写入HTML文件
proc writeHtmlFile*(sourceFile, targetFile: string, data: JsonNode) =
    let view = NView(path: "./template/")
    let source = view.render(sourceFile, data)
    let meta = splitFile(targetFile)
    if not existsDir(meta.dir): createDir(meta.dir)
    writeFile(targetFile, source)

# 生成博客列表内容
proc genBlogListHTML*(blogs: seq[Blog]): seq[string] =
    let view = NView(path: "./template/")
    for item in blogs:
        var meta = splitFile(item.file)
        var context = %* {
            "title": item.title,
            "category": item.category,
            "date": item.date,
            "keywords": item.keywords,
            "summary": item.summary,
            "file": meta.dir & "/" & meta.name & ".html"
        }
        var html = view.render("list-item.html", context)
        result.add html