//
//  ActiveLabel.swift
//  ActiveLabel
//
//  Created by Johannes Schickling on 9/4/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

public protocol ActiveLabelDelegate: class {
    func didSelectText(_ text: String, type: ActiveType)
    func didSelectRegexText(_ values: [String])
}

extension ActiveLabelDelegate {
    func didSelectRegexText(_ values: [String]) {
    }
}

@IBDesignable open class ActiveLabel: UILabel {
    
    // MARK: - public properties
    open weak var delegate: ActiveLabelDelegate?
    
    @IBInspectable open var mentionEnabled: Bool = true {
        didSet {
            updateTextStorage()
        }
    }
    @IBInspectable open var hashtagEnabled: Bool = true {
        didSet {
            updateTextStorage()
        }
    }
    @IBInspectable open var URLEnabled: Bool = true {
        didSet {
            updateTextStorage()
        }
    }
    @IBInspectable open var mentionColor: UIColor = .blue {
        didSet {
            updateTextStorage()
        }
    }
    @IBInspectable open var mentionSelectedColor: UIColor? {
        didSet {
            updateTextStorage()
        }
    }
    @IBInspectable open var hashtagColor: UIColor = .blue {
        didSet {
            updateTextStorage()
        }
    }
    @IBInspectable open var hashtagSelectedColor: UIColor? {
        didSet {
            updateTextStorage()
        }
    }
    @IBInspectable open var URLColor: UIColor = .blue {
        didSet {
            updateTextStorage()
        }
    }
    @IBInspectable open var URLSelectedColor: UIColor? {
        didSet {
            updateTextStorage()
        }
    }
    open var regexAttributes: ([String]) -> [String : AnyObject]? = { _ in
        return nil
    } {
        didSet {
            updateTextStorage()
        }
    }
    open var regexColor: ([String]) -> UIColor = { _ in
        return .blue
    } {
        didSet {
            updateTextStorage()
        }
    }
    open var regexSelectedColor: (([String]) -> UIColor?)? {
        didSet {
            updateTextStorage()
        }
    }
    open var regex: NSRegularExpression? {
        didSet {
            updateTextStorage()
        }
    }
    @IBInspectable open var lineSpacing: Float = 0 {
        didSet {
            updateTextStorage()
        }
    }
    
    // MARK: - public methods
    open func handleMentionTap(_ handler: @escaping (String) -> ()) {
        mentionTapHandler = handler
    }
    
    open func handleHashtagTap(_ handler: @escaping (String) -> ()) {
        hashtagTapHandler = handler
    }
    
    open func handleURLTap(_ handler: @escaping (URL) -> ()) {
        urlTapHandler = handler
    }
    
    open func handleRegexTap(_ handler: @escaping ([String]) -> ()) {
        regexTapHandler = handler
    }
    
    open func handleRegexReplace(_ handler: @escaping ([String]) -> String?) {
        regexReplaceHandler = handler
    }
    
    // MARK: - override UILabel properties
    override open var text: String? {
        didSet {
            updateTextStorage()
        }
    }
    
    override open var attributedText: NSAttributedString? {
        didSet {
            updateTextStorage()
        }
    }
    
    override open var font: UIFont! {
        didSet {
            updateTextStorage()
        }
    }
    
    override open var textColor: UIColor! {
        didSet {
            updateTextStorage()
        }
    }
    
