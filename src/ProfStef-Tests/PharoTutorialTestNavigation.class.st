"
SUnit tests for tutorial navigation
"
Class {
	#name : #PharoTutorialTestNavigation,
	#superclass : #TestCase,
	#instVars : [
		'prof',
		'mockView'
	],
	#category : #'ProfStef-Tests-Tests'
}

{ #category : #running }
PharoTutorialTestNavigation >> setUp [
	prof := ProfStef new.
	prof player: (
		TutorialPlayer new 
			tutorial: MockTutorial new; 
			yourself).
	mockView := MockLessonView new.
	prof lessonView: mockView.
	prof open.
]

{ #category : #tests }
PharoTutorialTestNavigation >> testNextOpenSecondLesson [
	prof next.
	self assert: mockView title equals: 'second (2/3)'.
	self assert: mockView lesson lesson equals: 'Second lesson'.
]

{ #category : #tests }
PharoTutorialTestNavigation >> testSequenceNextNextOpenThirdLesson [
	prof next; next.
	self assert: mockView title equals: 'third (3/3)'.
	self assert: mockView lesson lesson equals: 'Third lesson'.
]

{ #category : #tests }
PharoTutorialTestNavigation >> testSequenceNextNextPreviousOpenSecondLesson [
	prof next; next; previous.
	self assert: mockView title equals: 'second (2/3)'.
	self assert: mockView lesson lesson equals: 'Second lesson'.
]

{ #category : #tests }
PharoTutorialTestNavigation >> testShowFirstLessonOnGo [
	| lesson |
	lesson := mockView lesson.
	self assert: lesson title equals: 'first'.
	self assert: lesson lesson equals: 'First lesson'.
]

{ #category : #tests }
PharoTutorialTestNavigation >> testShowingLessonByIndex [
	prof tutorial: MockTutorial lessonAt: 2.
	self assert: mockView title equals: 'second (2/3)'.
	self assert: mockView lesson lesson equals: 'Second lesson'.
]

{ #category : #tests }
PharoTutorialTestNavigation >> testShowingLessonBySelector [
	prof tutorial: MockTutorial lesson: #firstLesson.
	self assert: mockView title equals: 'first (1/3)'.
	self assert: mockView lesson lesson equals: 'First lesson'.
]