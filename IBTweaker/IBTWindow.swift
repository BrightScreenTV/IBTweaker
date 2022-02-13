//
//  IBTWindow.swift
//  IBTweaker
//
//  Created by Todd Dalton on 12/02/2022.
//

import Cocoa

class IBTWindow: NSWindow, NSWindowDelegate {
    
    func changeFont(_ sender: Any?) {
        
        guard let _manager = sender as? NSFontManager else { return }
        
        dump(_manager.selectedFont)
    }

}
