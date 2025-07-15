const publicationName = 'webclient'

var activeTab
var favoriteReports
var idNavLink = new Map()
var countersUpdateDate
var openedTools = new Map()
var timeoutID
var toolsData
var userID
var version
var webClient = null

var webClientURL = new URL(publicationName, window.location.origin)
webClientURL.hash = location.hash
webClientURL.search = location.search

if (location.hash || location.search) {
	window.history.replaceState({}, document.title, window.location.pathname)
}

var init = function () {
	webClient = new WebClient1CE('webClientContainer', {
		webClientURL: webClientURL.href,
		events: {
			onMessage: onWebClientMessage,
			onStart: onStartWebClient,
			onEnd: onEndWebClient,
		},
	})
	setDraggable(menuLinks)
	setDraggable(reportsList)

	createTooltip()
	fillEventListeners()
	restorePanelCollapseState()
}

var setDraggable = function (list) {
	Sortable.create(list, {
		forceFallback: true,
		direction: 'vertical',
		draggable: '.nav-link',
		delay: 100,
		touchStartThreshold: 3,
		onChoose: () => {
			document.body.classList.add('grabbing')
			toolsListsArea.classList.add('toolGrabbing')
			hideTip()
		},
		onUnchoose: () => {
			document.body.classList.remove('grabbing')
			toolsListsArea.classList.remove('toolGrabbing')
		},
		onUpdate: event => {
			if (event.oldIndex != event.newIndex) {
				let toolID = event.item.id.split('_')[1]
				messageToWebClient({
					event: 'favoriteOnUpdateOrder',
					id: toolID,
					report: toolsData.get(toolID).report,
					oldIndex: event.oldIndex,
					newIndex: event.newIndex,
				})
			}
		},
	})
}

var onWebClientMessage = function (message, origin) {
	if (origin === window.location.origin) {
		let messageData = JSON.parse(message)

		switch (messageData.method) {
			case 'updateCounters':
				updateCounters(messageData.data)
				break
			case 'startClient':
				if (!version) {
					version = messageData.version
				} else if (version != messageData.version) {
					messageToWebClient({ event: 'closeClient' })

					setTimeout(() => {
						window.location.reload()
					}, 1)
				}

				initData(messageData.idNavLink, messageData.activeTab, messageData.userGUID)
				fillToolsList(messageData.tools)
				startCountersFilling()
				addStyles(messageData.styles)
				break
			case 'setToolWindowID':
				messageData.data.forEach(tool => {
					idNavLink.set(tool.id, tool.navLink)

					if (tool.id == activeTab) {
						refreshSelectedTool(tool.navLink)
					}
				})
				break
			case 'startUpdateAnimation':
				createUpdateOverlay(messageData.page, messageData.tableName, messageData.id)
				break
			case 'endUpdateAnimation':
				deleteUpdateOverlay(messageData.tableName, messageData.id)
				break
		}
	}
}

