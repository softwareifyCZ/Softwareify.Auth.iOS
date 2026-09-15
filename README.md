# Softwareify.Auth.iOS

Swift Package Manager library for OIDC / PKCE authentication (`SoftwareifyAuth`).

**Consume via:** Swift Package Manager (GitHub + semver tags)  
**Repo:** https://github.com/softwareifyCZ/Softwareify.Auth.iOS (public — no PAT required to resolve)

## Development & Release

### Development

1. Open a pull request targeting `master`.
2. GitHub Actions **CI** runs: `swift build` → `swift test`.
3. Fix failures, then merge. Pushes to `master` run the same checks (no release).

Locally:

```bash
swift build
swift test
```

### Release

Versioning is **manual**. The Git tag is what SPM resolves.

1. On `master`, set `VERSION` to the next semver (e.g. `0.1.0`).
2. Commit and merge to `master`.
3. Tag and push:

   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

4. **Release** workflow runs: build → test → checks tag == `VERSION` → creates a GitHub Release.

If tag `v0.1.0` does not match `VERSION` (`0.1.0`), the workflow **fails and does not create a release**.

### Semantic versioning

| Change | Bump |
|--------|------|
| Bug fix | **PATCH** |
| Backward-compatible feature | **MINOR** |
| Breaking change | **MAJOR** |

### Install (consumers)

In Xcode: **File → Add Package Dependencies…**  
URL: `https://github.com/softwareifyCZ/Softwareify.Auth.iOS`  
Version: Up to Next Major from `0.1.0` (or pin an exact tag).

Or in `Package.swift` / XcodeGen:

```swift
.package(url: "https://github.com/softwareifyCZ/Softwareify.Auth.iOS.git", from: "0.1.0")
```

```yaml
# project.yml (XcodeGen)
packages:
  SoftwareifyAuth:
    url: https://github.com/softwareifyCZ/Softwareify.Auth.iOS
    from: 0.1.0
```

Releasing uses the Actions `GITHUB_TOKEN` (no personal PAT).  
Org setting: **softwareifyCZ → Settings → Actions → General → Workflow permissions → Read and write permissions**.
