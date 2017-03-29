###

Materia
It's a thing

Widget  : Matching, Creator
Authors : Jonathan Warner, Micheal Parks
Updated : 6/14

###

# Create an angular module to import the animation module and house our controller.
MatchingCreator = angular.module( 'matchingCreator', ['ngAnimate'] )

MatchingCreator.directive('ngEnter', ->
    return (scope, element, attrs) ->
        element.bind("keydown keypress", (event) ->
            if(event.which == 13)
                scope.$apply ->
                    scope.$eval(attrs.ngEnter)
                event.preventDefault()
        )
)
MatchingCreator.directive('focusMe', ['$timeout', '$parse', ($timeout, $parse) ->
	link: (scope, element, attrs) ->
		model = $parse(attrs.focusMe)
		scope.$watch model, (value) ->
			if value
				$timeout ->
					element[0].focus()
			value
])

# Set the controller for the scope of the document body.
MatchingCreator.controller 'matchingCreatorCtrl', ['$scope', '$sce', ($scope, $sce) ->
	# Stores data to be gathered on save.
	$scope.widget =
		title     : "My Matching widget"
		wordPairs : []
		media     : []

	$scope.acceptedMediaTypes = ['mp3']

	audioRef      = []

	# Adds and removes a pair of textareas for users to input a word pair.
	$scope.addWordPair = (q=null, a=null, type=null, id='') ->
		$scope.widget.wordPairs.push {question:q,answer:a,id:id}

	$scope.removeWordPair = (index) -> 
		$scope.widget.wordPairs.splice(index, 1)
		$scope.widget.media.splice(index, 1)

	# Public methods
	$scope.initNewWidget = (widget, baseUrl) ->
		$scope.$apply ->
			$scope.showIntroDialog = true

	$scope.initExistingWidget = (title, widget, qset, version, baseUrl) ->
		_items = qset.items[0].items
		$scope.$apply ->
			$scope.widget.title     = title
			$scope.widget.wordPairs = []
			$scope.addWordPair( _items[i].questions[0].text, _items[i].answers[0].text ) for i in [0.._items.length-1]

	$scope.onSaveClicked = (mode = 'save') ->
		if $scope.widget.title
			Materia.CreatorCore.save $scope.widget.title, _buildSaveData()
		else Materia.CreatorCore.cancelSave 'Widget not ready to save.'

	$scope.onSaveComplete = (title, widget, qset, version) -> true

	$scope.onQuestionImportComplete = (questions) ->
		$scope.$apply -> $scope.addWordPair(question.questions[0].text, question.answers[0].text, question.id) for question in questions

	$scope.beginMediaImport = (index, which) ->
		Materia.CreatorCore.showMediaImporter($scope.acceptedMediaTypes)

		audioRef[0] = index
		audioRef[1] = which

	$scope.onMediaImportComplete = (media) ->
		# use $sce.trustAsResourceUrl to avoid interpolation error
		url = $sce.trustAsResourceUrl(Materia.CreatorCore.getMediaUrl media[0].id + ".mp3")
		# adds placeholders in the media array
		add_placeholders = -> 
			if $scope.widget.media.length < audioRef[0]+1
				$scope.widget.media.push [0,0]

		from = $scope.widget.media.length
		to = audioRef[0]
		add_placeholders() for from in [from..to]

		$scope.widget.media[audioRef[0]].splice(audioRef[1], 1, url)
		$scope.$apply -> true

		#Load all audio tags
		audioTags = document.getElementsByTagName("audio")
		audioAmount = audioTags.length
		count = 0
		for count in [0..audioAmount]
			audioTags[count].load()

	$scope.mediaSource = (index, which) ->
		return $scope.widget.media[index][which]

	$scope.checkMedia = (index, which) ->
		if $scope.widget.media[index] == undefined
			return false
		else
			return $scope.widget.media[index][which] != 0

	# View actions
	$scope.setTitle = ->
		$scope.widget.title = $scope.introTitle or $scope.widget.title
		$scope.step = 1
		$scope.hideCover()

	$scope.hideCover = ->
		$scope.showTitleDialog = $scope.showIntroDialog = false
	
	$scope.autoSize = (pair) ->
		question = pair.question or ''
		answer = pair.answer or ''
		len = if question.length > answer.length then question.length else answer.length
		size = if len > 15 then 30 + len * 1.1 else 25

		height: size + 'px'

	# Private methods
	_buildSaveData = ->
		if $scope.widget.media.length < $scope.widget.wordPairs.length
			$scope.widget.media.push [0,0]

		items      = []
		wordPairs  = $scope.widget.wordPairs
		items.push( _process(wordPairs[i], $scope.widget.media[i]) ) for i in [0..wordPairs.length-1]

		options : {}
		assets  : []
		rand    : false
		name    : ''
		items   : [
			items: items
		]

	# Get each pair's data from the controller and organize it into Qset form.
	_process = (wordPair) ->
		questions: [
			text  : wordPair.question
		]
		answers  : [
			text  : wordPair.answer,
			value : '100',
			id    : ''
		]
		type     : 'QA'
		id       : wordPair.id
		assets   : []

	Materia.CreatorCore.start $scope
]