var onStartWebClient = function () {
	webClient.g.webClientURL = `${window.location.origin}/${publicationName}/`
	panel.style.visibility = 'visible'
	sidebar.classList.add('webClientStarted')
	window.webClientWindow = webClient.h.contentWindow
	let styleSheet = webClientWindow.document.styleSheets[1].ownerNode.sheet
	webClientWindow.document.addEventListener(
		'click',
		e => {
			let Popper = PoppersInstance.subMenuPoppers[0]
			Popper.clicker(e, Popper.popperTarget, Popper.reference)
		},
		false
	)

	var targetNode = webClientWindow.document.querySelector('#LogoutArea .ecsAvatar')
	var observerLogoutArea = new MutationObserver(function () {
		if (targetNode.style.display != 'none') {
			changeAvatar()
		}
	})
	observerLogoutArea.observe(targetNode, { attributes: true, childList: true })

	styleSheet.insertRule(`
		div#openedpanel_popup_submenu > div.frameSubmenu > div.submenu:has(div#openFixedFormFix),
		div#openedpanel_popup_submenu > div.frameSubmenu > div.submenu:has(div#popupItem3.submenuBlockDisabled),
		div#openedpanel_popup_submenu > div.frameSubmenu > div.submenu:has(#popupItem5.submenuBlockDisabled),
		div#topline_popup_submenu > div.frameSubmenu > div.submenu:has(div#openFixedFormVer),
		div#topline_popup_submenu > div.frameSubmenu > div.submenu:has(div#popupItem5.submenuBlock),
		div#topline_popup_submenu > div.frameSubmenu > div.submenu:has(div#popupItem6.submenuBlock),
		div#ServiceButton_submenu > div.frameSubmenu > div.submenu > div#customizeDesktopButton,
		div#ServiceButton_submenu > div.frameSubmenu > div.submenu > div#customizeTopLevelButton,
		div#pePanelsArea > div#peP1,
		div#pePanelsArea > div#peP2,
		div#pePanelsArea > div#peP4,
		div#WindowBand_submenu > div.frameSubmenu > div.submenu:has(div#openFixedFormVer),
		div#WindowBand_submenu > div.frameSubmenu > div.submenu:has(div#popupItem2.submenuBlock),
		div#WindowBand_submenu > div.frameSubmenu > div.submenu:has(div#popupItem6.submenuBlock),
		div.fixer {
			display: none !important
		}`)

	let captionbarField = webClientWindow.document.getElementById('captionbarField')
	captionbarField.style.backgroundColor = '#F7F7F7'
	captionbarField.style.borderRadius = '8px'
	captionbarField.style.padding = '0 8px'

	var rules = styleSheet.rules

	for (var i = 0; i < rules.length; i++) {
		var rule = rules[i]

		if (rule.selectorText === '.pressDefault') {
			// Устанавливаем цвет текста кнопки по умолчанию
			rule.style.setProperty('color', '#fff')
		} else if (rule.selectorText === '.select.openedItem::before') {
			// Устанавливаем цвет фона активной вкладки
			rule.style.setProperty('background', '#0597fd')
		} else if (rule.selectorText === '.focusFrame') {
			// Устанавливаем цвет фона рамки активного поля
			rule.style.setProperty('background-color', '#6c9')
		} else if (rule.selectorText === '.focus.select.gridLine::after, .focus.gridBox .gridBoxTitle') {
			// Устанавливаем цвет фона рамки активной строки таблицы
			rule.style.setProperty('border-color', '#6c9')
		} else if (rule.selectorText === '.focus.select.gridLine::after') {
			rule.style.setProperty('border-radius', '3px')
			rule.style.setProperty('border-width', '1px')
		} else if (rule.selectorText === '.focus.gridBox .gridBoxTitle::before') {
			// Устанавливаем цвет фона рамки активной строки таблицы
			rule.style.setProperty('border-width', '1px')
			rule.style.setProperty('border-radius', '4px')
		} else if (rule.selectorText === '.staticTextHyperBorder') {
			// Скрываем выделение пунктиром активной гиперссылки
			rule.style.setProperty('outline-width', '0px')
		} else if (rule.selectorText === '.extTooltip') {
			// Устанавливаем свойства окна подсказки
			rule.style.setProperty('border', '1px solid #f0d56f')
			rule.style.setProperty('border-radius', '8px')
			rule.style.setProperty('background-color', '#ffffe9')
		} else if (rule.selectorText === '.balloon') {
			// Устанавливаем свойства окна предупреждения
			rule.style.setProperty('background', '#ffefef')
			rule.style.setProperty('border-radius', '8px')
			rule.style.setProperty('border', '1px solid #fec2c2')
			rule.style.setProperty('color', '#ff5c52')
		} else if (rule.selectorText === '.balloonCorner') {
			// Скрываем треугольник к полю ввода, к которому выводится предупреждение
			rule.style.setProperty('border-style', 'none')
		}
	}

	styleSheet.insertRule(`
		div.captionbar > div.captionbarTitle,
		div.captionbar > div.captionbar1C > div#captionbar1C,
		div.captionbar > div.captionbarIco > a#captionbarLogo,
		div.captionbar > div.captionbarIco > a#captionbarFunction {
			display: none;
		}
	`)

	styleSheet.insertRule('.captionbar.ePrimaryBack { background-color: #fff; }')

	addToolUpdateOverlayStyles(styleSheet)

	var openedCell = webClientWindow.openedCell
	const pattern = /^openedCell_cmd_([a-f0-9-]{36}|HOME|ECS)$/i

	observer = new MutationObserver(function (mutationsList) {
		let unknownTools = []

		mutationsList.forEach(mutation => {
			let toolCheck = mutation.target.id.match(pattern)
			if (toolCheck) {
				let toolID = toolCheck[1]
				let toolNavLink = idNavLink.get(toolID)
				let tabSelected = mutation.target.classList.contains('select')

				if (tabSelected && activeTab != toolID) {
					let previousActiveTab = openedTools.get(idNavLink.get(activeTab))
					if (previousActiveTab) {
						previousActiveTab.classList.remove('opened')
					}
					updateToolData(toolID)
				}

				if (toolNavLink == null) {
					unknownTools.push(toolID)
				} else if (tabSelected && activeTab != toolID) {
					refreshSelectedTool(toolNavLink)
				}

				if (tabSelected) {
					activeTab = toolID
				}
			}
		})

		if (unknownTools.length > 0) {
			messageToWebClient({
				event: 'getUnknownTools',
				unknownTools: unknownTools,
			})
		}
	})
	observer.observe(openedCell, { subtree: true, attributes: true })

	webClientWindow.document.addEventListener('visibilitychange', function () {
		if (document.visibilityState === 'visible') {
			let tabElement = openedCell.querySelector('.openedItem.select')
			if (tabElement) {
				let toolCheck = tabElement.id.match(pattern)
				if (toolCheck) {
					updateToolData(toolCheck[1])
				}
			}
			startCountersFilling()
		} else {
			endCountersFilling()
		}
	})
}

