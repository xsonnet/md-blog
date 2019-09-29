import json, re, strutils

type
    NView* = object
        path*: string
        global*: JsonNode

# 处理token
proc parseExp(v: NView, expression: string): string = 
    if expression.startsWith("include"):
        var file = expression.replace(re"include\s+")
        result = $(v.path & file).open().readAll()

# 处理代码
proc prseSource(v: NView, source: string, data: JsonNode): string = 
    let reg = re"\{%(\s?\w+\/?)+\.?\w+\s?%\}|\{{2}\s?\w+\s?\}{2}"
    result = source
    for token in source.findAll(reg):
        if token.startsWith("{{") and token.endsWith("}}"):
            var key = token.replace(re"\{{2}\s?").replace(re"\s?\}{2}")
            result = result.replace(token, data[key].getStr())
        if token.startsWith("{%") and token.endsWith("%}"):
            var expression = token.replace(re"\{\%\s?").replace(re"\s?\%\}")
            result = result.replace(token, v.parseExp(expression))

proc render*(v: NView, file: string, data: JsonNode = %* {}): string = 
    result = $(v.path & file).open().readAll()
    result = v.prseSource(result, data)
    result = result.replace(re"\>(\t|\n|\s)+\<", "><") #去掉标签中的换行与空格