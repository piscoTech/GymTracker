//
//  GTDataModelExport.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 14/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

enum GTDataImportError: Error {
	case failure(GTDataObject?)
}

extension GTDataObject {
	
	@objc func export() -> String {
		fatalError("Abstract method not implemented")
	}
	
	///Read XML data and create the corresponding `GTDataObject`, this method assumes that data is valid according to `workout.xsd`.
	///- returns: The created `GTDataObject`.
	///- throws: Throws `GTDataImportErrorWhether.failure` in case of failure, if the error contains a `GTDataObject` it must be deleted.
	@objc class func `import`(fromXML xml: XMLNode, withDataManager dataManager: DataManager) throws -> GTDataObject {
		fatalError("Abstract method not implemented")
	}
}