var refreshSelectedTool = function (toolNavLink) {
	let openedTool = openedTools.get(toolNavLink)

	if (openedTool) {
		openedTool.classList.add('opened')
	}
}

var onEndWebClient = function () {
	panel.style = ''
	sidebar.classList.remove('webClientStarted')
	endCountersFilling()
}

var messageToWebClient = function (data) {
	let message = JSON.stringify(data)
	webClient.postMessage(message)
}

var updateCounters = function (...data) {
	data.forEach(counterData => {
		let liElement = document.getElementById(`menuLinks_${counterData.id}`)

		if (liElement) {
			if (counterData.count == 0) {
				delete liElement.dataset.badge
			} else if (counterData.count > 99) {
				liElement.dataset.badge = '99+'
			} else {
				liElement.dataset.badge = counterData.count
			}
		}
	})
}

var addStyles = function (data) {
	let styleSheet = webClientWindow.document.styleSheets[1].ownerNode.sheet

	data.forEach(newRule => {
		styleSheet.insertRule(newRule, styleSheet.cssRules.length)
	})
}

var changeAvatar = function () {
	let cardBox = webClientWindow.document.querySelector('.cloudCard > .cardBox')
	let ecsAvatar = cardBox.querySelector('.ecsAvatar')
	let newAvatar = ecsAvatar.cloneNode(true)

	ecsAvatar.remove()
	cardBox.appendChild(newAvatar)
	newAvatar.parentNode.insertBefore(newAvatar, newAvatar.previousElementSibling)
	newAvatar.addEventListener(
		'click',
		function () {
			webClient.gotoURL('e1cib/command/ОбщаяКоманда.НастройкаАватараСистемыВзаимодействия')
		},
		false
	)
}

