# Build the site locally. Requires Emacs, Hugo (extended), and a LaTeX
# toolchain (for the resume PDF).

.PHONY: build serve clean

# Full production build into public/.
build: content static/resume/resume.pdf
	hugo --gc --minify

# Export Org -> Markdown (also refreshed by `serve`).
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
	rm -rf content public static/ox-hugo static/resume
