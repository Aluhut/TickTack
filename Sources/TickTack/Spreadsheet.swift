import Foundation
import zlib

/// The small ZIP subset used by XLSX: stored/deflated members, bounded reads, no extraction to disk.
enum SpreadsheetZIP {
    static let limit = 30_000_000
    static func read(_ data: Data) throws -> [String: Data] {
        func number(_ offset: Int, _ count: Int) throws -> Int {
            guard offset >= 0, offset <= data.count - count else { throw TransferError.invalid("Beschädigte Excel-Datei.") }
            return (0..<count).reduce(0) { $0 | Int(data[offset + $1]) << ($1 * 8) }
        }
        guard data.count >= 22, data.count <= limit,
              let end = stride(from: data.count - 22, through: max(0, data.count - 65557), by: -1).first(where: { (try? number($0, 4)) == 0x06054b50 })
        else { throw TransferError.invalid("Beschädigte oder zu große Excel-Datei.") }
        let count = try number(end + 10, 2)
        var cursor = try number(end + 16, 4), total = 0, members: [String: Data] = [:]
        guard count < 2000 else { throw TransferError.invalid("Die Excel-Datei enthält zu viele Bestandteile.") }
        for _ in 0..<count {
            guard try number(cursor, 4) == 0x02014b50 else { throw TransferError.invalid("Beschädigte Excel-Datei.") }
            let flags = try number(cursor + 8, 2), method = try number(cursor + 10, 2)
            let checksum = try number(cursor + 16, 4), size = try number(cursor + 20, 4), expanded = try number(cursor + 24, 4)
            let nameSize = try number(cursor + 28, 2), extra = try number(cursor + 30, 2), comment = try number(cursor + 32, 2)
            let local = try number(cursor + 42, 4)
            guard cursor + 46 + nameSize <= data.count, flags & 1 == 0, [0, 8].contains(method),
                  expanded <= 10_000_000, size <= limit, total + expanded <= limit,
                  let name = String(data: data.subdata(in: cursor + 46..<cursor + 46 + nameSize), encoding: .utf8), members[name] == nil
            else { throw TransferError.invalid("Verschlüsselte oder zu große Excel-Dateien werden nicht unterstützt.") }
            guard try number(local, 4) == 0x04034b50 else { throw TransferError.invalid("Beschädigte Excel-Datei.") }
            let start = try local + 30 + number(local + 26, 2) + number(local + 28, 2)
            guard start >= 0, start <= data.count - size else { throw TransferError.invalid("Beschädigte Excel-Datei.") }
            let source = data.subdata(in: start..<start + size)
            var result: Data
            if method == 0 { result = source }
            else {
                result = Data(count: max(1, expanded))
                let status: Int32 = source.withUnsafeBytes { input in
                    result.withUnsafeMutableBytes { output in
                        var stream = z_stream()
                        stream.next_in = UnsafeMutablePointer(mutating: input.bindMemory(to: Bytef.self).baseAddress)
                        stream.avail_in = uInt(source.count)
                        stream.next_out = output.bindMemory(to: Bytef.self).baseAddress
                        stream.avail_out = uInt(output.count)
                        guard inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK else { return Z_DATA_ERROR }
                        defer { inflateEnd(&stream) }
                        let status = inflate(&stream, Z_FINISH)
                        return status == Z_STREAM_END && stream.total_out == expanded && stream.total_in == size ? Z_OK : Z_DATA_ERROR
                    }
                }
                guard status == Z_OK else { throw TransferError.invalid("Beschädigte Excel-Datei.") }
                result.count = expanded
            }
            let actualCRC = result.withUnsafeBytes { crc32(0, $0.bindMemory(to: Bytef.self).baseAddress, uInt(result.count)) }
            guard result.count == expanded, actualCRC == checksum else { throw TransferError.invalid("Beschädigte Excel-Datei.") }
            members[name] = result; total += expanded
            cursor += 46 + nameSize + extra + comment
        }
        return members
    }

