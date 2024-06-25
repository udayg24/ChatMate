//
//  Extensions.swift
//  ChatApp
//
//  Created by Uday Gajera on 25/06/24.
//

import Foundation
import UIKit

extension UIView {
    public var width: CGFloat {
        self.frame.size.width
    }
    public var height: CGFloat {
        self.frame.size.height
    }
    public var top: CGFloat {
        self.frame.origin.y
    }
    public var bottom: CGFloat {
        self.frame.size.height + self.frame.origin.y
    }
    public var left: CGFloat {
        self.frame.origin.x
    }
    public var right: CGFloat {
        self.frame.size.width + self.frame.origin.x
    }
}
