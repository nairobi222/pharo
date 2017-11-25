"
MB stands for Metacello Borwser.
MBConfigurationRoot is the root object holding information on all available configurations in the image.

Instance Variables
	announcer:		<Object>
	configurations:	a collection of MBConfigurationInfo.
	password:		<Object>
	username:		<Object>

"
Class {
	#name : #MBConfigurationRoot,
	#superclass : #Object,
	#instVars : [
		'announcer',
		'configurations',
		'username',
		'password'
	],
	#classVars : [
		'Current'
	],
	#category : #'Versionner-Core-Model'
}

{ #category : #accessing }
MBConfigurationRoot class >> current [
	"singleton pattern"
	Current ifNil: [ 
		Current := self new.
		Current register ].
	^Current 
]

{ #category : #accessing }
MBConfigurationRoot class >> reset [
	"self reset"
	| c |
	Current ifNil: [ ^self ].
	c := Current.
	Current := nil.
	c unregister.

]

{ #category : #actions }
MBConfigurationRoot >> addConfigurationInfoFor: aConfigurationClass [
	(self configurationInfoFor: aConfigurationClass) notNil
		ifTrue: [ ^ self ].
	self configurations
		add:
			((MBConfigurationInfo configurationClass: aConfigurationClass)
				configurationRoot: self;
				yourself).
	self announcer announce: MBConfigurationInfoCreated
]

{ #category : #accessing }
MBConfigurationRoot >> announcer [

	^announcer 
]

{ #category : #updating }
MBConfigurationRoot >> categoryModified: anEvent [
	"(anEvent itemClass name asString beginsWith: 'ConfigurationOf')
		ifTrue: [  self respondToEventFor: anEvent itemClass withOperation: #modified ]"
 
	self flag: 'update only needed configurations'.
	"configName := 'ConfigurationOf' , (anEvent item).
	configClass := Smalltalk at: (configName asSymbol).
	configClass ifNotNilDo: [ 
		configInfo := self configurationInfoFor: configClass.
		configInfo fullRecalculate ]."
	self configurations do: [:config | config fullRecalculate ].
]

{ #category : #updating }
MBConfigurationRoot >> classAdded: anEvent [

	(anEvent classAdded name asString beginsWith: 'ConfigurationOf')
		ifTrue: [ self respondToEventFor: anEvent classAdded withOperation: #added ]
]

{ #category : #updating }
MBConfigurationRoot >> classModified: anEvent [

	(anEvent classAffected name asString beginsWith: 'ConfigurationOf')
		ifTrue: [ self respondToEventFor: anEvent classAffected withOperation: #modified ]
]

{ #category : #updating }
MBConfigurationRoot >> classRemoved: anEvent [

	(anEvent classRemoved originalName asString beginsWith: 'ConfigurationOf')
		ifTrue: [ self respondToEventFor: anEvent classRemoved withOperation: #removed ]
]

{ #category : #accessing }
MBConfigurationRoot >> configurationClasses [
	^ MetacelloToolBox configurationClasses
]

{ #category : #accessing }
MBConfigurationRoot >> configurationInfoFor: aConfigurationClass [

	self configurations do: [:info | info configurationClass == aConfigurationClass theNonMetaClass  ifTrue: [ ^info ]].
	^nil
]

{ #category : #accessing }
MBConfigurationRoot >> configurations [
	configurations
		ifNil: [ 
			configurations := (self configurationClasses
				collect: [ :cls | 
					(MBConfigurationInfo configurationClass: cls)
						configurationRoot: self;
						yourself ]) asSortedCollection: [ :a :b | a name <= b name ] ].
	^ configurations
]

{ #category : #'initialize-release' }
MBConfigurationRoot >> initialize [

	super initialize .
	announcer := Announcer new
]

{ #category : #updating }
MBConfigurationRoot >> methodModified: anEvent [

	(anEvent methodAffected class name asString beginsWith: 'ConfigurationOf')
		ifTrue: [  self respondToEventFor: anEvent methodAffected withOperation: #modified ]
]

{ #category : #accessing }
MBConfigurationRoot >> password [
	^ password
]

{ #category : #accessing }
MBConfigurationRoot >> password: anObject [
	password := anObject
]

{ #category : #updating }
MBConfigurationRoot >> register [
	"Set up dependencies"
	
	SystemAnnouncer uniqueInstance weak
		when: ClassAdded send: #classAdded: to: self;
		when: ClassModifiedClassDefinition,
			ClassCommented,
			ClassRenamed, 
			ClassReorganized,
			ClassRenamed send: #classModified: to: self;
		when: ClassRemoved send: #classRemoved: to: self;		
		when: MethodAdded,
			MethodModified ,
			MethodRemoved send: #methodModified: to: self.
					
	MCWorkingCopy addDependent: self.

]

{ #category : #actions }
MBConfigurationRoot >> removeConfigurationInfo: aConfigurationInfo [

	aConfigurationInfo release.
	self configurations remove: aConfigurationInfo ifAbsent: [].
	self announcer announce: MBConfigurationInfoDeleted
]

{ #category : #updating }
MBConfigurationRoot >> respondToEventFor: aConfigurationClass withOperation: operation [
	"Events generated by SystemChangeNotifier and involve edits to the configuration itself."

	| info |
	operation == #added
		ifTrue: [ ^self addConfigurationInfoFor: aConfigurationClass ].
	(info := self configurationInfoFor: aConfigurationClass) isNil
		ifTrue: [ ^ self ].
	operation == #removed
		ifTrue: [ ^self removeConfigurationInfo: info ].
	"operation == #modified...configuration specs potentially modified"
	info configurationClassModified.
	self configurations do: [ :configInfo | configInfo recalculateIfInterestedInConfigurationInfo: info for: operation ]
]

{ #category : #updating }
MBConfigurationRoot >> unregister [
	"Unregister from the dependent object. Typically used when closing the browser"
	
	SystemAnnouncer uniqueInstance unsubscribe: self.
	MCWorkingCopy removeDependent: self.

]

{ #category : #updating }
MBConfigurationRoot >> update: anArrayOrSymbol [
	"A package has been modified (loaded, removed, or updated). Find out if any configurations are managing the package.
	Update events are coming from MCWorkingCopy."

	| packageName operation |
	anArrayOrSymbol isArray
		ifFalse: [ ^ self ].
	operation := anArrayOrSymbol at: 1.
	operation == #modified
		ifTrue: [ packageName := (anArrayOrSymbol at: 2) packageName ].
	operation == #registered
		ifTrue: [ packageName := (anArrayOrSymbol at: 2) name ].
	operation == #unregistered
		ifTrue: [ packageName := (anArrayOrSymbol at: 2) name ].
	(packageName beginsWith: 'ConfigurationOf')
		ifTrue: [ 
			| wc info |
			operation ~~ #modified
				ifTrue: [ ^ self ].	"only interested in modified"
			wc := anArrayOrSymbol at: 2.
			wc modified
				ifTrue: [ ^ self ].	"only interested in transtion from modified to not modified"
			(info := self configurationInfoFor: (Smalltalk at: packageName asSymbol ifAbsent: [ ^ self ])) isNil
				ifTrue: [ ^ self ].	
			"removed and added packages handled by the add/removal of the class"
			info configurationClassModified.
			^ self ].
	self configurations do: [ :info | info recalculateIfInterestedInPackageNamed: packageName for: operation ]
]

{ #category : #accessing }
MBConfigurationRoot >> username [
	^ username
]

{ #category : #accessing }
MBConfigurationRoot >> username: anObject [
	username := anObject
]