    static func write(_ members: [(String, String)]) -> Data {
        var output = Data(), central = Data()
        func bytes(_ value: Int, _ size: Int) -> Data { Data((0..<size).map { UInt8((value >> ($0 * 8)) & 255) }) }
        for (name, text) in members {
            let content = Data(text.utf8), nameData = Data(name.utf8), offset = output.count
            let crc = Int(content.withUnsafeBytes { crc32(0, $0.bindMemory(to: Bytef.self).baseAddress, uInt(content.count)) })
            output += bytes(0x04034b50, 4) + bytes(20, 2) + bytes(0x800, 2) + bytes(0, 2) + bytes(0, 2) + bytes(33, 2)
            output += bytes(crc, 4) + bytes(content.count, 4) + bytes(content.count, 4) + bytes(nameData.count, 2) + bytes(0, 2) + nameData + content
            central += bytes(0x02014b50, 4) + bytes(20, 2) + bytes(20, 2) + bytes(0x800, 2) + bytes(0, 2) + bytes(0, 2) + bytes(33, 2)
            central += bytes(crc, 4) + bytes(content.count, 4) + bytes(content.count, 4) + bytes(nameData.count, 2)
            central += Data(repeating: 0, count: 12) + bytes(offset, 4) + nameData
        }
        let start = output.count
        output += central
        output += bytes(0x06054b50, 4) + bytes(0, 4) + bytes(members.count, 2) + bytes(members.count, 2) + bytes(central.count, 4) + bytes(start, 4) + bytes(0, 2)
        return output
    }
}

private final class SheetXML: NSObject, XMLParserDelegate {
    final class Node {
        let name: String
        let attributes: [String: String]
        var text = ""
        var children: [Node] = []
        init(_ name: String, _ attributes: [String: String]) { self.name = name; self.attributes = attributes }
        func child(_ name: String) -> Node? { children.first { $0.name == name } }
        var allText: String { text + children.map(\.allText).joined() }
    }
    let root = Node("root", [:])
    var stack: [Node] = []
    var count = 0
    static func parse(_ data: Data) throws -> Node {
        guard let text = String(data: data, encoding: .utf8), !text.contains("<!DOCTYPE"), !text.contains("<!ENTITY") else {
            throw TransferError.invalid("Nicht unterstütztes XML in der Excel-Datei.")
        }
        let delegate = SheetXML(); delegate.stack = [delegate.root]
        let parser = XMLParser(data: data); parser.delegate = delegate; parser.shouldResolveExternalEntities = false
        guard parser.parse() else { throw TransferError.invalid("Beschädigtes XML in der Excel-Datei.") }
        return delegate.root
    }
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        count += 1
        guard count <= 800000, stack.count < 64 else { parser.abortParsing(); return }
        let node = Node(elementName.split(separator: ":").last.map(String.init) ?? elementName, attributeDict)
        stack.last?.children.append(node); stack.append(node)
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) { stack.last?.text += string }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) { if stack.count > 1 { stack.removeLast() } }
}

