local XML_ = {
    writeln = function(self, s)
        self.file:write(string.rep("\t", self.indent) .. s .. "\n")
    end,
    incIndent = function(self)
        self.indent = self.indent + 1
    end,
    decIndent = function(self)
        self.indent = self.indent - 1
    end,
    startTag = function(self, s)
        self:writeln(s)
        self:incIndent()
    end,
    endTag = function(self, s)
        self:decIndent()
        self:writeln(s)
    end,
    open = function(self)
        self.file = io.open(self.filename, "w")
        self:writeln('<?xml version="1.0"?>')
    end,
    close = function(self)
        self.file:close()
    end
}

local ExcelXML_ = {
    writeWorkbook = function(self, inner)
        self:open()
        self:startTag('<ss:Workbook xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">')
        inner()
        self:endTag("</ss:Workbook>")
        self:close()
    end,
    writeWorksheet = function(self, name, inner)
        self:startTag('<ss:Worksheet ss:Name="' .. name .. '">')
        self:startTag('<ss:Table>')
        inner()
        self:endTag('</ss:Table>')
        self:endTag('</ss:Worksheet>')
    end,
    writeRow = function(self, inner)
        self:startTag('<ss:Row>')
        inner()
        self:endTag('</ss:Row>')
    end,
    writeCell = function(self, inner)
        self:startTag('<ss:Cell>')
        inner()
        self:endTag('</ss:Cell>')
    end,
    writeData = function(self, type, value)
        self:writeln('<ss:Data ss:Type="' .. type .. '">' .. value .. '</ss:Data>')
    end
}

setmetatable(ExcelXML_, {__index = XML_})

function XML(file)
    local xml = {indent = 0, filename = file}
    setmetatable(xml, {__index = XML_})
    return xml
end

function ExcelXML(file)
    local xls = XML(file)
    setmetatable(xls, {__index = ExcelXML_})
    return xls
end