    // MARK: - init functions
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLabel()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupLabel()
    }
    
    open override func drawText(in rect: CGRect) {
        let range = NSRange(location: 0, length: textStorage.length)
        
        textContainer.size = rect.size
        
        layoutManager.drawBackground(forGlyphRange: range, at: rect.origin)
        layoutManager.drawGlyphs(forGlyphRange: range, at: rect.origin)
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let currentSize = textContainer.size
        defer {
            textContainer.size = currentSize
        }
        
        textContainer.size = size
        return layoutManager.usedRect(for: textContainer).size
    }
    
    // MARK: - touch events
    func onTouch(_ touch: UITouch) -> Bool {
        let location = touch.location(in: self)
        var avoidSuperCall = false
        
        switch touch.phase {
        case .began, .moved:
            if let element = elementAtLocation(location) {
                if element.range.location != selectedElement?.range.location || element.range.length != selectedElement?.range.length {
                    updateAttributesWhenSelected(false)
                    selectedElement = element
                    updateAttributesWhenSelected(true)
                }
                avoidSuperCall = true
            } else {
                updateAttributesWhenSelected(false)
                selectedElement = nil
            }
        case .cancelled, .ended:
            guard let selectedElement = selectedElement else { return avoidSuperCall }
            
            switch selectedElement.element {
            case .mention(let userHandle): didTapMention(userHandle)
            case .hashtag(let hashtag): didTapHashtag(hashtag)
            case .url(let url): didTapStringURL(url)
            case .regex(let values): didTapRegex(values)
            case .none: ()
            }
            
            let when = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: when) {
                self.updateAttributesWhenSelected(false)
                self.selectedElement = nil
            }
            avoidSuperCall = true
        default: ()
        }
        
        return avoidSuperCall
    }
    
    // MARK: - private properties
    fileprivate var mentionTapHandler: ((String) -> ())?
    fileprivate var hashtagTapHandler: ((String) -> ())?
    fileprivate var urlTapHandler: ((URL) -> ())?
    fileprivate var regexTapHandler: (([String]) -> ())?
    fileprivate var regexReplaceHandler: (([String]) -> String?)? {
        didSet {
            updateTextStorage()
        }
    }
    
    fileprivate var selectedElement: (range: NSRange, element: ActiveElement)?
    fileprivate lazy var textStorage = NSTextStorage()
    fileprivate lazy var layoutManager = NSLayoutManager()
    fileprivate lazy var textContainer = NSTextContainer()
    fileprivate lazy var activeElements: [ActiveType: [(range: NSRange, element: ActiveElement)]] = [
        .mention: [],
        .hashtag: [],
        .url: [],
        .regex: [],
    ]
    
    // MARK: - helper functions
    fileprivate func setupLabel() {
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        isUserInteractionEnabled = true
    }
    
    fileprivate func updateTextStorage() {
        guard let attributedText = attributedText else {
            return
        }
        
        // clean up previous active elements
        for (type, _) in activeElements {
            activeElements[type]?.removeAll()
        }
        
        guard attributedText.length > 0 else {
            return
        }
        
        let mutAttrString = addLineBreak(attributedText)
        parseTextAndExtractActiveElements(mutAttrString)
        addLinkAttribute(mutAttrString)
        
        textStorage.setAttributedString(mutAttrString)
        super.attributedText = mutAttrString
        
        setNeedsDisplay()
    }
    
    /// add link attribute
    fileprivate func addLinkAttribute(_ mutAttrString: NSMutableAttributedString) {
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributes(at: 0, effectiveRange: &range)
        
        attributes[NSAttributedStringKey.font] = font!
        attributes[NSAttributedStringKey.foregroundColor] = textColor
        mutAttrString.addAttributes(attributes, range: range)
        
        attributes[NSAttributedStringKey.foregroundColor] = mentionColor
        
        for (type, elements) in activeElements {
            
            var isRegex = false
            switch type {
            case .mention: attributes[NSAttributedStringKey.foregroundColor] = mentionColor
            case .hashtag: attributes[NSAttributedStringKey.foregroundColor] = hashtagColor
            case .url: attributes[NSAttributedStringKey.foregroundColor] = URLColor
            case .regex: isRegex = true
            case .none: ()
            }
            
            for element in elements {
                if isRegex {
                    if case .regex(let values) = element.element {
                        attributes[NSAttributedStringKey.foregroundColor] = regexColor(values)
                        if let attrs = regexAttributes(values), !attrs.isEmpty {
                            for (k, v) in attrs {
                                attributes[NSAttributedStringKey(k)] = v
                            }
                        }
                    }
                }
                mutAttrString.setAttributes(attributes, range: element.range)
            }
        }
    }
    
    /// use regex check all link ranges
    fileprivate func parseTextAndExtractActiveElements(_ mutAttrString: NSMutableAttributedString) {
        if let regex = regex, let elements = reduceToRegex(mutAttrString, regex: regex, replaceHandler: regexReplaceHandler) {
            let mapElements = elements.map({ (range: NSRange, values: [String]) -> (range: NSRange, element: ActiveElement) in
                return (range, .regex(values))
            })
            activeElements[.regex]?.append(contentsOf: mapElements)
        }
        
        let textString = mutAttrString.string as NSString
        let textLength = textString.length
        var searchRange = NSMakeRange(0, textLength)
        
        for word in textString.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
            let element = activeElement(word)
    
            if case .none = element {
                continue
            }
            
            let elementRange = textString.range(of: word, options: .literal, range: searchRange)
            defer {
                let startIndex = elementRange.location + elementRange.length
                searchRange = NSMakeRange(startIndex, textLength - startIndex)
            }
            
            switch element {
            case .mention where mentionEnabled:
                activeElements[.mention]?.append((elementRange, element))
            case .hashtag where hashtagEnabled:
                activeElements[.hashtag]?.append((elementRange, element))
            case .url where URLEnabled:
                activeElements[.url]?.append((elementRange, element))
            default: ()
            }
        }
    }
    
    /// add line break mode
    fileprivate func addLineBreak(_ attrString: NSAttributedString) -> NSMutableAttributedString {
        let mutAttrString = NSMutableAttributedString(attributedString: attrString)
        
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributes(at: 0, effectiveRange: &range)
        
        let paragraphStyle = attributes[NSAttributedStringKey.paragraphStyle] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.lineSpacing = CGFloat(lineSpacing)
        
        attributes[NSAttributedStringKey.paragraphStyle] = paragraphStyle
        mutAttrString.setAttributes(attributes, range: range)
        
        return mutAttrString
    }
    
    fileprivate func updateAttributesWhenSelected(_ isSelected: Bool) {
        guard let selectedElement = selectedElement else {
            return
        }
        
        var attributes = textStorage.attributes(at: 0, effectiveRange: nil)
        if isSelected {
            switch selectedElement.element {
            case .mention(_): attributes[NSAttributedStringKey.foregroundColor] = mentionColor
            case .hashtag(_): attributes[NSAttributedStringKey.foregroundColor] = hashtagColor
            case .url(_): attributes[NSAttributedStringKey.foregroundColor] = URLColor
            case .regex(let values):
                attributes[NSAttributedStringKey.foregroundColor] = regexColor(values)
                if let attrs = regexAttributes(values), !attrs.isEmpty {
                    for (k, v) in attrs {
                        attributes[NSAttributedStringKey(k)] = v
                    }
                }
            case .none: ()
            }
        } else {
            switch selectedElement.element {
            case .mention(_): attributes[NSAttributedStringKey.foregroundColor] = mentionSelectedColor ?? mentionColor
            case .hashtag(_): attributes[NSAttributedStringKey.foregroundColor] = hashtagSelectedColor ?? hashtagColor
            case .url(_): attributes[NSAttributedStringKey.foregroundColor] = URLSelectedColor ?? URLColor
            case .regex(let values):
                attributes[NSAttributedStringKey.foregroundColor] = regexSelectedColor?(values) ?? regexColor(values)
                if let attrs = regexAttributes(values), !attrs.isEmpty {
                    for (k, v) in attrs {
                        attributes[NSAttributedStringKey(k)] = v
                    }
                }
            case .none: ()
            }
        }
        
        textStorage.addAttributes(attributes, range: selectedElement.range)
        
        setNeedsDisplay()
    }
    
    fileprivate func elementAtLocation(_ location: CGPoint) -> (range: NSRange, element: ActiveElement)? {
        guard textStorage.length > 0 else {
            return nil
        }
        
        let boundingRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: 0, length: textStorage.length), in: textContainer)
        guard boundingRect.contains(location) else {
            return nil
        }
        
        let index = layoutManager.glyphIndex(for: location, in: textContainer)
        
        for element in activeElements.map({ $0.1 }).joined() {
            if index >= element.range.location && index <= element.range.location + element.range.length {
                return element
            }
        }
        
        return nil
    }
    
    
    //MARK: - Handle UI Responder touches
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesBegan(touches, with: event)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        onTouch(touch)
        super.touchesCancelled(touches, with: event)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesEnded(touches, with: event)
    }
    
    //MARK: - ActiveLabel handler
    fileprivate func didTapMention(_ username: String) {
        guard let mentionHandler = mentionTapHandler else {
            delegate?.didSelectText(username, type: .mention)
            return
        }
        mentionHandler(username)
    }
    
    fileprivate func didTapHashtag(_ hashtag: String) {
        guard let hashtagHandler = hashtagTapHandler else {
            delegate?.didSelectText(hashtag, type: .hashtag)
            return
        }
        hashtagHandler(hashtag)
    }
    
    fileprivate func didTapStringURL(_ stringURL: String) {
        guard let urlHandler = urlTapHandler, let url = URL(string: stringURL) else {
            delegate?.didSelectText(stringURL, type: .url)
            return
        }
        urlHandler(url)
    }
    
    fileprivate func didTapRegex(_ values: [String]) {
        guard let handler = regexTapHandler else {
            delegate?.didSelectRegexText(values)
            return
        }
        handler(values)
    }
}

extension ActiveLabel: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