enum Spreadsheet {
    static func tables(_ data: Data) throws -> [ImportTable] {
        let zip = try SpreadsheetZIP.read(data)
        func xml(_ name: String) throws -> SheetXML.Node {
            guard let data = zip[name] else { throw TransferError.invalid("Unvollständige Excel-Datei.") }
            return try SheetXML.parse(data)
        }
        let workbook = try xml("xl/workbook.xml").child("workbook")
        let relationships = try xml("xl/_rels/workbook.xml.rels").child("Relationships")?.children ?? []
        let strings = try zip["xl/sharedStrings.xml"].map { try SheetXML.parse($0).child("sst")?.children.filter { $0.name == "si" }.map(\.allText) ?? [] } ?? []
        let styles = try zip["xl/styles.xml"].flatMap { try SheetXML.parse($0).child("styleSheet") }
        let formats = styles?.child("numFmts")?.children ?? []
        let dateStyles = Set((styles?.child("cellXfs")?.children ?? []).enumerated().compactMap { index, node -> Int? in
            let id = Int(node.attributes["numFmtId"] ?? "") ?? 0
            if (14...22).contains(id) { return index }
            let format = formats.first { $0.attributes["numFmtId"] == String(id) }?.attributes["formatCode"]?.lowercased() ?? ""
            let plain = format.replacingOccurrences(of: #"\"[^\"]*\"|\[[^\]]*\]|\\."#, with: "", options: .regularExpression)
            return plain.contains("y") || plain.contains("d") ? index : nil
        })
        let date1904 = workbook?.child("workbookPr")?.attributes["date1904"].map { ["1", "true"].contains($0) } ?? false
        let epoch = AppLanguage.parseISODate(date1904 ? "1904-01-01" : "1899-12-30")!
        var tables: [ImportTable] = []
        for sheet in workbook?.child("sheets")?.children ?? [] {
            let relationshipID = sheet.attributes.first { $0.key.hasSuffix(":id") }?.value
            guard let relationshipID, let relation = relationships.first(where: { $0.attributes["Id"] == relationshipID }),
                  relation.attributes["TargetMode"] != "External", let target = relation.attributes["Target"] else { continue }
            let path = target.hasPrefix("/") ? String(target.dropFirst()) : "xl/" + target
            let resolved = (path as NSString).standardizingPath
            guard resolved.hasPrefix("xl/"), let data = zip[resolved] else { continue }
            let worksheet = try SheetXML.parse(data).child("worksheet")
            var rows: [[String]] = [], rowNumbers: [Int] = []
            for row in worksheet?.child("sheetData")?.children ?? [] {
                var values: [String] = []
                for cell in row.children where cell.name == "c" {
                    let letters = (cell.attributes["r"] ?? "").prefix { $0.isLetter }
                    guard letters.count <= 3, letters.utf8.allSatisfy({ (65...90).contains($0) }) else { throw TransferError.invalid("Beschädigte Excel-Datei.") }
                    let column = letters.utf8.reduce(0) { $0 * 26 + Int($1) - 64 } - 1
                    guard column >= 0, column < 256, rows.count < 100000 else { throw TransferError.invalid("Die Tabelle ist zu groß.") }
                    while values.count <= column { values.append("") }
                    let raw = cell.child("v")?.text ?? ""
                    let type = cell.attributes["t"] ?? "n"
                    if type == "s", let index = Int(raw), strings.indices.contains(index) { values[column] = strings[index] }
                    else if type == "inlineStr" { values[column] = cell.child("is")?.allText ?? "" }
                    else if dateStyles.contains(Int(cell.attributes["s"] ?? "") ?? -1), let serial = Double(raw), serial.isFinite, abs(serial) < 3_000_000 {
                        values[column] = AppLanguage.dateString(Calendar(identifier: .gregorian).date(byAdding: .day, value: Int(serial) + (!date1904 && serial < 60 ? 1 : 0), to: epoch)!)
                    } else if type == "n", let number = Double(raw), number.isFinite, raw.lowercased().contains("e") {
                        values[column] = String(format: "%.15f", locale: Locale(identifier: "en_US_POSIX"), number)
                    } else { values[column] = raw }
                }
                if values.contains(where: { !$0.isEmpty }) { rows.append(values); rowNumbers.append(Int(row.attributes["r"] ?? "") ?? rows.count) }
            }
            if !rows.isEmpty {
                var table = ImportTable(name: sheet.attributes["name"] ?? L("Tabelle"), rows: rows, rowNumbers: rowNumbers)
                table.suggestMapping(); tables.append(table)
            }
        }
        guard !tables.isEmpty else { throw TransferError.invalid("Keine lesbare Tabelle gefunden.") }
        return tables
    }

    static func export(project: TimeProject, entries: [Entry]) -> Data {
        func escape(_ text: String) -> String {
            String(String.UnicodeScalarView(text.unicodeScalars.filter { $0.value >= 32 || [9, 10, 13].contains($0.value) }))
                .replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
        }
        func cell(_ ref: String, _ text: String, _ style: Int) -> String {
            "<c r=\"\(ref)\" s=\"\(style)\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\(escape(text))</t></is></c>"
        }
        let headers = L("Position;Bereich;Tätigkeit;Konkreter Umfang;Bearbeitungszeitraum;Aufwand (h)").components(separatedBy: ";")
        var rows = "<row r=\"1\" ht=\"30\" customHeight=\"1\">" + headers.enumerated().map { cell("\(String(UnicodeScalar(65 + $0.offset)!))1", $0.element, 1) }.joined() + "</row>"
        for (index, entry) in entries.enumerated() {
            let r = index + 2, style = index % 2 == 0 ? 2 : 3
            let values = [entry.position ?? String(index + 1), entry.category, entry.task, entry.scope, entry.period]
            let characterWidths = [7, 19, 35, 57, 25]
            let lineCount = zip(values, characterWidths).map { value, width in
                value.components(separatedBy: "\n").reduce(0) { $0 + max(1, Int(ceil(Double($1.count) / Double(width)))) }
            }.max() ?? 1
            let height = min(409, max(36, lineCount * 17 + 12))
            rows += "<row r=\"\(r)\" ht=\"\(height)\" customHeight=\"1\">" + values.enumerated().map { cell("\(String(UnicodeScalar(65 + $0.offset)!))\(r)", $0.element, style) }.joined()
            rows += "<c r=\"F\(r)\" s=\"\(style + 2)\"><v>\(entry.seconds / 3600)</v></c></row>"
        }
        let ns = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
        let sheet = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><worksheet xmlns=\"\(ns)\"><sheetViews><sheetView workbookViewId=\"0\"><pane ySplit=\"1\" topLeftCell=\"A2\" activePane=\"bottomLeft\" state=\"frozen\"/></sheetView></sheetViews><sheetFormatPr defaultRowHeight=\"36\"/><cols><col min=\"1\" max=\"1\" width=\"10\" customWidth=\"1\"/><col min=\"2\" max=\"2\" width=\"22\" customWidth=\"1\"/><col min=\"3\" max=\"3\" width=\"38\" customWidth=\"1\"/><col min=\"4\" max=\"4\" width=\"60\" customWidth=\"1\"/><col min=\"5\" max=\"5\" width=\"28\" customWidth=\"1\"/><col min=\"6\" max=\"6\" width=\"16\" customWidth=\"1\"/></cols><sheetData>\(rows)</sheetData><autoFilter ref=\"A1:F\(entries.count + 1)\"/></worksheet>"
        let total = entries.reduce(0) { $0 + $1.seconds } / 3600
        let summary = "<worksheet xmlns=\"\(ns)\"><cols><col min=\"1\" max=\"2\" width=\"40\" customWidth=\"1\"/></cols><sheetData><row r=\"1\">\(cell("A1", project.name, 1))</row><row r=\"2\">\(cell("A2", L("Gesamtzeit dieses Projekts"), 2))<c r=\"B2\" s=\"4\"><v>\(total)</v></c></row><row r=\"3\">\(cell("A3", L("Stunden"), 2))</row><row r=\"4\">\(cell("A4", L("Nur gespeicherte Einträge; ohne laufende Messung."), 2))</row></sheetData></worksheet>"
        let styles = "<styleSheet xmlns=\"\(ns)\"><numFmts count=\"1\"><numFmt numFmtId=\"164\" formatCode=\"0.0000\"/></numFmts><fonts count=\"2\"><font><sz val=\"12\"/><name val=\"Calibri\"/></font><font><b/><sz val=\"12\"/><color rgb=\"FFFFFFFF\"/><name val=\"Calibri\"/></font></fonts><fills count=\"4\"><fill><patternFill patternType=\"none\"/></fill><fill><patternFill patternType=\"gray125\"/></fill><fill><patternFill patternType=\"solid\"><fgColor rgb=\"FF163B46\"/><bgColor indexed=\"64\"/></patternFill></fill><fill><patternFill patternType=\"solid\"><fgColor rgb=\"FFEDF4F5\"/><bgColor indexed=\"64\"/></patternFill></fill></fills><borders count=\"1\"><border/></borders><cellStyleXfs count=\"1\"><xf/></cellStyleXfs><cellXfs count=\"6\"><xf/><xf fontId=\"1\" fillId=\"2\" applyFill=\"1\" applyFont=\"1\"><alignment vertical=\"center\" wrapText=\"1\"/></xf><xf><alignment vertical=\"top\" wrapText=\"1\"/></xf><xf fillId=\"3\" applyFill=\"1\"><alignment vertical=\"top\" wrapText=\"1\"/></xf><xf numFmtId=\"164\" applyNumberFormat=\"1\"><alignment vertical=\"top\"/></xf><xf numFmtId=\"164\" fillId=\"3\" applyFill=\"1\" applyNumberFormat=\"1\"><alignment vertical=\"top\"/></xf></cellXfs><cellStyles count=\"1\"><cellStyle name=\"Normal\" xfId=\"0\" builtinId=\"0\"/></cellStyles></styleSheet>"
        return SpreadsheetZIP.write([
            ("[Content_Types].xml", "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\"><Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/><Default Extension=\"xml\" ContentType=\"application/xml\"/><Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/><Override PartName=\"/xl/worksheets/sheet1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/><Override PartName=\"/xl/worksheets/sheet2.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/><Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/></Types>"),
            ("_rels/.rels", "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\"><Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/></Relationships>"),
            ("xl/workbook.xml", "<workbook xmlns=\"\(ns)\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\"><sheets><sheet name=\"\(L("Einträge"))\" sheetId=\"1\" r:id=\"rId1\"/><sheet name=\"\(L("Übersicht"))\" sheetId=\"2\" r:id=\"rId2\"/></sheets></workbook>"),
            ("xl/_rels/workbook.xml.rels", "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\"><Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet1.xml\"/><Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet2.xml\"/><Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/></Relationships>"),
            ("xl/styles.xml", styles), ("xl/worksheets/sheet1.xml", sheet), ("xl/worksheets/sheet2.xml", summary)
        ])
    }
}
