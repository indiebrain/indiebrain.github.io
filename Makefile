IMAGE ?= site-builder:local
DOCKER_RUN = docker run --rm -u $(shell id -u):$(shell id -g) -e HOME=/tmp \
	-v "$(PWD)":/site -w /site $(IMAGE)

.PHONY: build serve clean deploy image docker-build docker-deploy shell

# --- Host toolchain (requires Emacs, Hugo extended, and LaTeX) ---

# Full production build into public/.
build: content static/resume/resume.pdf
	hugo --gc --minify

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

# Clean-build and publish to the master branch (served by GitHub Pages).
deploy:
	$(MAKE) clean
	$(MAKE) build
	./build/deploy.sh

# --- Containerized toolchain (only Docker required) ---
# Same image CI uses, so builds match everywhere.

# Build the toolchain image locally.
image:
	docker build -t $(IMAGE) .

# Build the site inside the container.
docker-build: image
	$(DOCKER_RUN) make build

# Build in the container, then publish to master from the host.
docker-deploy: docker-build
	./build/deploy.sh

# Interactive shell in the toolchain container.
shell: image
	docker run --rm -it -u $(shell id -u):$(shell id -g) -e HOME=/tmp \
		-v "$(PWD)":/site -w /site $(IMAGE) bash
