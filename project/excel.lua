
function XML(file)
	local xml = {}
	xml.indent = 0
	function xml:writeln(s)
		self.file:write(string.rep("\t", self.indent) .. s .. "\n")
	end
	function xml:incIndent()
		self.indent = self.indent + 1
	end
	function xml:decIndent()
		self.indent = self.indent - 1
	end
	function xml:startTag(s)
		self:writeln(s)
		self:incIndent()
	end
	function xml:endTag(s)
		self:decIndent()
		self:writeln(s)
	end
	function xml:open()
		self.file = io.open(file, "w")
		self:writeln('<?xml version="1.0"?>')
	end
	function xml:close()
		self.file:close()
	end
	return xml
end

function ExcelXML(file)
	local xls = XML(file)
	function xls:writeWorkbook(inner)
		self:open()
		self:startTag('<ss:Workbook xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">')
		inner()
		self:endTag("</ss:Workbook>")
		self:close()
	end
	function xls:writeWorksheet(name, inner)
		self:startTag('<ss:Worksheet ss:Name="' .. name .. '">')
		self:startTag('<ss:Table>')
		inner()
		self:endTag('</ss:Table>')
		self:endTag('</ss:Worksheet>')
	end
	function xls:writeRow(inner)
		self:startTag('<ss:Row>')
		inner()
		self:endTag('</ss:Row>')
	end
	function xls:writeCell(inner)
		self:startTag('<ss:Cell>')
		inner()
		self:endTag('</ss:Cell>')
	end
	function xls:writeData(type, value)
		self:writeln('<ss:Data ss:Type="' .. type .. '">' .. value .. '</ss:Data>')
	end
	return xls
end
