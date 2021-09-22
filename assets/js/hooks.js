let Hooks = {}

Hooks.ScrollToTop = {
	mounted() {
		this.el.addEventListener("click", e => {
			window.scrollTo(0, 0);
		})
	}
}

Hooks.BackgroundColorChange = {
	value() {
		return this.el.dataset.value;
	},
	mounted() {
		document.body.style.background = this.value();
	},
	updated() {
		document.body.style.background = this.value();
	}
}

Hooks.InfiniteScroll = {
	mounted() {
		const observer = new IntersectionObserver(entries => {
			const entry = entries[0];
			if (entry.isIntersecting) {
				this.pushEventTo(this.el, "load_more");
			}
		});
		observer.observe(this.el);
	}
}

export default Hooks;
