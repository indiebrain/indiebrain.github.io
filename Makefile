IMAGE ?= site-builder:local
# The image is amd64 (headless Chrome has no Linux arm64 build); pin the
# platform so it runs consistently, natively in CI and emulated locally.
DOCKER_RUN = docker run --rm --platform linux/amd64 -u $(shell id -u):$(shell id -g) -e HOME=/tmp \
	-v "$(PWD)":/site -w /site $(IMAGE)

.PHONY: build a11y serve clean deploy image docker-build docker-deploy shell

# --- Host toolchain (requires Emacs, Hugo extended, and LaTeX) ---

# Full production build into public/, then audit it for accessibility.
build: content static/resume/resume.pdf
	hugo --gc --minify
	$(MAKE) a11y

# Audit the built site against WCAG 2.2 Level AAA with pa11y. Runs as part
# of `build` (and therefore `deploy`); also runnable on its own once
# public/ exists. Needs the container's browser + pa11y, so invoke through
# `make docker-build` / `make docker-deploy` (or install the tools on the
# host).
a11y:
	./build/a11y.sh

# Export Org -> Markdown (ox-hugo).
content:
	emacs --batch -Q -l build/export.el

# Resume PDF -> static/resume/resume.pdf.
static/resume/resume.pdf:
	emacs --batch -Q -l build/resume.el

# Rebuild everything and serve locally with live reload.
serve:
	emacs --batch -Q -l build/export.el
	emacs --batch -Q -l build/resume.el
	hugo server

# Remove all generated output.
clean:
	rm -rf content public static/resume static/images

# Break-glass fallback: clean-build and publish to the gh-pages branch
# (normal deploys run automatically from master via GitHub Actions).
deploy:
	$(MAKE) clean
	$(MAKE) build
	./build/deploy.sh

# --- Containerized toolchain (only Docker required) ---
# Same image CI uses, so builds match everywhere.

# Build the toolchain image locally.
image:
	docker build --platform linux/amd64 -t $(IMAGE) .

# Build the site inside the container.
docker-build: image
	$(DOCKER_RUN) make build

# Break-glass fallback: build in the container, then publish to gh-pages.
docker-deploy: docker-build
	./build/deploy.sh

# Interactive shell in the toolchain container.
shell: image
	docker run --rm -it --platform linux/amd64 -u $(shell id -u):$(shell id -g) -e HOME=/tmp \
		-v "$(PWD)":/site -w /site $(IMAGE) bash
