
	| remove |
	"save and restart image here"
	SessionManager default unregisterClassNamed: #GTSpotterEventRecorderSettings.
	SessionManager default unregisterClassNamed: #FFICallbackThunk.
	SessionManager default unregisterClassNamed: #Alien.
	(Smalltalk classNamed: #AlienWeakTable)
		allInstancesDo: [ :table | WeakArray removeWeakDependent: table ].
	WeakArray removeWeakDependent: (Smalltalk classNamed: #Callback).
	remove := #('Athens-Cairo' 'NativeBoost-Tests' 'NativeBoost-Examples' 'NativeBoost-Unix' 'NativeBoost-Win32' 'NativeBoost-Mac' 'NativeBoost-Core' 'NativeBoost-Pools' 'AsmJit-Tests' 'AsmJit-StackManagement' 'AsmJit-Operands' 'AsmJit-x86' 'AsmJit-Extension' 'AsmJit-Instructions' 'AsmJit-Core' 'Alien' 'FFI-MacOS' 'FFI-Tests' 'FFI-Unix' 'FFI-Win32').
	remove
		do: [ :packageName | (MCWorkingCopy forPackage: (MCPackage named: packageName)) unload ].
	Smalltalk recreateSpecialObjectsArray.
	Context initializePrimitiveSimulators.
	SmalltalkImage current fixObsoleteReferences.
	Behavior flushObsoleteSubclasses.
	Smalltalk garbageCollect

!

	3 timesRepeat: [ SmalltalkImage current fixObsoleteReferences.
			Behavior flushObsoleteSubclasses.
			Smalltalk garbageCollect ]

!


	SystemAnnouncer uniqueInstance unsubscribe: TestCase. 
	RBProgramNode resetFormatter.

!

	[ | tests keep o ordered notResolved foundDeps deps depsList resolveBlock hasResolved delete cyclic notResolvedNames sortedByDeps unloadFirst array bootstrappedPackages |
	[ World submorphs do: #delete.
	100
		timesRepeat: [ 10 milliSecond wait.
			World doOneCycle.
			Processor yield ].
	3 timesRepeat: [ Smalltalk garbageCollect ].
	UIManager default terminateUIProcess.

	" clean processes"
	(Process allInstances
		reject: [ :process | 
			{(InputEventFetcher default instVarNamed: #fetcherProcess).
			Processor activeProcess.
			WeakArray runningFinalizationProcess.
			Smalltalk lowSpaceWatcherProcess.
			Processor backgroundProcess} includes: process ])
		do: [ :process | 
			process suspend.
			process terminate ].
	Delay restartTimerEventLoop.

	"(Smalltalk at: #GTExampleOrganizer) stop.
    (Smalltalk at: #GTExampleOrganizer) compile: 'methodRemoved: anAnnouncement'."
	(Smalltalk at: #GLMBrick) removeFromSystem.
	tests := #('AST-Interpreter-Test' 'AST-Tests-Core' 'Announcements-Tests-Core' 'AsmJit-Tests' 'ClassOrganizer-Tests' 'ConfigurationCommandLineHandler-Tests' 'FileSystem-Tests-Core' 'FileSystem-Tests-Disk' 'FileSystem-Tests-Memory' 'Gofer-Tests' 'Graphics-Tests' 'HelpSystem-Tests' 'Keymapping-Tests' 'Manifest-Resources-Tests' 'Manifest-Tests' 'Metacello-TestsCore' 'Metacello-TestsMC' 'Metacello-TestsMCCore' 'Metacello-TestsMCResources' 'Metacello-TestsPharo20MC' 'Metacello-TestsPlatform' 'Metacello-TestsTutorial' 'Multilingual-Tests' 'NativeBoost-Tests' 'OpalCompiler-Tests' 'ProfStef-Tests' 'RPackage-Tests' 'Refactoring-Tests-Changes' 'Refactoring-Tests-Core' 'Refactoring-Tests-Critics' 'Refactoring-Tests-Environment' 'Regex-Tests-Core' 'Ring-Tests-Containers' 'Ring-Tests-Kernel' 'Ring-Tests-Monticello' 'System-SessionManager-Tests' 'SUnit-Tests' 'SUnit-UITesting' 'Spec-Tests' 'Text-Tests' 'UpdateStreamer-Tests' 'Zinc-Character-Encoding-Tests' 'Zinc-Resource-Meta-Tests' 'Zinc-Tests' 'Zodiac-Tests' 'FuelTests' 'KernelTests' 'MorphicTests' 'NetworkTests' 'ShoutTests' 'SlotTests' 'Tests' 'BalloonTests' 'CollectionsTests' 'CompressionTests' #'Debugger-Tests' 'EmbeddedFreeType-Tests' 'FontInfrastructure-Tests' 'FreeTypeTests' 'Graphics-Fonts-Tests' 'Monticello-Tests' 'NECompletion-Tests' 'Nautilus-Tests' 'Reflectivity-Tests' 'ReleaseTests' #'ScriptLoader-Tests' 'Slot-Tests' 'SmartSuggestions-Tests' 'System-CachingTests' 'System-History-Tests' 'System-Localization-Tests' 'Text-Edition-Tests' 'Tool-FileList-Tests' 'ToolsTest' 'UserManager-Tests' 'Versionner-Tests-Core-Commands' 'Versionner-Tests-Core-DependenciesModel' 'Versionner-Tests-Resources').
	unloadFirst := #('QualityAssistantRecording' 'QualityAssistant' 'GT-Debugger').
	bootstrappedPackages := BaselineOfPharoBootstrap kernelPackageNames , BaselineOfPharoBootstrap compilerPackageNames , BaselineOfPharoBootstrap fileSystemPackageNames
		, BaselineOfMonticello corePackageNames.
	keep := bootstrappedPackages.

	" clean "
	MetacelloProjectRegistration resetRegistry.
	SystemAnnouncer uniqueInstance unsubscribe: EpMonitor current.
	Job jobAnnouncer unsubscribe: EpMonitor current.
	SystemAnnouncer uniqueInstance unsubscribe: Breakpoint.
	KMRepository reset.
	KMPragmaKeymapBuilder release.
	PragmaCollector allInstances do: [ :pc | pc announcer subscriptions reset ].
	RecentMessageList stopNotifications.
	NOCCompletionTable reset.
	SystemAnnouncer uniqueInstance unsubscribe: NOCCompletionTable.
	MCWorkingCopyBrowser allInstances do: [ :mcwcb | SystemAnnouncer uniqueInstance unsubscribe: mcwcb ].
	ZnNetworkingUtils default secureSocketStreamClass: nil.
	ZnNetworkingUtils default socketStreamClass: SocketStream.
	TextConstants TextSharedInformation removeKey: #DefaultTextStyle.
	TextConstants TextSharedInformation removeKey: #DefaultMultiStyle.
	TextConstants TextSharedInformation removeKey: #DefaultFixedTextStyle.
	TextConstants TextSharedInformation removeKey: (Smalltalk classNamed: #StrikeFont) defaultFontKey.
	Smalltalk allClasses select: [ :c | c sharedPools includes: TextConstants ] thenDo: [ :c | c compileAll ].

	" change UI manager"
	UIManager default: DummyUIManager new.
	Stdio stdout
		nextPutAll: 'Removing tests...';
		lf.
	tests
		withIndexDo: [ :packageName :index | 
			| wc |
			wc := MCWorkingCopy forPackage: (MCPackage named: packageName).
			Stdio stdout
				nextPutAll: index asString , '/' , tests size asString , ' - unloading ' , wc packageName;
				lf.
			wc unload ].
	unloadFirst
		withIndexDo: [ :packageName :index | 
			| wc |
			wc := MCWorkingCopy forPackage: (MCPackage named: packageName).
			Stdio stdout
				nextPutAll: index asString , '/' , tests size asString , ' - unloading ' , wc packageName;
				lf.
			wc unload ].


	" count unloading order and select packages with cyclic dependencies "
	cyclic := OrderedCollection new.
	[ deps := Dictionary new.
	(MCWorkingCopy allManagers collect: #packageName)
		do: [ :packageName | 
			| package |
			package := RPackageSet named: packageName.
			deps at: packageName put: (package extensionMethods groupedBy: [ :m | (Smalltalk classOrTraitNamed: m className) package packageName ]) keys ].
	depsList := deps associations asOrderedCollection.
	resolveBlock := [ :a | a value isEmpty or: [ keep , cyclic includes: a key ] ].
	hasResolved := depsList select: resolveBlock.
	notResolved := depsList reject: resolveBlock.
	ordered := hasResolved collect: #key.
	[ foundDeps := notResolved select: [ :a | ordered includesAll: a value ].
	foundDeps removeAllSuchThat: [ :a | ((notResolved copyWithoutAll: foundDeps) gather: #value) asSet includes: a key ].
	notResolved := notResolved copyWithoutAll: foundDeps.
	ordered addAll: (foundDeps collect: #key).
	foundDeps isEmpty ] whileFalse.
	notResolvedNames := notResolved collect: [ :a | a key ].
	sortedByDeps := (notResolved collect: [ :a | a key -> (notResolved select: [ :b | b value includes: a key ]) size ])
		asSortedCollection: [ :a :b | a value <= b value ].
	sortedByDeps ifNotEmpty: [ cyclic add: sortedByDeps last key ].
	notResolvedNames isEmpty ] whileFalse.

	" sort packages with cyclic dependencies by count of dependencies "
	notResolvedNames := notResolved collect: [ :a | a key ].
	sortedByDeps := (notResolved collect: [ :a | a key -> (notResolved select: [ :b | b value includes: a key ]) size ])
		asSortedCollection: [ :a :b | a value <= b value ].

	" remove extension methods of packages with cyclic dependencies manually "
	Stdio stdout
		lf;
		nextPutAll: 'Removing messages...';
		lf.
	cyclic
		do: [ :pn | 
			(RPackageSet named: pn) extensionMethods
				do: [ :m | 
					(Smalltalk classOrTraitNamed: m className) removeSelector: m name ] ].
	Stdio stdout
		lf;
		nextPutAll: 'Removing regular packages...';
		lf.

	" move packages with cyclic dependencies at the end of ordered list "
	ordered := (ordered copyWithoutAll: cyclic) , cyclic reversed.

	" select packages to delete, keep counted order "
	delete := ordered copyWithoutAll: keep.

	" unload packages "
	delete
		withIndexDo: [ :packageName :index | 
			| wc |
			wc := MCWorkingCopy forPackage: (MCPackage named: packageName).
			Stdio stdout
				nextPutAll: index asString , '/' , delete size asString , ' - unloading ' , packageName;
				lf.
			wc unload ].
	Stdio stdout
		nextPutAll: 'Cleaning...';
		lf.

	" clean Morphic globals "
	#(ActiveEvent World ActiveWorld ActiveHand)
		do: [ :sym | 
			Smalltalk at: sym put: nil.
			Smalltalk removeKey: sym ].

	" Monticello still keeps some classes (why???), remove them manually "
	o := Smalltalk globals associations select: [ :a | a value isClass ].
	o := o select: [ :a | a value package name = '_UnpackagedPackage' ].
	o := o collect: #key.
	o
		do: [ :cn | 
			Stdio stdout
				nextPutAll: 'redelete ' , cn;
				lf.
			(Smalltalk globals at: cn) removeFromSystem ].

	" final cleaning "
	ChangeSet removeChangeSetsNamedSuchThat: [ :each | true ].
	ChangeSet resetCurrentToNewUnnamedChangeSet.
	Author reset.
	SmalltalkImage classPool at: #Tools put: nil.
	Job jobAnnouncer initialize.
	EncodedCharSet initialize.
	LanguageEnvironment resetKnownEnvironments.
	RPackageOrganizer resetDefault.
	bootstrappedPackages do: [ :packageName | RPackageOrganizer default registerPackageNamed: packageName ].
	(Smalltalk at: #Display) becomeForward: nil.
	Smalltalk removeKey: #Display.
	MCWorkingCopy allInstances do: [ :wc | wc repositoryGroup: nil ].
	Smalltalk removeKey: #Sensor.
	MCRepositoryGroup instVarNamed: #default put: nil.

	"((Array allInstances select: [ :i | i size = 1024 ])
 	    detect: [ :a | a second = SmallInteger  ])  at: 54 put: nil."


	"remove obsolete bitmap"
	array := Smalltalk specialObjectsArray copy.
	array at: 5 put: nil.
	Smalltalk specialObjectsArray becomeForward: array.
	ClassOrganization allInstancesDo: [ :org | org removeEmptyCategories ].
	SystemOrganization removeEmptyCategories.


	" clean object memory, maybe can be simpler"
	3 timesRepeat: [ Smalltalk garbageCollect ].
	Smalltalk globals flushClassNameCache.
	3
		timesRepeat: [ Smalltalk garbageCollect.
			Symbol compactSymbolTable ].
	HashedCollection rehashAll.
	SmalltalkImage current fixObsoleteReferences.
	3 timesRepeat: [ Smalltalk garbageCollect ].
	UIManager default progressBarEnabled: true.
	MCPackageManager allSubInstancesDo: [ :p | p unregister ].
	SystemAnnouncer uniqueInstance unsubscribe: MCWorkingCopy.
	delete := #('RingChunkImporter' 'Zinc-Resource-Meta-Core' 'System-Changes' 'Ring-Core-Kernel' 'Ring-Core-Containers' 'RingChunkImporter' 'Compression' 'Monticello' 'Ring-Monticello').
	delete
		do: [ :packageName | 
			| mcPackage classes |
			mcPackage := packageName asPackage.
			mcPackage extensionMethods do: #removeFromSystem.
			classes := mcPackage definedClasses.
			classes do: #removeFromSystem ].
	SystemAnnouncer reset.
	ChangesLog reset default.	"subscribe to SystemAnnouncer"
	WeakArray restartFinalizationProcess.
	[ | obsoleteBitmap bad |
	Undeclared removeUnreferencedKeys.
	array := Smalltalk specialObjectsArray copy.
	array at: 5 put: nil.
	Smalltalk specialObjectsArray becomeForward: array.
	obsoleteBitmap := SystemNavigation default obsoleteClasses detect: [ :c | c name = #AnObsoleteBitmap ].
	(Behavior classPool at: #ClassProperties) removeKey: obsoleteBitmap.
	(Behavior classPool at: #ObsoleteSubclasses) at: ArrayedCollection put: (WeakArray ofSize: 3).
	obsoleteBitmap instVarNamed: #layout put: nil.
	3 timesRepeat: [ Smalltalk garbageCollect ].
	obsoleteBitmap class becomeForward: nil.
	bad := Set allSubInstances select: [ :badSet | badSet isHealthy not ].
	bad do: #rehash.
	bad := Dictionary allSubInstances select: [ :dict | dict isHealthy not ].
	bad do: #rehash.
	Smalltalk image recompile.
	3 timesRepeat: [ Smalltalk garbageCollect ].
	Smalltalk globals flushClassNameCache.
	3
		timesRepeat: [ Smalltalk garbageCollect.
			Symbol compactSymbolTable ].
	HashedCollection rehashAll.
	SmalltalkImage current fixObsoleteReferences.
	3 timesRepeat: [ Smalltalk garbageCollect ] ] value.
	Stdio stdout
		nextPutAll: 'DONE';
		lf.
	Smalltalk saveImageInNewContext ]
		ifError: [ :e | 
			| rep |
			rep := Stdio stderr.
			rep
				nextPutAll: 'Error:';
				cr.
			rep
				nextPutAll: e asString;
				cr.
			rep nextPutAll: thisContext stack size asString.
			thisContext stack copy
				withIndexDo: [ :stck :i | 
					[ rep
						nextPutAll: i asString;
						space;
						nextPutAll: stck asString;
						cr ] ifError: [  ] ].
			rep close.
			Smalltalk exitFailure ] ] fork