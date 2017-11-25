Extension { #name : #TraitBehavior }

{ #category : #'*GT-SpotterExtensions-Core' }
TraitBehavior >> spotterClassInstanceVariablesFor: aStep [
	<spotterOrder: 25>
	self isTrait
		ifTrue: [ ^ self ].
	aStep listProcessor
		title: 'Class instance variables';
		allCandidates: [ self class classLayout allSlots ];
		itemName: [ :each | each name asString ];
		filter: GTFilterSubstring
]

{ #category : #'*GT-SpotterExtensions-Core' }
TraitBehavior >> spotterCompositionFor: aStep [
	<spotterOrder: 25>
	aStep listProcessor
			title: 'Composing traits';
			allCandidates: [ self traitComposition allTraits ];
			itemIcon: #systemIcon;
			filter: GTFilterSubstring
]

{ #category : #'*GT-SpotterExtensions-Core' }
TraitBehavior >> spotterInstanceVariablesFor: aStep [
	<spotterOrder: 20>
	self isTrait
		ifTrue: [ ^ self ].
	aStep listProcessor
		title: 'Instance variables';
		allCandidates: [ self classLayout allSlots ];
		itemName: [ :each | each name asString ];
		filter: GTFilterSubstring
]

{ #category : #'*GT-SpotterExtensions-Core' }
TraitBehavior >> spotterSubclassesFor: aStep [
	<spotterOrder: 50>
	aStep listProcessor
			title: 'All subclasses';
			allCandidates: [ self allSubclasses ];
			itemIcon: #systemIcon;
			filter: GTFilterSubstring
]

{ #category : #'*GT-SpotterExtensions-Core' }
TraitBehavior >> spotterSuperclassesFor: aStep [
	<spotterOrder: 40>
	aStep listProcessor
			title: 'All superclasses';
			allCandidates: [ self allSuperclasses ];
			itemIcon: #systemIcon;
			filter: GTFilterSubstring
]

{ #category : #'*GT-SpotterExtensions-Core' }
TraitBehavior >> spotterTraitUsersFor: aStep [
	<spotterOrder: 20>
	self isTrait ifFalse: [ ^ self ].
	aStep listProcessor
			title: 'Users';
			allCandidates: [ self traitUsers asArray ];
			itemIcon: #systemIcon;
			filter: GTFilterSubstring
]

{ #category : #'*GT-SpotterExtensions-Core' }
TraitBehavior >> spotterUsedSlotsFor: aStep [
	<spotterOrder: 70>
	aStep listProcessor
			title: 'Special Slots';
			allCandidates: [ self slots select: [ :slot | slot isSpecial ] ];
			itemName: [ :item | item definitionString ];
			filter: GTFilterSubstring
]

{ #category : #'*GT-SpotterExtensions-Core' }
TraitBehavior >> spotterUsedTraitsFor: aStep [
	<spotterOrder: 60>
	aStep listProcessor
			title: 'Uses Traits';
			allCandidates: [ self traits asArray ];
			itemIcon: #systemIcon;
			filter: GTFilterSubstring
]

{ #category : #'*GT-SpotterExtensions-Core-private' }
TraitBehavior >> withMethodsReferTo: aLiteral do: aBlock [
	| specialIndex |
	specialIndex := Smalltalk specialSelectorIndexOrNil: aLiteral.
	self selectorsAndMethodsDo: [ :selector :method | 
		((method hasLiteral: aLiteral) 
			or: [ specialIndex notNil and: [ method scanFor: method encoderClass firstSpecialSelectorByte + specialIndex ] ])
				ifTrue: [ aBlock value: method ] ]
]

{ #category : #'*GT-SpotterExtensions-Core-private' }
TraitBehavior >> withThorougMethodsReferTo: aLiteral do: aBlock [
	| specialIndex |
	specialIndex := Smalltalk specialSelectorIndexOrNil: aLiteral.
	self selectorsAndMethodsDo: [ :selector :method | 
		(method hasSelector: aLiteral specialSelectorIndex: specialIndex)
					ifTrue: [ aBlock value: method ] ].
]