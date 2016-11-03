//
//  PropagatingTableDelegateDataSourceRequiredSpec.swift
//  CascadingTableDelegate
//
//  Created by Ricardo Pramana Suranta on 8/23/16.
//  Copyright © 2016 Ricardo Pramana Suranta. All rights reserved.
//

import Quick
import Nimble

@testable import CascadingTableDelegate

class PropagatingTableDelegateDataSourceRequiredSpec: QuickSpec {
	
	override func spec() {
		
		var propagatingTableDelegate: PropagatingTableDelegate!
		var childDelegates: [CascadingTableDelegateStub]!
		
		beforeEach { 
			
			childDelegates = [
				CascadingTableDelegateBareStub(index: 0, childDelegates: []),
				CascadingTableDelegateBareStub(index: 1, childDelegates: []),
				CascadingTableDelegateBareStub(index: 2, childDelegates: [])
			]
			
			propagatingTableDelegate = PropagatingTableDelegate(
				index: 20,
				childDelegates: childDelegates.map({ $0 as CascadingTableDelegate })
			)
		}
		
		
		describe("tableView(_:numberOfRowsInSection:)") {
			
			var expectedTableView: UITableView!
			
			beforeEach({
				expectedTableView = UITableView(frame: CGRectZero)
			})
			
			context("in .Row propagation mode", {
				
				var numberOfRows: Int!
				let sectionIndex = 20
				
				beforeEach({
					
					childDelegates.forEach({ $0.resetRecordedParameters() })
					
					propagatingTableDelegate.propagationMode = .Row
					
					numberOfRows = propagatingTableDelegate.tableView(
						expectedTableView,
						numberOfRowsInSection: sectionIndex
					)
				})
				
				it("should return the number of childDelegates as result", closure: {
					expect(numberOfRows).to(equal(childDelegates.count))					
				})
				
				it("should not call any of its childDelegates' methods", closure: {
					
					for childDelegate in childDelegates {
						expect(childDelegate.latestCalledDelegateMethod).to(beEmpty())
					}
				})
			})
			
			context("in .Section propagation mode", { 
				
				beforeEach({
					
					childDelegates.forEach({ $0.resetRecordedParameters() })
					
					propagatingTableDelegate.propagationMode = .Section
				})
				
				it("should return 0 when passed with invalid section number", closure: { 
					
					let invalidSectionIndex = 999
					
					let numberOfRows = propagatingTableDelegate.tableView(expectedTableView, numberOfRowsInSection: invalidSectionIndex)
					
					expect(numberOfRows).to(equal(0))
				})
				
				
				context("with valid index", {
					
					let validIndex = 1
					var numberOfRows: Int!
					
					beforeEach({
						
						numberOfRows = propagatingTableDelegate.tableView(expectedTableView, numberOfRowsInSection: validIndex)
					})
					
					it("should call its childDelegate of corresponding index's method with passed parameters ", closure: {
						
						let latestCalledFunction = childDelegates[validIndex].latestCalledDelegateMethod
						
						guard let calledMethod = latestCalledFunction.keys.first,
							let parameters = latestCalledFunction[calledMethod] as? (tableView: UITableView, section: Int) else {
								
							fail("No method called in child #\(validIndex).")
							return
						}
						
						let expectedMethod = #selector(UITableViewDataSource.tableView(_:numberOfRowsInSection:))
						
						expect(calledMethod).to(equal(expectedMethod))
						expect(parameters.tableView).to(equal(expectedTableView))
						expect(parameters.section).to(equal(validIndex))
					})
					
					it("should return the result from the corresponding child delegate", closure: { 
						
						let expectedDelegate = childDelegates[validIndex]
						let expectedResult = expectedDelegate.tableView(expectedTableView, numberOfRowsInSection: validIndex)
						
						expect(numberOfRows).to(equal(expectedResult))
					})
					
				})
				
				context("with invalid index", { 					
					
					let invalidIndex = 99
					var numberOfRows: Int!
					
					beforeEach({ 
						numberOfRows = propagatingTableDelegate.tableView(expectedTableView, numberOfRowsInSection: invalidIndex)
					})
					
					it("should return 0 as the result", closure: { 
						expect(numberOfRows).to(equal(0))
					})
					
					it("should not call any of its child delegates' method ", closure: {
						
						for childDelegate in childDelegates {
							expect(childDelegate.latestCalledDelegateMethod).to(beEmpty())
						}
					})
					
				})
			})
		}
		
		describe("tableView(_:cellForRowAtindexPath:)") { 
			
			var expectedTableView: UITableView!
			
			beforeEach({ 
				expectedTableView = UITableView(frame: CGRectZero)
			})
			
			context("in .Section propagation mode with invalid index path ", {
				
				var invalidPath: NSIndexPath!
				var cellResult: UITableViewCell!
				
				beforeEach({
					propagatingTableDelegate.propagationMode = .Section
					
					invalidPath = NSIndexPath(forRow: 0, inSection: 99)
					cellResult = propagatingTableDelegate.tableView(expectedTableView, cellForRowAtIndexPath: invalidPath)
				})
				
				it("should not call any of its child delegates' method", closure: { 
					
					for childDelegate in childDelegates {
						expect(childDelegate.latestCalledDelegateMethod).to(beEmpty())
					}
				})
				
				it("should return a dummy UITableViewCell instead of nil", closure: { 
					expect(cellResult).toNot(beNil())
				})
			})
			
			context("in .Section propagation mode with valid index path", { 
				
				var validPath: NSIndexPath!
				var cellResult: UITableViewCell!
				
				beforeEach({
					
					propagatingTableDelegate.propagationMode = .Section
					
					validPath = NSIndexPath(forItem: 0, inSection: 0)
					cellResult = propagatingTableDelegate.tableView(expectedTableView, cellForRowAtIndexPath: validPath)
				})
				
				it("should call the corresponding method to child with same index of the section using passed parameters", closure: {
					
					let childDelegate = childDelegates[0]
					let calledMethods = childDelegate.latestCalledDelegateMethod
					
					guard let calledMethod = calledMethods.keys.first,
						let calledParameters = calledMethods[calledMethod] as? (tableView: UITableView, indexPath: NSIndexPath) else {
							
							fail("tableView(_:indexPath:) not called correctly")
							return
					}
					
					expect(calledMethod).to(equal(#selector(UITableViewDataSource.tableView(_:cellForRowAtIndexPath:))))
					expect(calledParameters.tableView).to(equal(expectedTableView))
					expect(calledParameters.indexPath).to(equal(validPath))
				})
				
				it("should return the cell result from the child delegate's method", closure: { 
					
					let childDelegate = childDelegates[0]
					
					expect(cellResult).to(beIdenticalTo(childDelegate.returnedTableCell))
				})
			})
			
			context("in .Row propagation mode with invalid index path", {
				
				var invalidPath: NSIndexPath!
				var cellResult: UITableViewCell!
				
				beforeEach({
					
					propagatingTableDelegate.propagationMode = .Row
					
					invalidPath = NSIndexPath(forRow: 99, inSection: 0)
					cellResult = propagatingTableDelegate.tableView(expectedTableView, cellForRowAtIndexPath: invalidPath)
				})
				
				it("should not call any of its child delegate's methods", closure: {
					for childDelegate in childDelegates {
						expect(childDelegate.latestCalledDelegateMethod).to(beEmpty())
					}
				})
				
				it("should return new UITableViewCell instance instead of nil", closure: {
					expect(cellResult).toNot(beNil())
				})
			})
			
			context("in .Row propagation mode with valid index path", { 
				
				var validPath: NSIndexPath!
				var cellResult: UITableViewCell!
				
				beforeEach({ 
					propagatingTableDelegate.propagationMode = .Row
					
					validPath = NSIndexPath(forRow: 0, inSection: 0)
					cellResult = propagatingTableDelegate.tableView(expectedTableView, cellForRowAtIndexPath: validPath)
				})
				
				it("should call corresponding method on child delegate with same index with the row using passed parameters", closure: { 
					
					let childDelegate = childDelegates[0]
					let calledMethods = childDelegate.latestCalledDelegateMethod
					
					guard let calledMethod = calledMethods.keys.first,
						let calledParameters = calledMethods[calledMethod] as? (tableView: UITableView, indexPath: NSIndexPath) else {
							fail("tableView(_:cellForRowAtIndexPath:) not called correctly")
							return
					}
					
					expect(calledMethod).to(equal(#selector(UITableViewDataSource.tableView(_:cellForRowAtIndexPath:))))
					expect(calledParameters.tableView).to(equal(expectedTableView))
					expect(calledParameters.indexPath).to(equal(validPath))
				})
				
				it("should return the result of corresponding child delegate's method", closure: { 
					let childDelegate = childDelegates[0]
					expect(cellResult).to(beIdenticalTo(childDelegate.returnedTableCell))
				})
			})
			
		}
	}
}