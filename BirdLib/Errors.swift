//
//  Errors.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 5 November 2026.
//  Last changed on 5 November 2026.
//

import Foundation

public enum BirdWorldError: Error {

    case fileFormat(String)
}

public enum ProgramError: Error {

    case missingTaxonomyURL
    case argumentCount
}