var fillToolsList = function (data) {
	toolsData = new Map()
	data.toolsData.forEach(toolData => {
		toolsData.set(toolData.id, toolData.data)
	})

	toolsLists.innerHTML = ''
	reportsListContent.innerHTML = ''

	let reportsIco = reports.querySelector(':scope > a > div')
	reportsIco.dataset.tooltip = 'Отчеты'
	reportsIco.addEventListener('mouseenter', showTip)
	reportsIco.addEventListener('mouseleave', hideTip)
	reportsIco.addEventListener('click', hideTip)

	let i = 0

	data.toolsList.forEach(toolGroup => {
		if (!toolGroup.fixed) {
			let ulElement = document.createElement('ul')

			i = 0
			toolGroup.tools.forEach(toolId => {
				let tool = toolsData.get(toolId)

				if (!toolGroup.reports || i++ < 6) {
					let navLinkElement = document.createElement('a')
					navLinkElement.onclick = menuLinkClick
					navLinkElement.innerHTML = tool.name
					let liElement = document.createElement('li')
					liElement.id = `toolsList_${toolId}`
					liElement.appendChild(navLinkElement)
					if (!toolGroup.reports && tool.quickAccess) {
						let favoriteIcon = document.createElement('div')
						favoriteIcon.className = 'favorite-icon'
						favoriteIcon.id = toolId
						favoriteIcon.onclick = favoriteIconClick
						if (tool.favorite) {
							favoriteIcon.classList.add('checked')
						}
						liElement.appendChild(favoriteIcon)
					}
					ulElement.appendChild(liElement)
				}

				if (toolGroup.reports) {
					let divElement = document.createElement('div')
					divElement.id = `reportsList_${toolId}`

					let inputElement = document.createElement('input')
					inputElement.type = 'checkbox'
					inputElement.id = toolId
					if (tool.favorite) {
						inputElement.checked = true
					}

					let labelElement = document.createElement('label')
					labelElement.htmlFor = toolId
					labelElement.innerText = tool.name

					let iconElement = document.createElement('div')
					iconElement.classList.add('openReport')
					iconElement.onclick = menuLinkClick

					divElement.appendChild(inputElement)
					divElement.appendChild(labelElement)
					divElement.appendChild(iconElement)
					reportsListContent.appendChild(divElement)
				}
			})

			if (toolGroup.reports) {
				let navLinkElement = document.createElement('a')
				navLinkElement.onclick = openReportsList
				navLinkElement.innerHTML = 'Все отчеты'

				let liElement = document.createElement('li')
				liElement.id = 'allReports'
				liElement.appendChild(navLinkElement)

				ulElement.appendChild(liElement)
			}

			let spanElement = document.createElement('span')
			spanElement.innerHTML = toolGroup.name

			let listTitleElement = document.createElement('div')
			listTitleElement.className = 'list-title'
			listTitleElement.innerHTML = toolGroup.icon
			listTitleElement.appendChild(spanElement)

			let toolsElement = document.createElement('div')
			toolsElement.className = 'tools'
			toolsElement.appendChild(ulElement)

			let toolsListElement = document.createElement('div')
			toolsListElement.append(listTitleElement, toolsElement)

			toolsLists.appendChild(toolsListElement)
		} else {
			fixedTools.innerHTML = ''
			toolGroup.tools.forEach(toolId => {
				let liElement = createMenuElement(toolId)
				fixedTools.appendChild(liElement)
			})
		}
	})

	menuLinks.innerHTML = ''
	data.favoriteTools.forEach(toolId => {
		let tool = toolsData.get(toolId)
		let liElement = createMenuElement(toolId, tool)
		menuLinks.appendChild(liElement)
	})

	reportsList.innerHTML = ''
	favoriteReports = data.favoriteReports
	favoriteReports.forEach(toolId => {
		let liElement = createMenuElement(toolId)
		reportsList.appendChild(liElement)
	})
}

var getActivePageID = function () {
	let elementID
	webClientWindow.pages_container.childNodes.forEach(element => {
		if (element.style.display != 'none') elementID = element.id
	})
	return elementID
}

