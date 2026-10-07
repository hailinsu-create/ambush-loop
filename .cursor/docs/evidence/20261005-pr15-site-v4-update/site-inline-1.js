
const GODOT_CONFIG = {"args":[],"canvasResizePolicy":2,"emscriptenPoolSize":8,"ensureCrossOriginIsolationHeaders":false,"executable":"index","experimentalVK":false,"fileSizes":{"index.pck":38096256,"index.wasm":39514754},"focusCanvas":true,"gdextensionLibs":[],"godotPoolSize":4};
const GODOT_THREADS_ENABLED = false;
const engine = new Engine(GODOT_CONFIG);
	const packTransport = {"bytes":38096256,"sha256":"0eabd893591bc97c6e7ad897e370759ba58b6e36419d47e80a0aefce638c6523","parts":[{"path":"index.pck.part00","bytes":25165824,"sha256":"ae9bcfa8230188f5789b16ad1324a3cfc133cec8445b3cd0f7cc2beda16448a4"},{"path":"index.pck.part01","bytes":12930432,"sha256":"bafd4cca2b1e25dbf55748a72e7849a1a464c00ebc2925a154577672dcb4be1a"}]};
	const wasmTransport = {"bytes":39514754,"sha256":"fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0"};
	const originalFetch = window.fetch.bind(window);
	const wasmURL = new URL('index.wasm', document.baseURI).href;
	window.fetch = async function (input, init) {
		const url = new URL(input instanceof Request ? input.url : input, document.baseURI).href;
		if (url !== wasmURL) return originalFetch(input, init);
		if (typeof DecompressionStream === 'undefined') throw new Error('This game needs a browser with gzip DecompressionStream support.');
		const response = await originalFetch('index.wasm.gz', init);
		if (!response.ok) throw new Error('Engine download failed (' + response.status + ')');
		const bytes = await new Response(response.body.pipeThrough(new DecompressionStream('gzip'))).arrayBuffer();
		const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)), b => b.toString(16).padStart(2, '0')).join('');
		if (bytes.byteLength !== wasmTransport.bytes || hash !== wasmTransport.sha256) throw new Error('Engine download integrity check failed. Please reload.');
		return new Response(bytes, {headers: {'Content-Type': 'application/wasm', 'Content-Length': String(bytes.byteLength)}});
	};
	const originalPreloadFile = engine.preloadFile.bind(engine);
	engine.preloadFile = async function (file, path) {
		if (file !== 'index.pck') return originalPreloadFile(file, path);
		const pack = new Uint8Array(packTransport.bytes);
		let offset = 0;
		for (const part of packTransport.parts) {
			const response = await fetch(part.path, {credentials: 'same-origin'});
			if (!response.ok) throw new Error('Game download failed: ' + part.path + ' (' + response.status + ')');
			const bytes = new Uint8Array(await response.arrayBuffer());
			if (bytes.length !== part.bytes) throw new Error('Incomplete game download: ' + part.path);
			pack.set(bytes, offset);
			offset += bytes.length;
		}
		const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', pack)), b => b.toString(16).padStart(2, '0')).join('');
		if (offset !== packTransport.bytes || hash !== packTransport.sha256) throw new Error('Game download integrity check failed. Please reload.');
		return originalPreloadFile(pack.buffer, path);
	};


(function () {
	const statusOverlay = document.getElementById('status');
	const statusProgress = document.getElementById('status-progress');
	const statusNotice = document.getElementById('status-notice');

	let initializing = true;
	let statusMode = '';

	function setStatusMode(mode) {
		if (statusMode === mode || !initializing) {
			return;
		}
		if (mode === 'hidden') {
			statusOverlay.remove();
			initializing = false;
			return;
		}
		statusOverlay.style.visibility = 'visible';
		statusProgress.style.display = mode === 'progress' ? 'block' : 'none';
		statusNotice.style.display = mode === 'notice' ? 'block' : 'none';
		statusMode = mode;
	}

	function setStatusNotice(text) {
		while (statusNotice.lastChild) {
			statusNotice.removeChild(statusNotice.lastChild);
		}
		const lines = text.split('\n');
		lines.forEach((line) => {
			statusNotice.appendChild(document.createTextNode(line));
			statusNotice.appendChild(document.createElement('br'));
		});
	}

	function displayFailureNotice(err) {
		console.error(err);
		if (err instanceof Error) {
			setStatusNotice(err.message);
		} else if (typeof err === 'string') {
			setStatusNotice(err);
		} else {
			setStatusNotice('An unknown error occurred.');
		}
		setStatusMode('notice');
		initializing = false;
	}

	const missing = Engine.getMissingFeatures({
		threads: GODOT_THREADS_ENABLED,
	});

	if (missing.length !== 0) {
		if (GODOT_CONFIG['serviceWorker'] && GODOT_CONFIG['ensureCrossOriginIsolationHeaders'] && 'serviceWorker' in navigator) {
			let serviceWorkerRegistrationPromise;
			try {
				serviceWorkerRegistrationPromise = navigator.serviceWorker.getRegistration();
			} catch (err) {
				serviceWorkerRegistrationPromise = Promise.reject(new Error('Service worker registration failed.'));
			}
			// There's a chance that installing the service worker would fix the issue
			Promise.race([
				serviceWorkerRegistrationPromise.then((registration) => {
					if (registration != null) {
						return Promise.reject(new Error('Service worker already exists.'));
					}
					return registration;
				}).then(() => engine.installServiceWorker()),
				// For some reason, `getRegistration()` can stall
				new Promise((resolve) => {
					setTimeout(() => resolve(), 2000);
				}),
			]).then(() => {
				// Reload if there was no error.
				window.location.reload();
			}).catch((err) => {
				console.error('Error while registering service worker:', err);
			});
		} else {
			// Display the message as usual
			const missingMsg = 'Error\nThe following features required to run Godot projects on the Web are missing:\n';
			displayFailureNotice(missingMsg + missing.join('\n'));
		}
	} else {
		setStatusMode('progress');
		engine.startGame({
			'onProgress': function (current, total) {
				if (current > 0 && total > 0) {
					statusProgress.value = current;
					statusProgress.max = total;
				} else {
					statusProgress.removeAttribute('value');
					statusProgress.removeAttribute('max');
				}
			},
		}).then(() => {
			setStatusMode('hidden');
		}, displayFailureNotice);
	}
}());
		