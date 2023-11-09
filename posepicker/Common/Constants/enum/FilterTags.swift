//
//  FilterTags.swift
//  posepicker
//
//  Created by 박경준 on 2023/10/27.
//

import Foundation

enum FilterTags: String {
    case friend = "친구"
    case couple = "커플"
    case family = "가족"
    case coworker = "동료"
    case fun = "재미"
    case natural = "자연스러움"
    case trend = "유행"
    case celebrity = "유명인 프레임"
    case props = "소품"
    
    static func getAllFilterTags() -> [FilterTags] {
        return [.friend, .couple, .family, .coworker, .fun, .natural, .trend, .celebrity, .props]
    }
    
    static func getTagFromTitle(title: String) -> FilterTags? {
        switch title {
        case "친구": return .friend
        case "커플": return .couple
        case "가족": return .family
        case "동료": return .coworker
        case "재미": return .fun
        case "자연스러움": return .natural
        case "유행": return .trend
        case "유명인 프레임": return .celebrity
        case "소품": return .props
        default: return nil
        }
    }
    
    static func getNumberFromPeopleCountString(countString: String) -> Int {
        switch countString {
        case "전체":
            return 0
        case "1인":
            return 1
        case "2인":
            return 2
        case "3인":
            return 3
        case "4인":
            return 4
        case "5인+":
            return 5
        default:
            return 0
        }
    }
    
    static func getNumberFromFrameCountString(countString: String) -> Int {
        switch countString {
        case "전체":
            return 0
        case "1컷":
            return 1
        case "3컷":
            return 3
        case "4컷":
            return 4
        case "6컷":
            return 6
        case "8컷+":
            return 8
        default:
            return 0
        }
    }
    
    func getTagNumber() -> Int {
        switch self {
        case .friend: return 0
        case .couple: return 1
        case .family: return 2
        case .coworker: return 3
        case .fun: return 4
        case .natural: return 5
        case .trend: return 6
        case .celebrity: return 7
        case .props: return 8
        }
    }
}