var addToolUpdateOverlayStyles = function (styleSheet) {
	styleSheet.insertRule(`
		.updateToolOverlay {
			position: absolute;
			top: 0;
			left: 0;
			right: 0;
			bottom: 0;
			-webkit-backdrop-filter: blur(2px);
			backdrop-filter: blur(2px);
			display: flex;
			justify-content: center;
			align-items: center;
			z-index: 10;
			transition: opacity 0.2s ease-out;
			opacity: 0;
		}
	`)
	styleSheet.insertRule(`
		.updateToolOverlay > div {
			height: 100px;
			width: 100px;
			position: relative;
			margin: 0 auto;
			display: inline-block;
		}
	`)
	styleSheet.insertRule(`
		.updateToolOverlay > div > svg {
			height: 100%;
			width: 100%;
			animation: progressSpinner-rotate 2s linear infinite;
		}
	`)
	styleSheet.insertRule(`
		.updateToolOverlay > div > svg > circle {
			animation: progressSpinner-dash 1.5s ease-in-out infinite, progressSpinner-color 6s ease-in-out infinite;
			stroke-linecap: round;
		}
	`)
	styleSheet.insertRule(`
		@keyframes progressSpinner-rotate {
			100% {
				transform: rotate(360deg);
			}
		}
	`)
	styleSheet.insertRule(`
		@keyframes progressSpinner-dash {
			0% {
				stroke-dasharray: 1, 200;
				stroke-dashoffset: 0;
			}
			50% {
				stroke-dasharray: 89, 200;
				stroke-dashoffset: -35px;
			}
			100% {
				stroke-dasharray: 89, 200;
				stroke-dashoffset: -124px;
			}
		}
	`)
	styleSheet.insertRule(`
		@keyframes progressSpinner-color {
			100%, 0% {
				stroke: #ef4444;
			}
			40% {
				stroke: #3b82f6;
			}
			66% {
				stroke: #84cc16;
			}
			80%, 90% {
				stroke: #eab308;
			}
		}
	`)
}

var openReportsList = function () {
	reportsListArea.classList.add('opened')
}

var initData = function (data, activeTabId, userGUID) {
	idNavLink.clear()
	idNavLink.set('ECS', '')
	openedTools.clear()
	activeTab = activeTabId
	data.forEach(tool => {
		idNavLink.set(tool.id, tool.navLink)
	})
	updateToolData(activeTabId)
	countersUpdateDate = 0
	timeoutID = null
	userID = userGUID
}

var updateToolData = function (activeTabId) {
	let activePageID = getActivePageID()
	if (activePageID) {
		messageToWebClient({
			event: 'updateToolData',
			formID: activeTabId,
			elementID: activePageID,
		})
	}
}

var createMenuElement = function (toolID, tool) {
	if (!tool) {
		tool = toolsData.get(toolID)
	}

	let spanElement = document.createElement('span')
	spanElement.className = 'nav-text'
	spanElement.innerText = tool.quickAccessName ? tool.quickAccessName : tool.name

	let aElement = document.createElement('a')
	aElement.onclick = menuLinkClick

	let svgIcon = ''
	if (!tool.report) {
		svgIcon = tool.icon

		let divElement = document.createElement('div')
		divElement.dataset.tooltip = tool.quickAccessName ? tool.quickAccessName : tool.name
		divElement.innerHTML = svgIcon

		divElement.addEventListener('mouseenter', showTip)
		divElement.addEventListener('mouseleave', hideTip)

		aElement.appendChild(divElement)
	}

	aElement.appendChild(spanElement)

	let liElement = document.createElement('li')
	liElement.id = `menuLinks_${toolID}`
	liElement.className = 'nav-link'
	liElement.appendChild(aElement)

	if (!tool.report) {
		openedTools.set(tool.navLink, liElement)

		let activeToolNavLink = idNavLink.get(activeTab)
		if (activeToolNavLink == tool.navLink) {
			liElement.classList.add('opened')
		}
	}

	return liElement
}

