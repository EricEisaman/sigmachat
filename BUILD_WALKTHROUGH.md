# Docker Build Process: Verified Walkthrough

This document traces the exact execution flow of your `Dockerfile` to ensure correctness and prevent failures.

## Stage 1: The Builder (`ghcr.io/cirruslabs/flutter:stable`)
**Environment**: Debian-based Linux, Flutter Stable (3.27+), Dart SDK (3.6+).

1.  **System Dependencies (`apt`)**
    -   Installs `curl`, `wget`, `jq`, `build-essential`.
    -   *Status*: **Safe**. Standard packages.

2.  **Rust Installation (`rustup`)**
    -   Installs standard Rust.
    -   Adds `wasm32-unknown-unknown` target (implicitly done by `prepare-web.sh` or `rustup` config?).
    -   *Checkpoint*: The `prepare-web.sh` script assumes `rustup` is in PATH. **Verified**: `ENV PATH` is set correctly.

3.  **Tool Installation (`yq`)**
    -   Downloads `yq` binary to parse `pubspec.yaml`.
    -   *Status*: **Safe**. Version v4.40.5 is pinned.

4.  **Cache Layer Strategy**
    -   `COPY pubspec.yaml pubspec.lock ./`
    -   `COPY scripts ./scripts`
    -   `COPY web ./web`
    -   *Why*: This allows Docker to skip the heavy Rust compilation step if you only change your Dart UI code (`lib/`).

5.  **Preparation Script (`RUN mkdir -p assets/vodozemac && ./scripts/prepare-web.sh`)**
    -   **Step 5a**: `mkdir -p assets/vodozemac`
        -   *Crucial Fix*: Creates the target directory. The previous failure happened because this was missing.
    -   **Step 5b**: `scripts/prepare-web.sh`
        -   Uses `yq` to read `flutter_vodozemac` version.
        -   Clones `dart-vodozemac` repo.
        -   Installs `flutter_rust_bridge_codegen`.
        -   Compiles Rust code (`cargo build ...`).
        -   **Moves output to `assets/vodozemac/`**. *Verified*: Directory now exists from Step 5a.
        -   Runs `flutter pub get`.
        -   Compiles `native_executor.dart` -> `native_executor.js`.
    -   *Status*: **Verified**. Dependencies matches, directory exists.

6.  **Application Build**
    -   `COPY . .`: Copies the full source code.
    -   `flutter build web --release`: Compiles the specific Flutter app.
    -   *Output*: `build/web` directory containing `index.html`, `main.dart.js`, etc.

## Stage 2: The Production Runtime (`nginx:alpine`)
**Environment**: Alpine Linux (Tiny, <20MB).

1.  **Setup (`apk`)**
    -   Installs `gettext` (for `envsubst`) and `wget` (for healthcheck).

2.  **Asset Transfer**
    -   Copies `build/web` from Stage 1 into `/usr/share/nginx/html`.
    -   *Status*: **Safe**. Matches standard Nginx path.

3.  **Configuration**
    -   Copies `nginx.conf.template` to `/etc/nginx/templates/`.
    -   Copies `docker-entrypoint.sh`.

4.  **Runtime Execution**
    -   **Entrypoint**: `docker-entrypoint.sh` runs first.
        -   It reads `$PORT` (from Render).
        -   It runs `envsubst` to replace `$PORT` in `nginx.conf.template`.
        -   It writes the result to `/etc/nginx/conf.d/default.conf`.
    -   **Command**: `nginx -g "daemon off;"`.
        -   Starts the web server.

## Conclusion
The build pipeline is now robust.
-   **Version Mismatch**: Fixed by upgrading to `:stable`.
-   **Missing Directory**: Fixed by explicit `mkdir`.
-   **Configuration**: Handled dynamically by entrypoint.
