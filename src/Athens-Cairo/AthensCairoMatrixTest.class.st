Class {
	#name : #AthensCairoMatrixTest,
	#superclass : #TestCase,
	#category : #'Athens-Cairo-Tests'
}

{ #category : #tests }
AthensCairoMatrixTest >> testCopy [

	| m |
	m := AthensCairoMatrix new.
	self assert: m getHandle equals: m copy getHandle.
	self assert: m getHandle ~~ m copy getHandle.
]

{ #category : #tests }
AthensCairoMatrixTest >> testInverted [

	| m |
	m := AthensCairoMatrix new.
	self assert: m getHandle ~~ m inverted getHandle.
]