var favoriteIconClick = function () {
	let tool = toolsData.get(this.id)
	let favoriteAdding = this.classList.toggle('checked')
	messageToWebClient({
		event: 'favoriteChange',
		id: this.id,
		favoriteAdding: favoriteAdding,
		report: tool.report,
	})

	let ulElement = tool.report ? reportsList : menuLinks

	if (favoriteAdding) {
		let liElement = createMenuElement(this.id, tool)
		ulElement.appendChild(liElement)

		if (tool.counter & !tool.report) {
			startCountersFilling(this.id)
		}
	} else {
		let liElement = document.getElementById(`menuLinks_${this.id}`)
		ulElement.removeChild(liElement)
		openedTools.delete(tool.navLink)
	}
}

var endCountersFilling = function () {
	if (timeoutID) {
		clearTimeout(timeoutID)
		timeoutID = null
	}
}

var startCountersFilling = function (toolID) {
	if (toolID) {
		updateCountersData(toolID)
	} else {
		timeoutID = null
		const now = new Date()

		let timeDiff = now.getTime() - countersUpdateDate
		if (timeDiff > 120000) {
			updateCountersData(null, now.getTime())
		} else {
			timeoutID = setTimeout(startCountersFilling, 120000 - timeDiff)
		}
	}
}

var updateCountersData = async function (tool, updateDate = 0) {
	const URLparams = new URLSearchParams({
		userID: userID,
	})

	if (tool) {
		URLparams.set('tool', tool)
	}

	const response = await fetch(`/services/hs/api/toolCounters?${URLparams}`, {
		method: 'GET',
		credentials: 'omit',
		headers: {
			'Content-Type': 'application/json',
		},
	})

	let toolCount = 0

	try {
		const data = await response.json()
		if (data.code == 0) {
			updateCounters(...data.data)

			if (updateDate) {
				countersUpdateDate = updateDate
			}

			toolCount = data.data.length
		}
		if (!timeoutID & toolCount > 0) {
			timeoutID = setTimeout(startCountersFilling, 120000)
		}
	} catch (error) {
		console.error(error)
	}
}

var menuLinkClick = function (event) {
	let elementParent = event.currentTarget.parentNode
	if (!elementParent.classList.contains('sub-menu')) {
		let navLink = toolsData.get(elementParent.id.split('_')[1]).navLink
		webClient.gotoURL(navLink)
		if (toolsListsArea.classList.contains('opened')) {
			toolsListsArea.classList.remove('opened')
			reportsListArea.classList.remove('opened')
			toolsListCollapseButton.classList.remove('close')
		}
	} else {
		elementParent.classList.toggle('open')
	}
}

var collapsePanel = function () {
	let panelClosed = panel.classList.toggle('close')
	PoppersInstance.closePoppers()
	updatePoppersTimeout()

	savePanelCollapseState(panelClosed)
}

var savePanelCollapseState = function (panelClosed) {
	localStorage.setItem('sdmsPanelClosed', panelClosed)
}

var restorePanelCollapseState = function () {
	let panelClosedState = localStorage.getItem('sdmsPanelClosed') != 'false'
	panel.classList.toggle('close', panelClosedState)
}

var collapseToolsList = function () {
	toolsListsArea.classList.toggle('opened')
	toolsListCollapseButton.classList.toggle('close')

	if (panel.classList.contains('close')) {
		PoppersInstance.closePoppers()
		updatePoppersTimeout()
	}
}

var createUpdateOverlay = function (page, tableName, toolID) {
	let updatedTable = webClientWindow.document.getElementById(page).querySelector(`[id^="form"][id$="_${tableName}"]`)

	if (updatedTable) {
		let overlayID = `updateToolOverlay_${tableName}_${toolID}`

		if (!webClientWindow.document.getElementById(overlayID)) {
			let circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle')
			circle.setAttribute('cx', '50')
			circle.setAttribute('cy', '50')
			circle.setAttribute('r', '20')
			circle.setAttribute('fill', 'none')
			circle.setAttribute('stroke-width', '2')
			circle.setAttribute('stroke-miterlimit', '10')
			circle.setAttribute('fill', 'none')

			let svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
			svg.setAttribute('viewBox', '25 25 50 50')
			svg.appendChild(circle)

			let spinnerWrapper = document.createElement('div')
			spinnerWrapper.appendChild(svg)

			let overlay = document.createElement('div')
			overlay.id = overlayID
			overlay.className = 'updateToolOverlay'
			overlay.appendChild(spinnerWrapper)

			updatedTable.appendChild(overlay)

			setTimeout(() => {
				overlay.style.opacity = 1
			}, 10)
		}
	}
}

