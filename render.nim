import json, re, strutils

type
    View* = object
        path*: string
        global*: JsonNode

# 处理include
proc parseInclude(v: View, source: string): string =
    let regexp = re"\{\%\s?include\s+.+\%\}"
    let start = re"\{\%\s?include\s+"
    let stop = re"\s?\%\}"
    result = source
    for m in source.findAll(regexp):
        var file = m.replace(start).replace(stop)
        result = result.replace(m, $(v.path & file).open().readAll())

# 处理数据
proc parseData(v: View, source: string, data: JsonNode): string = 
    let regexp = re"\{{2}\s?\w+\b\s?\}{2}"
    let start = re"\{{2}\s?"
    let stop = re"\s?\}{2}"
    result = source
    for m in source.findAll(regexp):
        var key = m.replace(start).replace(stop)
        result = result.replace(m, data[key].getStr())

proc render*(v: View, file: string, data: JsonNode = %* {}): string = 
    result = $(v.path & file).open().readAll()
    result = v.parseInclude(result)
    result = v.parseData(result, data)