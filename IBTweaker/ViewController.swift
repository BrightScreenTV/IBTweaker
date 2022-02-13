//
//  ViewController.swift
//  IBTweaker
//
//  Created by Todd Dalton on 12/02/2022.
//

import Cocoa

extension String {
    /// Handy hack for substring
    func subString(_range: NSRange) -> String {
        return String(Array(self)[_range.location ..< (_range.location + _range.length)])
    }
}

class ViewController: NSViewController, XMLParserDelegate {

    // a few variables to hold the results as we parse the XML
    // https://stackoverflow.com/a/31084545/372347

    var results: [[String: String]]?         // the whole array of dictionaries
    var currentDictionary: [String: String]? // the current dictionary
    var currentValue: String?                // the current value for one of the keys in the dictionary
    
    /// This is the control for fitering the output of the text view
    @IBOutlet weak var filterControl: NSSegmentedControl!
    
    /// This is the place to save the file
    var savePlace: URL? = nil
    
    ///Store the original text so we can just display filters and the like
    private var originalText: String = ""
    
    /// The font pull down ment
    @IBOutlet weak var fontsPopuUp: NSPopUpButton!
    
    /// The font size box
    @IBOutlet weak var fontSizeBox: NSTextField!
    
    /// This is the right-hand pane containing the IB file
    @IBOutlet weak var ibFileText: NSTextView!
    
    /// A singleton for parsing
    var parser: XMLParser = XMLParser()
    
    /// Store a font panel
    let fontManager = NSFontManager.shared
    let fontPanel: NSFontPanel = NSFontPanel.shared
    var selectedFont: NSFont? = nil
    
    /// These are the options for the segment filter control
    struct FilterInfo {
        /// This is the index of the segment in the `filterControl`
        var segmentIndex: Int
        /// This is the label of the segment for this filter in `filterControl`
        var label: String
        /// This is the text that will be looked for in the filter
        var filterText: String
    }
    
    let filters: [FilterInfo] = [
        FilterInfo(segmentIndex: 0, label: "FONTS", filterText: "<font\\skey=\"font\"\\s(metaFont=\"|size=\")(.+)>")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterControl.segmentCount = filters.count
        
        for filter in filters {
            filterControl.setLabel(filter.label, forSegment: filter.segmentIndex)
        }
        
        filterControl.action = #selector(self.filterClicked(_:))
        filterControl.target = self
        
        // Do any additional setup after loading the view.
        NSFontPanel.shared.setPanelFont(NSFont.systemFont(ofSize: 10), isMultiple: false)
        
        let fonts = NSFontManager.shared.availableFonts
        fontsPopuUp.removeAllItems()
        fontsPopuUp.addItems(withTitles: fonts.filter { !$0.starts(with: ".") })
        
        var DEBUG_MODE: Bool = true
        
        if DEBUG_MODE {
            let path = Bundle.main.url(forResource: "Main copy 2", withExtension: "storyboard")!
            ibFileText.string = (try? String(contentsOf: path)) ?? "nothing"
            originalText = ibFileText.string
        }
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    ///Generic function to show alert
    @discardableResult func alert(type: NSAlert.Style = .warning, title: String, body: String) -> NSApplication.ModalResponse {
        
        let alert = NSAlert()
        alert.alertStyle = type
        alert.informativeText = body
        alert.messageText = title
        return alert.runModal()
    }

    
    @IBAction func save(sender: NSButton) {
        
        guard let _savePlace = savePlace else { return }
        
        // Check it's not empty - TODO: make more of a thorough check of the string
        if originalText.isEmpty {
            if alert(title: "NO TEXT TO SAVE", body: "Do you really want to overwrite your file with nothing?") != .OK {
                return
            }
        }
        
        // Write the text to the current saved place
        do {
            try originalText.write(toFile: _savePlace.absoluteString, atomically: true, encoding: .utf8)
        } catch {
            alert(title: "COULDN'T SAVE", body: "Can't save the file!!!")
        }
    }
    
    /// Let user select the ib file
    @IBAction func open(sender: NSButton) {
        
        // Setup a panel to choose a file
        let opener: NSOpenPanel = NSOpenPanel()
        opener.canChooseDirectories = false
        opener.canChooseFiles = true
        opener.allowsMultipleSelection = false
        opener.title = "OPEN IB FILE...."
        
        // Get the user's input
        let response = opener.runModal()
        
        // Not worth going any further if they didn't select anything
        guard let _url = opener.url else { return }
        
        // Descide what to do
        switch response {
        case .OK:
            do {
                //Try to open the file
                let text = try String(contentsOf: _url)
                
                // Store the file's location for a quick save
                savePlace = _url
                
                // Clear filters
                for filter in filters {
                    filterControl.setSelected(false, forSegment: filter.segmentIndex)
                }
                
                // Set the text for the first time
                originalText = text
                
                self.filterClicked(filterControl)
            } catch {
                // Failed!
                alert(title: "CAN'T OPEN FILE", body: "Can't open \(opener.url?.path ?? "file")")
                // Reset the save location
                savePlace = nil
            }
        default:
            return
        }
    }
    
    ///Currently the only real function is to change the font to the
    ///one selected by the user in the main menu bar
    @IBAction func changeFont(sender: NSButton) {

        /// Check we've selected something
        guard let fontName: String = fontsPopuUp.selectedItem?.title else { return }
        
        /// Check it's a valid font
        guard let newFont = NSFont(name: fontName, size: CGFloat(fontSizeBox.floatValue)) else { return }
        
        let replacement: String = "<font key=\"font\" size=\"\(newFont.pointSize)\" name=\"\(newFont.fontName)\"/>"
        
        guard let regex = try? NSRegularExpression(pattern: "<font\\skey=\"font\"\\s(metaFont=\"|size=\")(.+)>", options: [.caseInsensitive]) else { return }
        
        guard let range = regex.matches(in: originalText, options: .withTransparentBounds, range: NSRange(location: 0, length: originalText.count - 1)).first?.range else { return }
        
        print(String(Array(originalText)[range.location..<(range.location + range.length)]))
        
        let newString = regex.stringByReplacingMatches(in: originalText, options: .withTransparentBounds, range: NSRange(location: 0, length: originalText.count), withTemplate: replacement)
        
        originalText = newString
        
        filterClicked(filterControl)
    }

    ///This is the method called when the user clicks a segment on the control
    @objc func filterClicked(_ sender: NSSegmentedControl) {
        
        var filterREGEXs:[NSRegularExpression] = []
        
        for filter in filters {
            if filterControl.isSelected(forSegment: filter.segmentIndex) {
                // This is a segment that's selected to get it's text pattern
                if let _regex = try? NSRegularExpression(pattern: filter.filterText, options: .caseInsensitive) {
                    filterREGEXs.append(_regex)
                }
            }
        }
        
        if filterREGEXs.isEmpty {
            // nothing to filter
            ibFileText.string = originalText
            return
        }
        
        ibFileText.string = ""
        
        for regex in filterREGEXs {
            regex.enumerateMatches(in: originalText, options: .withTransparentBounds, range: NSRange(location: 0, length: originalText.count)) { result, flags, objcBool in
                guard let _result = result else { return }
                ibFileText.string += originalText.subString(_range: _result.range) + "\n"
            }
        }
    }

}