var deleteUpdateOverlay = function (tableName, toolID) {
	let overlay = webClientWindow.document.getElementById(`updateToolOverlay_${tableName}_${toolID}`)
	if (overlay) {
		overlay.style.opacity = 0

		setTimeout(() => {
			overlay.parentNode.removeChild(overlay)
		}, 200)
	}
}

function showTip(event) {
	let element = event.currentTarget
	if (panel.classList.contains('close') && element.dataset.tooltip && !(reports.contains(element) && reports.classList.contains('open'))) {
		let elementRect = element.getBoundingClientRect()
		tooltip.style.left = `${elementRect.right + 15}px`
		tooltip.style.top = `${elementRect.top + elementRect.height / 2 - 10}px`

		tooltip.innerHTML = element.dataset.tooltip
		tooltip.classList.remove('hidden')
	}
}

function hideTip() {
	tooltip.classList.add('hidden')
}

function createTooltip() {
	let tooltip = document.createElement('div')
	tooltip.className = 'tooltip'
	tooltip.id = 'tooltip'

	document.body.append(tooltip)
}

function fillEventListeners() {
	document.getElementById('closeReportsList').addEventListener(
		'click',
		() => {
			reportsListContent.childNodes.forEach(element => {
				if (favoriteReports.includes(element.childNodes[0].id)) {
					element.childNodes[0].checked = true
				} else {
					element.childNodes[0].checked = false
				}
			})
			reportsListArea.classList.remove('opened')
		},
		false
	)

	document.getElementById('saveReports').addEventListener(
		'click',
		() => {
			reportsListContent.childNodes.forEach(element => {
				let reportId = element.childNodes[0].id
				let checked = element.childNodes[0].checked
				let favoriteIndex = favoriteReports.indexOf(reportId)
				let favorite = favoriteIndex >= 0

				if (checked != favorite) {
					if (checked && !favorite) {
						favoriteReports.push(reportId)

						let liElement = createMenuElement(reportId)
						reportsList.appendChild(liElement)
					} else {
						favoriteReports.splice(favoriteIndex, 1)

						let liElement = document.getElementById(`menuLinks_${reportId}`)
						reportsList.removeChild(liElement)
					}

					messageToWebClient({
						event: 'favoriteReportsChange',
						favoriteReports: favoriteReports,
					})
				}
			})
			reportsListArea.classList.remove('opened')
		},
		false
	)

	panelCollapseButton.addEventListener('click', collapsePanel, false)
	toolsListCollapseButton.addEventListener('click', collapseToolsList, false)
	document.addEventListener(
		'pointerup',
		event => {
			if ((toolsListsArea.classList.contains('opened') && toolsListsArea == event.target) || topPanel == event.target) {
				collapseToolsList()
			}
		},
		false
	)
	reports.querySelectorAll(':scope > a').forEach(element => {
		element.addEventListener('click', () => {
			if (panel.classList.contains('close')) {
				PoppersInstance.togglePopper(element.nextElementSibling)
			} else {
				const parentMenu = element.closest('.menu.open-current-submenu')
				if (parentMenu) parentMenu.querySelectorAll(':scope > ul > li.nav-link.sub-menu > a').forEach(el => window.getComputedStyle(el.nextElementSibling).display !== 'none' && slideUp(el.nextElementSibling))
				slideToggle(element.nextElementSibling)
			}
		})
	})

	window.PoppersInstance = new Poppers()
}
