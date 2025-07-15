const animationDuration = 300

class PopperObject {
	instance = null
	reference = null
	popperTarget = null

	constructor(reference, popperTarget) {
		this.init(reference, popperTarget)
	}

	init(reference, popperTarget) {
		this.reference = reference
		this.popperTarget = popperTarget
		this.instance = Popper.createPopper(this.reference, this.popperTarget, {
			placement: 'right',
			strategy: 'fixed',
			resize: true,
			modifiers: [
				{
					name: 'computeStyles',
					options: {
						adaptive: false,
					},
				},
				{
					name: 'flip',
					options: {
						fallbackPlacements: ['left', 'right'],
					},
				}
			],
		})

		document.addEventListener('click', e => this.clicker(e, this.popperTarget, this.reference), false)
		const ro = new ResizeObserver(() => {
			this.instance.update()
		})

		ro.observe(this.popperTarget)
		ro.observe(this.reference)
	}

	clicker(event, popperTarget, reference) {
		if (panel.classList.contains("close") && (!reference.contains(event.target) || popperTarget.contains(event.target))) {
			this.hide()
		}
	}

	hide() {
		this.instance.state.elements.popper.style.visibility = 'hidden'
		this.instance.state.elements.popper.parentNode.classList.remove('open')
	}
}

class Poppers {
	subMenuPoppers = []

	constructor() {
		this.init()
	}

	init() {
			this.subMenuPoppers.push(new PopperObject(reports, reports.lastElementChild))
			this.closePoppers()
	}

	togglePopper(target) {
		if (window.getComputedStyle(target).visibility === 'hidden')
			target.style.visibility = 'visible';
		else target.style.visibility = 'hidden'
	}

	updatePoppers() {
		this.subMenuPoppers.forEach(element => {
			element.instance.state.elements.popper.style.display = 'none'
			element.instance.update()
		})
	}

	closePoppers() {
		this.subMenuPoppers.forEach(element => {
			element.hide()
		})
	}
}

const slideUp = (target, duration = animationDuration) => {
	const { parentElement } = target
	parentElement.classList.remove('open')
	target.style.transitionProperty = 'height, margin, padding'
	target.style.transitionDuration = `${duration}ms`
	target.style.boxSizing = 'border-box'
	target.style.height = `${target.offsetHeight}px`
	target.offsetHeight
	target.style.overflow = 'hidden'
	target.style.height = 0
	target.style.paddingTop = 0
	target.style.paddingBottom = 0
	target.style.marginTop = 0
	target.style.marginBottom = 0
	window.setTimeout(() => {
		target.style.display = 'none'
		target.style.removeProperty('height')
		target.style.removeProperty('padding-top')
		target.style.removeProperty('padding-bottom')
		target.style.removeProperty('margin-top')
		target.style.removeProperty('margin-bottom')
		target.style.removeProperty('overflow')
		target.style.removeProperty('transition-duration')
		target.style.removeProperty('transition-property')
	}, duration)
}
const slideDown = (target, duration = animationDuration) => {
	const { parentElement } = target
	parentElement.classList.add('open')
	target.style.removeProperty('display')
	let { display } = window.getComputedStyle(target)
	if (display === 'none') display = 'block'
	target.style.display = display
	const height = target.offsetHeight
	target.style.overflow = 'hidden'
	target.style.height = 0
	target.style.paddingTop = 0
	target.style.paddingBottom = 0
	target.style.marginTop = 0
	target.style.marginBottom = 0
	target.offsetHeight
	target.style.boxSizing = 'border-box'
	target.style.transitionProperty = 'height, margin, padding'
	target.style.transitionDuration = `${duration}ms`
	target.style.height = `${height}px`
	target.style.removeProperty('padding-top')
	target.style.removeProperty('padding-bottom')
	target.style.removeProperty('margin-top')
	target.style.removeProperty('margin-bottom')
	window.setTimeout(() => {
		target.style.removeProperty('height')
		target.style.removeProperty('overflow')
		target.style.removeProperty('transition-duration')
		target.style.removeProperty('transition-property')
	}, duration)
}
const slideToggle = (target, duration = animationDuration) => {
	if (window.getComputedStyle(target).display === 'none') return slideDown(target, duration);
	return slideUp(target, duration)
}
const updatePoppersTimeout = () => {
	setTimeout(() => {
		PoppersInstance.updatePoppers()
	}, animationDuration)
}
